import '../utils/semver_helper.dart';

enum UpdateDecision {
  none,
  optional,
  force,
}

class AppVersionInfo {
  final String platform;
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> whatsNew;
  final String storeUrl;
  final DateTime? releaseDate;

  const AppVersionInfo({
    required this.platform,
    required this.latestVersion,
    required this.minimumVersion,
    this.forceUpdate = false,
    required this.title,
    required this.message,
    this.whatsNew = const [],
    required this.storeUrl,
    this.releaseDate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    List<String> parseWhatsNew(dynamic val) {
      if (val is List) {
        return val
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return val
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
      return const [];
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AppVersionInfo(
      platform: json['platform']?.toString().toUpperCase() ?? 'ANDROID',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      minimumVersion: json['minimumVersion']?.toString() ?? '1.0.0',
      forceUpdate: json['forceUpdate'] == true,
      title: json['title']?.toString() ?? 'App Update Available',
      message: json['message']?.toString() ??
          'A new version of AI Mock Interview is available.',
      whatsNew: parseWhatsNew(json['whatsNew']),
      storeUrl: json['storeUrl']?.toString() ?? '',
      releaseDate: parseDate(json['releaseDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'latestVersion': latestVersion,
      'minimumVersion': minimumVersion,
      'forceUpdate': forceUpdate,
      'title': title,
      'message': message,
      'whatsNew': whatsNew,
      'storeUrl': storeUrl,
      'releaseDate': releaseDate?.toIso8601String(),
    };
  }

  /// Evaluates update decision according to production rules:
  ///
  /// if installedVersion < minimumVersion:
  ///     force update
  /// else if forceUpdate && installedVersion < latestVersion:
  ///     force update
  /// else if installedVersion < latestVersion:
  ///     optional update
  /// else:
  ///     no update
  UpdateDecision evaluateDecision(String installedVersion) {
    if (!SemverHelper.isValid(installedVersion) ||
        !SemverHelper.isValid(latestVersion) ||
        !SemverHelper.isValid(minimumVersion)) {
      return UpdateDecision.none;
    }

    try {
      // 1. Force update if installed is lower than minimum supported version
      if (SemverHelper.compare(installedVersion, minimumVersion) < 0) {
        return UpdateDecision.force;
      }

      // 2. Force update if CMS marked forceUpdate = true and installed is lower than latest
      if (forceUpdate &&
          SemverHelper.compare(installedVersion, latestVersion) < 0) {
        return UpdateDecision.force;
      }

      // 3. Optional update if installed is lower than latest version
      if (SemverHelper.compare(installedVersion, latestVersion) < 0) {
        return UpdateDecision.optional;
      }

      // 4. Installed version is equal or newer -> No update required
      return UpdateDecision.none;
    } catch (_) {
      return UpdateDecision.none;
    }
  }
}
