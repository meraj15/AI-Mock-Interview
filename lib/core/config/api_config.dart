import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static Environment currentEnvironment = Environment.development;

  /// Optional manual base URL override (useful for physical device LAN testing or CI)
  static String? customBaseUrl;

  /// Returns the base URL according to the current platform & environment.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
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
        // In Android emulator, 10.0.2.2 points to host machine's localhost
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:3000';
        }
        // iOS Simulator, Windows desktop, macOS
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

  // ── Network Timeouts ───────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
