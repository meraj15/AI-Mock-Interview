import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static Environment currentEnvironment = Environment.development;

  /// Optional manual base URL override (useful for physical device LAN testing or CI)
  static String? customBaseUrl;

  /// Candidate development endpoints (tested in order of priority)
  static const List<String> developmentCandidates = [
    'http://localhost:3000',
    'http://192.168.0.113:3000',
    'http://10.0.2.2:3000',
  ];

  /// Currently active discovered base URL
  static String? _resolvedBaseUrl;

  static void setResolvedBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  /// Returns the base URL according to the current platform & environment.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      return _resolvedBaseUrl!;
    }

    switch (currentEnvironment) {
      case Environment.production:
        return 'https://api.interviewcoach.ai';
      case Environment.staging:
        return 'https://staging-api.interviewcoach.ai';
      case Environment.development:
        if (kIsWeb) {
          return 'http://localhost:3000';
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Default to localhost (works with adb reverse) or LAN IP
          return 'http://localhost:3000';
        }
        return 'http://localhost:3000';
    }
  }

  // ── Authentication Endpoints ───────────────────────────────────────────────
  static const String healthEndpoint = '/health';
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String refreshEndpoint = '/api/v1/auth/refresh';
  static const String meEndpoint = '/api/v1/auth/me';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String logoutAllEndpoint = '/api/v1/auth/logout-all';
  static const String profileEndpoint = '/api/v1/profile';

  // ── Resume Endpoints ───────────────────────────────────────────────────────
  static const String resumeParseEndpoint = '/api/resume/parse';

  // ── Network Timeouts ───────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
