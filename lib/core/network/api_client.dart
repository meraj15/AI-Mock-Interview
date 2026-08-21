import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../error/exceptions.dart';
import '../storage/token_storage.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? message;
  final bool success;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.message,
    this.success = true,
  });
}

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiClient({
    http.Client? client,
    required TokenStorage tokenStorage,
    this.onSessionExpired,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage;

  // ── Public HTTP Methods ───────────────────────────────────────────────────

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _sendRequestWithFallback(
      method: 'GET',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
    bool autoRefresh = true,
  }) async {
    return _sendRequestWithFallback(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
      autoRefresh: autoRefresh,
    );
  }

  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequestWithFallback(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequestWithFallback(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendRequestWithFallback(
      method: 'DELETE',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  // ── Candidate Host Fallback for Development (Physical Device / Emulator / Desktop) ─

  Future<ApiResponse> _sendRequestWithFallback({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool autoRefresh = true,
  }) async {
    if (ApiConfig.currentEnvironment != Environment.development) {
      return _sendSingleRequest(
        baseUrl: ApiConfig.baseUrl,
        method: method,
        path: path,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
        requiresAuth: requiresAuth,
        autoRefresh: autoRefresh,
      );
    }

    // Try current base URL first
    final candidateHosts = [
      ApiConfig.baseUrl,
      ...ApiConfig.developmentCandidates.where((u) => u != ApiConfig.baseUrl),
    ];

    Exception? lastException;

    for (final host in candidateHosts) {
      try {
        final res = await _sendSingleRequest(
          baseUrl: host,
          method: method,
          path: path,
          body: body,
          headers: headers,
          queryParameters: queryParameters,
          requiresAuth: requiresAuth,
          autoRefresh: autoRefresh,
          customTimeout: const Duration(seconds: 4),
        );
        // Remember successful host
        ApiConfig.setResolvedBaseUrl(host);
        return res;
      } on NetworkException catch (e) {
        lastException = e;
        continue;
      } on SocketException catch (e) {
        lastException = NetworkException(e.message);
        continue;
      } on TimeoutException catch (e) {
        lastException = NetworkException(e.message ?? 'Timed out');
        continue;
      } catch (e) {
        if (e is Exception && (e is AuthException || e is ValidationException || e is ServerException)) {
          // If the server responded with an application-level error, the host is reachable!
          ApiConfig.setResolvedBaseUrl(host);
          rethrow;
        }
        lastException = NetworkException(e.toString());
      }
    }

    throw lastException ?? NetworkException('Unable to reach backend server. Please make sure the server is running.');
  }

  // ── Core Single Request Execution ─────────────────────────────────────────

  Future<ApiResponse> _sendSingleRequest({
    required String baseUrl,
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool autoRefresh = true,
    Duration? customTimeout,
  }) async {
    final uri = _buildUri(baseUrl, path, queryParameters);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    http.Response response;
    try {
      final request = http.Request(method, uri);
      request.headers.addAll(requestHeaders);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final timeout = customTimeout ?? ApiConfig.connectTimeout;
      final streamedResponse = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException('Request timed out. Please check your connection.');
    } catch (e) {
      if (e is Exception && (e is NetworkException || e is ServerException || e is AuthException || e is ValidationException)) {
        rethrow;
      }
      throw NetworkException('Network error: ${e.toString()}');
    }

    // ── Handle 401 Unauthorized with Automatic Token Refresh ─────────────────
    if (response.statusCode == 401 && requiresAuth && autoRefresh) {
      final refreshed = await _attemptTokenRefresh(baseUrl);
      if (refreshed) {
        return _sendSingleRequest(
          baseUrl: baseUrl,
          method: method,
          path: path,
          body: body,
          headers: headers,
          queryParameters: queryParameters,
          requiresAuth: true,
          autoRefresh: false,
        );
      } else {
        await _tokenStorage.clearTokens();
        onSessionExpired?.call();
        throw AuthException('Session expired. Please sign in again.', 'SESSION_EXPIRED');
      }
    }

    return _processResponse(response);
  }

  // ── Token Refresh Coordination (Thread-Safe Mutex) ────────────────────────

  Future<bool> _attemptTokenRefresh(String baseUrl) async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter?.complete(false);
        return false;
      }

      final refreshUri = _buildUri(baseUrl, ApiConfig.refreshEndpoint, null);
      final response = await _client
          .post(
            refreshUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenData = data['data'] ?? data;
        final newAccessToken = tokenData['accessToken'] as String?;
        final newRefreshToken = tokenData['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          _refreshCompleter?.complete(true);
          return true;
        }
      }

      _refreshCompleter?.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── URI & Headers Helpers ─────────────────────────────────────────────────

  Uri _buildUri(String baseUrl, String path, Map<String, dynamic>? queryParameters) {
    final fullUrl = path.startsWith('http') ? path : '$baseUrl$path';
    final parsed = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsed.replace(queryParameters: {
        ...parsed.queryParameters,
        ...queryParameters.map((k, v) => MapEntry(k, v.toString())),
      });
    }
    return parsed;
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  // ── Response Parsing & Error Translation ──────────────────────────────────

  ApiResponse _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      jsonBody = null;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccess) {
      final message = jsonBody is Map ? jsonBody['message'] as String? : null;
      final data = jsonBody is Map && jsonBody.containsKey('data') ? jsonBody['data'] : jsonBody;
      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        message: message,
        success: true,
      );
    }

    // Extract message & code from backend response
    String errorMessage = 'Request failed with status ${response.statusCode}';
    String? errorCode;
    final List<String> validationDetails = [];

    if (jsonBody is Map) {
      errorMessage = jsonBody['message'] as String? ?? errorMessage;
      if (jsonBody['error'] is Map) {
        errorCode = jsonBody['error']['code'] as String?;
        final nestedMsg = jsonBody['error']['message'] as String?;
        if (nestedMsg != null && nestedMsg.isNotEmpty) {
          errorMessage = nestedMsg;
        }
        // Parse field-level validation details: [{ "field": "password", "message": "..." }]
        final details = jsonBody['error']['details'];
        if (details is List) {
          for (final d in details) {
            if (d is Map && d['message'] is String) {
              validationDetails.add(d['message'] as String);
            }
          }
        }
      }
    }

    // Friendly translations
    if (errorCode == 'INVALID_CREDENTIALS') {
      errorMessage = 'Invalid email or password.';
      throw AuthException(errorMessage, errorCode);
    }

    if (errorCode == 'EMAIL_ALREADY_EXISTS') {
      errorMessage = 'An account with this email already exists.';
      throw AuthException(errorMessage, errorCode);
    }

    if (errorCode == 'ACCOUNT_DISABLED') {
      errorMessage = 'Your account has been disabled. Please contact support.';
      throw AuthException(errorMessage, errorCode);
    }

    if (errorCode == 'RATE_LIMIT_EXCEEDED') {
      errorMessage = 'Too many attempts. Please wait 15 minutes before trying again.';
      throw AuthException(errorMessage, errorCode);
    }

    if (response.statusCode == 422 || errorCode == 'VALIDATION_ERROR') {
      // Use detail messages when available, otherwise fall back to the top-level message
      final displayMessage = validationDetails.isNotEmpty
          ? validationDetails.join('\n')
          : errorMessage;
      throw ValidationException(displayMessage, validationDetails);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(errorMessage, errorCode);
    }

    if (response.statusCode >= 500) {
      throw ServerException('Something went wrong. Please try again later.', errorCode);
    }

    throw ServerException(errorMessage, errorCode);
  }
}
