import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../error/exceptions.dart';
import '../storage/token_storage.dart';

/// SharedPreferences key used to persist the resolved backend host across
/// app restarts so host-discovery only runs once.
const _kResolvedHostKey = 'ic_resolved_backend_host';

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

  // ── Candidate Host Fallback ───────────────────────────────────────────────
  //
  // In development mode the client tries all 3 candidate hosts sequentially
  // until one responds. After the first success the working host is saved to
  // SharedPreferences so subsequent cold-starts skip the discovery loop and
  // go directly to the known-good host.

  Future<ApiResponse> _sendRequestWithFallback({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool autoRefresh = true,
  }) async {
    if (ApiConfig.currentEnvironment != Environment.development || ApiConfig.isResolved) {
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

    // Build candidate list — resolved host (if known) goes first so we skip
    // trying unreachable addresses on subsequent requests.
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
          customTimeout: ApiConfig.connectTimeout,
        );
        // Host is reachable — remember it in memory and persist it so the
        // next cold-start skips the discovery loop entirely.
        ApiConfig.setResolvedBaseUrl(host);
        _persistResolvedHost(host);
        return res;
      } on NetworkException catch (e) {
        lastException = e;
        continue;
      } on SocketException catch (e) {
        lastException = NetworkException(e.message);
        continue;
      } on TimeoutException catch (e) {
        lastException = NetworkException(e.message ?? 'Request timed out');
        continue;
      } catch (e) {
        if (e is Exception &&
            (e is AuthException ||
                e is ValidationException ||
                e is ServerException)) {
          // Server responded with an application-level error → host is reachable.
          ApiConfig.setResolvedBaseUrl(host);
          _persistResolvedHost(host);
          rethrow;
        }
        lastException = NetworkException(e.toString());
      }
    }

    throw lastException ??
        NetworkException(
            'Unable to reach backend server. Please make sure the server is running.');
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
      if (e is Exception &&
          (e is NetworkException ||
              e is ServerException ||
              e is AuthException ||
              e is ValidationException)) {
        rethrow;
      }
      throw NetworkException('Network error: ${e.toString()}');
    }

    // ── Handle 401 with automatic token refresh ───────────────────────────
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
        throw AuthException(
            'Session expired. Please sign in again.', 'SESSION_EXPIRED');
      }
    }

    return _processResponse(response);
  }

  // ── Token Refresh (thread-safe mutex) ────────────────────────────────────

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

  // ── Persist resolved host ─────────────────────────────────────────────────

  /// Fire-and-forget: saves the working host to SharedPreferences so the next
  /// cold-start restores it and skips the 3-candidate discovery loop.
  void _persistResolvedHost(String host) {
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_kResolvedHostKey, host),
    );
  }

  // ── URI & Headers Helpers ─────────────────────────────────────────────────

  Uri _buildUri(
    String baseUrl,
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    final fullUrl = path.startsWith('http') ? path : '$baseUrl$path';
    final parsedUri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsedUri.replace(queryParameters: {
        ...parsedUri.queryParameters,
        ...queryParameters.map((k, v) => MapEntry(k, v.toString())),
      });
    }
    return parsedUri;
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
      final message =
          jsonBody is Map ? jsonBody['message'] as String? : null;
      final data = jsonBody is Map && jsonBody.containsKey('data')
          ? jsonBody['data']
          : jsonBody;
      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        message: message,
        success: true,
      );
    }

    String errorMessage =
        'Request failed with status ${response.statusCode}';
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

    if (errorCode == 'INVALID_CREDENTIALS') {
      throw AuthException('Invalid email or password.', errorCode);
    }

    if (errorCode == 'EMAIL_ALREADY_EXISTS') {
      throw AuthException(
          'An account with this email already exists.', errorCode);
    }

    if (errorCode == 'ACCOUNT_DISABLED') {
      throw AuthException(
          'Your account has been disabled. Please contact support.',
          errorCode);
    }

    if (errorCode == 'RATE_LIMIT_EXCEEDED') {
      throw AuthException(
          'Too many attempts. Please wait 15 minutes before trying again.',
          errorCode);
    }

    if (response.statusCode == 422 || errorCode == 'VALIDATION_ERROR') {
      final displayMessage = validationDetails.isNotEmpty
          ? validationDetails.join('\n')
          : errorMessage;
      throw ValidationException(displayMessage, validationDetails);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(errorMessage, errorCode);
    }

    if (response.statusCode >= 500) {
      throw ServerException(
          errorMessage.isNotEmpty ? errorMessage : 'Something went wrong. Please try again later.', errorCode);
    }

    throw ServerException(errorMessage, errorCode);
  }
}
