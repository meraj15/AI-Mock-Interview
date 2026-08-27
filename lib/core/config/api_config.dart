import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static Environment currentEnvironment = Environment.development;

  /// Optional manual base URL override (useful for physical device LAN testing or CI)
  static String? customBaseUrl;

  /// Candidate development endpoints (tested in order of priority).
  ///
  /// Order matters — the first reachable host wins and is persisted so
  /// subsequent cold-starts skip this discovery loop.
  ///
  /// • 192.168.0.113 — current LAN IP of the dev machine (update if your IP changes)
  /// • 10.0.2.2      — Android emulator alias for host localhost
  /// • localhost     — Windows / web / desktop runner
  static const List<String> developmentCandidates = [
    'http://192.168.0.113:3000',
    'http://10.0.2.2:3000',
    'http://localhost:3000',
  ];

  /// Currently active discovered base URL — set after first successful request.
  /// Persisted across sessions via [setResolvedBaseUrl] so host discovery only
  /// runs once rather than on every cold-start.
  static String? _resolvedBaseUrl;

  static void setResolvedBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  /// Restore the previously discovered host on app startup.
  /// Call this in main() after reading SharedPreferences.
  /// If the saved host is no longer in [developmentCandidates] (e.g. the
  /// machine IP changed) it is ignored and discovery runs again.
  static void restoreResolvedBaseUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      // Only restore if it's still a valid candidate — guards against stale IPs.
      final isStillValid = developmentCandidates.contains(url) ||
          currentEnvironment != Environment.development;
      if (isStillValid) {
        _resolvedBaseUrl = url;
      }
    }
  }

  static bool get isResolved => _resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty;

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
          return 'http://192.168.0.113:3000';
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
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
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
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
