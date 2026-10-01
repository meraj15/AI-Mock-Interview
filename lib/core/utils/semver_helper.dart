/// Semantic Versioning (SemVer) Utility for Flutter
///
/// Implements standard numerical SemVer comparison (e.g. 1.4.10 > 1.4.9)
/// to avoid string lexical comparison pitfalls.
class SemverHelper {
  static final RegExp _semverRegex = RegExp(
    r'^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$',
  );

  /// Validates whether a version string matches basic semantic versioning.
  static bool isValid(String? version) {
    if (version == null || version.trim().isEmpty) return false;
    return _semverRegex.hasMatch(version.trim());
  }

  /// Parses version into numeric [major, minor, patch] components.
  static List<int>? parseComponents(String version) {
    final match = _semverRegex.firstMatch(version.trim());
    if (match == null) return null;

    final major = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minor = int.tryParse(match.group(2) ?? '0') ?? 0;
    final patch = int.tryParse(match.group(3) ?? '0') ?? 0;

    return [major, minor, patch];
  }

  /// Compares two semantic version strings numerically.
  ///
  /// Returns:
  /// - `-1` if [v1] < [v2]
  /// - `0` if [v1] == [v2]
  /// - `1` if [v1] > [v2]
  ///
  /// Throws [FormatException] if either version string cannot be parsed.
  static int compare(String v1, String v2) {
    final c1 = parseComponents(v1);
    final c2 = parseComponents(v2);

    if (c1 == null) {
      throw FormatException('Invalid semantic version: "$v1"');
    }
    if (c2 == null) {
      throw FormatException('Invalid semantic version: "$v2"');
    }

    // Compare Major
    if (c1[0] != c2[0]) {
      return c1[0] > c2[0] ? 1 : -1;
    }

    // Compare Minor
    if (c1[1] != c2[1]) {
      return c1[1] > c2[1] ? 1 : -1;
    }

    // Compare Patch
    if (c1[2] != c2[2]) {
      return c1[2] > c2[2] ? 1 : -1;
    }

    // Pre-release check:
    final m1 = _semverRegex.firstMatch(v1.trim());
    final m2 = _semverRegex.firstMatch(v2.trim());
    final pre1 = m1?.group(4);
    final pre2 = m2?.group(4);

    if (pre1 == null && pre2 != null) return 1; // 1.0.0 > 1.0.0-beta
    if (pre1 != null && pre2 == null) return -1;
    if (pre1 != null && pre2 != null) {
      return pre1.compareTo(pre2);
    }

    return 0;
  }

  /// Returns true if [installedVersion] is strictly lower than [targetVersion].
  static bool isLower(String installedVersion, String targetVersion) {
    return compare(installedVersion, targetVersion) < 0;
  }

  /// Returns true if [installedVersion] is greater than or equal to [targetVersion].
  static bool isGreaterOrEqual(String installedVersion, String targetVersion) {
    return compare(installedVersion, targetVersion) >= 0;
  }
}
