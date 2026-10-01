import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interview_coach/core/models/app_version_info.dart';
import 'package:interview_coach/core/network/api_client.dart';
import 'package:interview_coach/core/services/app_update_service.dart';
import 'package:interview_coach/core/storage/token_storage.dart';
import 'package:interview_coach/core/theme/app_theme.dart';
import 'package:interview_coach/core/utils/semver_helper.dart';
import 'package:interview_coach/core/widgets/app_update_dialog.dart';

class MockTokenStorage implements TokenStorage {
  @override
  Future<void> clearTokens() async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<bool> hasTokens() async => false;
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
}

class FakeFailingApiClient extends ApiClient {
  FakeFailingApiClient() : super(tokenStorage: MockTokenStorage());

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    throw Exception('SocketException: Failed host lookup: backend.mockinterview.com');
  }
}

class FakeSuccessApiClient extends ApiClient {
  final Map<String, dynamic>? responseData;
  final bool success;

  FakeSuccessApiClient({this.responseData, this.success = true})
      : super(tokenStorage: MockTokenStorage());

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    return ApiResponse(
      statusCode: 200,
      success: success,
      data: responseData,
    );
  }
}

void main() {
  group('App Update Management — Semver & Version Comparison Tests', () {
    test('Semver comparison handles numerical order (1.4.10 > 1.4.9)', () {
      expect(SemverHelper.compare('1.4.10', '1.4.9'), equals(1));
      expect(SemverHelper.compare('1.4.9', '1.4.10'), equals(-1));
      expect(SemverHelper.compare('1.5.0', '1.4.10'), equals(1));
      expect(SemverHelper.compare('2.0.0', '1.5.0'), equals(1));
      expect(SemverHelper.compare('1.5.0', '1.5.0'), equals(0));
    });

    test('installed == latest -> no update', () {
      const config = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false,
        title: 'New Update',
        message: 'A new version is available',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      final decision = config.evaluateDecision('1.5.0');
      expect(decision, equals(UpdateDecision.none));
    });

    test('installed < latest and installed >= minimum -> optional update', () {
      const config = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false,
        title: 'New Update',
        message: 'A new version is available',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      // 1.4.9 is < 1.5.0 and >= 1.4.0
      final decision = config.evaluateDecision('1.4.9');
      expect(decision, equals(UpdateDecision.optional));
    });

    test('installed < minimum -> force update', () {
      const config = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false, // Even if forceUpdate is false, minVersion enforces it
        title: 'Update Required',
        message: 'Version is deprecated',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      // 1.3.9 is < 1.4.0 minimum
      final decision = config.evaluateDecision('1.3.9');
      expect(decision, equals(UpdateDecision.force));
    });

    test('installed > latest -> no update (beta/dev builds)', () {
      const config = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false,
        title: 'New Update',
        message: 'A new version is available',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      final decision = config.evaluateDecision('2.0.0');
      expect(decision, equals(UpdateDecision.none));
    });

    test('forceUpdate flag set to true triggers force update for installed < latest', () {
      const config = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: true, // Marked as required in CMS
        title: 'Critical Update',
        message: 'Security update required',
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      final decision = config.evaluateDecision('1.4.5');
      expect(decision, equals(UpdateDecision.force));
    });
  });

  group('Platform Store URLs & Safe JSON Parsing', () {
    test('Android configuration provides Google Play Store link', () {
      final json = {
        'platform': 'ANDROID',
        'latestVersion': '1.5.0',
        'minimumVersion': '1.4.0',
        'forceUpdate': false,
        'title': 'Android Update',
        'message': 'Performance patch for Android',
        'whatsNew': ['Faster AI interviews', 'Voice fixes'],
        'storeUrl': 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      };

      final info = AppVersionInfo.fromJson(json);
      expect(info.platform, equals('ANDROID'));
      expect(info.storeUrl, contains('play.google.com'));
      expect(info.whatsNew.length, equals(2));
    });

    test('iOS configuration provides Apple App Store link', () {
      final json = {
        'platform': 'IOS',
        'latestVersion': '1.5.1',
        'minimumVersion': '1.4.0',
        'forceUpdate': true,
        'title': 'iOS Update',
        'message': 'Security patch for iOS',
        'whatsNew': 'Better voice experience\nBug fixes',
        'storeUrl': 'https://apps.apple.com/app/ai-mock-interview/id123456789',
      };

      final info = AppVersionInfo.fromJson(json);
      expect(info.platform, equals('IOS'));
      expect(info.storeUrl, contains('apps.apple.com'));
      expect(info.forceUpdate, isTrue);
      expect(info.whatsNew.length, equals(2));
    });

    test('invalid response / malformed payload handled safely without crash', () {
      final json = <String, dynamic>{
        'platform': null,
        'latestVersion': null,
        'whatsNew': 12345, // invalid type
        'storeUrl': null,
      };

      final info = AppVersionInfo.fromJson(json);
      expect(info.latestVersion, equals('1.0.0'));
      expect(info.whatsNew, isEmpty);
      expect(info.storeUrl, isEmpty);

      // Should not throw on decision
      final decision = info.evaluateDecision('invalid-version');
      expect(decision, equals(UpdateDecision.none));
    });
  });

  group('AppUpdateService Resilience & API Failure Handling', () {
    test('API failure does not crash app and returns null gracefully', () async {
      final failingClient = FakeFailingApiClient();
      final service = AppUpdateService(
        apiClient: failingClient,
        testInstalledVersion: '1.0.0',
      );

      final result = await service.fetchPublishedVersion();
      expect(result, isNull);
    });

    test('Successful response returns parsed AppVersionInfo', () async {
      final successClient = FakeSuccessApiClient(
        responseData: {
          'platform': 'ANDROID',
          'latestVersion': '2.0.0',
          'minimumVersion': '1.8.0',
          'forceUpdate': false,
          'title': 'Version 2.0 Released',
          'message': 'Major release available',
          'whatsNew': ['New resume scanner', 'Deep evaluation'],
          'storeUrl': 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
        },
      );

      final service = AppUpdateService(
        apiClient: successClient,
        testInstalledVersion: '1.5.0',
      );

      final result = await service.fetchPublishedVersion();
      expect(result, isNotNull);
      expect(result?.latestVersion, equals('2.0.0'));
      expect(result?.whatsNew.length, equals(2));
    });
  });

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('Optional update displays "Later" button and can be dismissed', (tester) async {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false,
        title: 'New Update Available',
        message: 'A new version with performance improvements is available.',
        whatsNew: ['Faster AI interviews', 'Bug fixes'],
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppUpdateDialog.show(
                    context: context,
                    updateInfo: info,
                    decision: UpdateDecision.optional,
                  );
                },
                child: const Text('Check Update'),
              ),
            ),
          ),
        ),
      );

      // Trigger dialog
      await tester.tap(find.text('Check Update'));
      await tester.pumpAndSettle();

      // Verify content is displayed
      expect(find.text('New Update Available'), findsOneWidget);
      expect(find.text('Version 1.5.0'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      // Dismiss dialog by tapping "Later"
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      // Dialog should be gone
      expect(find.text('New Update Available'), findsNothing);
    });

    testWidgets('Force update displays "Update Required" and does not have a "Later" button', (tester) async {
      const info = AppVersionInfo(
        platform: 'ANDROID',
        latestVersion: '2.0.0',
        minimumVersion: '1.8.0',
        forceUpdate: true,
        title: 'Update Required',
        message: 'A new version of AI Mock Interview is required to continue.',
        whatsNew: ['Critical security upgrade'],
        storeUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppUpdateDialog.show(
                    context: context,
                    updateInfo: info,
                    decision: UpdateDecision.force,
                  );
                },
                child: const Text('Open Force Update'),
              ),
            ),
          ),
        ),
      );

      // Trigger dialog
      await tester.tap(find.text('Open Force Update'));
      await tester.pumpAndSettle();

      // Verify content is displayed
      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);

      // Verify NO "Later" button is present
      expect(find.text('Later'), findsNothing);

      // Clean up dialog before test concludes
      Navigator.of(tester.element(find.byType(AppUpdateDialog))).pop();
      await tester.pumpAndSettle();
    });
  });
}
