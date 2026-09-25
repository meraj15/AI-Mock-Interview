import 'package:flutter/foundation.dart';

enum Environment { uat, production }

class ApiConfig {
  /// ══════════════════════════════════════════════════════════════════════════
  /// ENVIRONMENT TOGGLE (PRODUCTION vs LOCAL / UAT)
  /// ══════════════════════════════════════════════════════════════════════════
  /// Set this boolean to switch base URLs:
  ///   • true  => Production URL ([productionBaseUrl])
  ///   • false => Local / UAT URL ([uatBaseUrl])
  ///
  /// Toggle directly here:
  ///   `static bool isProduction = true;`  // Production
  ///   `static bool isProduction = false;` // Local / UAT
  ///
  /// Or override via CLI:
  ///   flutter run --dart-define=IS_PRODUCTION=true
  static bool _isProduction =
      const bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);

  static bool get isProduction => _isProduction;

  static set isProduction(bool value) {
    _isProduction = value;
    _environment = value ? Environment.production : Environment.uat;
  }

  /// Production Base URL hosted on Railway
  static const String productionBaseUrl =
      'https://ai-mock-interview-production-09fa.up.railway.app';

  /// Local / UAT Base URL
  /// Connected to your local development machine IP (192.168.0.117:3000)
  /// so physical mobile devices on the Wi-Fi network and emulators can reach the backend.
  static String uatBaseUrl = const String.fromEnvironment('UAT_BASE_URL',
          defaultValue: '')
      .isNotEmpty
      ? const String.fromEnvironment('UAT_BASE_URL')
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://192.168.0.117:3000'
          : 'http://192.168.0.117:3000');

  /// Convenient alias for uatBaseUrl
  static String get localBaseUrl => uatBaseUrl;
  static set localBaseUrl(String url) => uatBaseUrl = url;

  /// Optional build-time environment override, e.g.:
  /// `flutter run --dart-define=ENVIRONMENT=production`
  /// `flutter build apk --dart-define=ENVIRONMENT=production`
  static const String _envDefine =
      String.fromEnvironment('ENVIRONMENT', defaultValue: '');

  /// Optional build-time custom base URL override, e.g.:
  /// `flutter run --dart-define=API_BASE_URL=https://...`
  static const String _baseUrlDefine =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static Environment _detectInitialEnvironment() {
    if (bool.hasEnvironment('IS_PRODUCTION')) {
      return _isProduction ? Environment.production : Environment.uat;
    }
    if (_envDefine.isNotEmpty) {
      final env = _envDefine.toLowerCase();
      if (env == 'production' || env == 'prod') {
        return Environment.production;
      }
      return Environment.uat;
    }
    return _isProduction ? Environment.production : Environment.uat;
  }

  static Environment _environment = _detectInitialEnvironment();

  static Environment get currentEnvironment {
    return _environment;
  }

  static set currentEnvironment(Environment env) {
    _environment = env;
    _isProduction = (env == Environment.production);
  }

  /// Optional manual base URL override (useful for physical device LAN testing, CI, or --dart-define)
  static String? customBaseUrl =
      _baseUrlDefine.isNotEmpty ? _baseUrlDefine : null;

  /// Returns the base URL according to the boolean toggle:
  ///   - true  => productionBaseUrl
  ///   - false => uatBaseUrl
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    if (isProduction || currentEnvironment == Environment.production) {
      return productionBaseUrl;
    }

    return uatBaseUrl;
  }

  // ── Authentication Endpoints ───────────────────────────────────────────────
  static const String healthEndpoint = '/health';
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String refreshEndpoint = '/api/v1/auth/refresh';
  static const String meEndpoint = '/api/v1/auth/me';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String logoutAllEndpoint = '/api/v1/auth/logout-all';
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
  static const String verifyResetOtpEndpoint = '/api/v1/auth/verify-reset-otp';
  static const String resetPasswordEndpoint = '/api/v1/auth/reset-password';
  static const String profileEndpoint = '/api/v1/profile';
  static const String profileMergeResumeEndpoint = '/api/v1/profile/merge-resume';

  // ── Resume Endpoints ───────────────────────────────────────────────────────
  static const String resumeParseEndpoint = '/api/resume/parse';

  // ── AI Endpoints ───────────────────────────────────────────────────────────
  static const String aiQuestionsEndpoint = '/api/v1/ai/questions';
  static const String aiEvaluateAnswerEndpoint = '/api/v1/ai/evaluate-answer';
  static const String aiEvaluateSessionEndpoint = '/api/v1/ai/evaluate-session';

  // ── Interview Endpoints ────────────────────────────────────────────────────
  static const String interviewsEndpoint      = '/api/v1/interviews';
  static const String interviewStatsEndpoint  = '/api/v1/interviews/stats';
  static const String interviewStartEndpoint  = '/api/v1/interviews/start';
  static String interviewAnswerEndpoint(String sessionId) => '/api/v1/interviews/$sessionId/answer';
  static String interviewResultEndpoint(String sessionId) => '/api/v1/interviews/$sessionId/result';

  // ── Network Timeouts ───────────────────────────────────────────────────────
  /// Standard timeout for non-AI endpoints (auth, profile, etc.).
  static const Duration connectTimeout = Duration(seconds: 20);

  /// Extended timeout for Gemini-backed AI endpoints.
  /// Gemini can take 8-30 s depending on model load and prompt size.
  static const Duration aiTimeout = Duration(seconds: 60);
}
