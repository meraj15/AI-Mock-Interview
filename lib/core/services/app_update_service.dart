import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/app_version_info.dart';
import '../network/api_client.dart';
import '../widgets/app_update_dialog.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  static AppUpdateService get instance => _instance;

  ApiClient? _apiClient;
  SharedPreferences? _preferences;

  /// Cache cooldown duration between non-forced background checks
  static const Duration checkCooldown = Duration(minutes: 15);

  /// Key for storing last check timestamp
  static const String _prefLastCheckTimestamp = 'last_app_update_check_ms';

  /// Manual override version for automated tests or local debugging
  String? _testInstalledVersion;

  AppUpdateService._internal();

  factory AppUpdateService({
    ApiClient? apiClient,
    SharedPreferences? preferences,
    String? testInstalledVersion,
  }) {
    if (apiClient != null) _instance._apiClient = apiClient;
    if (preferences != null) _instance._preferences = preferences;
    if (testInstalledVersion != null) {
      _instance._testInstalledVersion = testInstalledVersion;
    }
    return _instance;
  }

  void initialize({
    required ApiClient apiClient,
    required SharedPreferences preferences,
  }) {
    _apiClient = apiClient;
    _preferences = preferences;
  }

  @visibleForTesting
  void setTestInstalledVersion(String? version) {
    _testInstalledVersion = version;
  }

  /// Detect mobile platform query string
  String get targetPlatformString {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }
    return 'android';
  }

  /// Fetches the installed app version from the device package info.
  Future<String> getInstalledVersion() async {
    if (_testInstalledVersion != null) {
      return _testInstalledVersion!;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      return version.isNotEmpty ? version : '1.0.0';
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to read PackageInfo: $e');
      return '1.0.0';
    }
  }

  /// Checks if enough time has elapsed since the last update check.
  bool _shouldThrottleCheck() {
    if (_preferences == null) return false;
    final lastMs = _preferences!.getInt(_prefLastCheckTimestamp) ?? 0;
    if (lastMs <= 0) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
    return elapsed < checkCooldown.inMilliseconds;
  }

  /// Records the current timestamp as the last check time.
  Future<void> _recordCheckTimestamp() async {
    if (_preferences != null) {
      await _preferences!.setInt(
        _prefLastCheckTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Queries the backend CMS for the published version configuration.
  ///
  /// Returns [AppVersionInfo] if a published update is available, or null.
  Future<AppVersionInfo?> fetchPublishedVersion({
    ApiClient? clientOverride,
  }) async {
    final client = clientOverride ?? _apiClient;
    if (client == null) {
      debugPrint('[AppUpdateService] ApiClient not initialized');
      return null;
    }

    try {
      final response = await client.get(
        ApiConfig.appVersionEndpoint,
        queryParameters: {'platform': targetPlatformString},
        requiresAuth: false,
        timeout: const Duration(seconds: 10),
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return AppVersionInfo.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      // Safe resilience: server unavailable / offline / timeout must not crash the app
      debugPrint('[AppUpdateService] Failed to fetch published version: $e');
      return null;
    }
  }

  /// Main method: checks for updates and displays the dialog if needed.
  ///
  /// [forceCheck]: bypasses throttling (useful on cold-start or manual trigger).
  Future<UpdateDecision> checkForUpdate({
    required BuildContext context,
    bool forceCheck = false,
  }) async {
    if (!forceCheck && _shouldThrottleCheck()) {
      return UpdateDecision.none;
    }

    final publishedConfig = await fetchPublishedVersion();
    await _recordCheckTimestamp();

    if (publishedConfig == null) {
      return UpdateDecision.none;
    }

    final installedVersion = await getInstalledVersion();
    final decision = publishedConfig.evaluateDecision(installedVersion);

    if (decision != UpdateDecision.none && context.mounted) {
      await AppUpdateDialog.show(
        context: context,
        updateInfo: publishedConfig,
        decision: decision,
      );
    }

    return decision;
  }
}
