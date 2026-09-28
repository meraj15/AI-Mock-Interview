import 'package:flutter_test/flutter_test.dart';
import 'package:interview_coach/features/subscription/data/models/subscription_model.dart';
import 'package:interview_coach/features/subscription/domain/entities/plan_entity.dart';
import 'package:interview_coach/features/subscription/domain/entities/subscription_entity.dart';
import 'package:interview_coach/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:interview_coach/features/subscription/presentation/controllers/subscription_controller.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionEntity? currentSub;

  @override
  Future<List<PlanEntity>> getPlans() async => [];

  @override
  Future<SubscriptionEntity> getMySubscription() async {
    return currentSub ??
        SubscriptionModel.fromJson({
          'id': 'free_default',
          'status': 'ACTIVE',
          'planCode': 'FREE',
          'billingInterval': 'MONTHLY',
          'amount': 0,
          'currency': 'INR',
          'entitlement': {
            'tier': 'FREE',
            'isPremium': false,
            'interviewsLimit': 2,
            'interviewsUsed': 0,
            'interviewsRemaining': 2,
            'maxQuestionsPerSession': 5,
            'canUseVoice': false,
            'canUseAdvancedPersonas': false,
            'canUseDeepDive': false,
            'canUseFullEvaluation': false,
            'canUseFullRoadmap': false,
            'canUseAdvancedAnalytics': false,
            'canExportPdf': false,
            'maxResumeScans': 1,
            'resumeScansUsed': 0,
            'resumeScansRemaining': 1,
          },
        });
  }

  @override
  Future<Map<String, String>> createSubscription(String planCode) async => {};

  @override
  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  }) async =>
      true;

  @override
  Future<void> cancelSubscription(String subscriptionId,
      {bool cancelAtCycleEnd = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription & Entitlement Entity & Model', () {
    test('Correctly parses FREE entitlement from backend API payload', () {
      final json = {
        'id': 'sub_free_123',
        'userId': 'usr_456',
        'planId': 'free_plan',
        'status': 'ACTIVE',
        'planCode': 'FREE',
        'billingInterval': 'MONTHLY',
        'amount': 0,
        'currency': 'INR',
        'entitlement': {
          'tier': 'FREE',
          'isPremium': false,
          'interviewsLimit': 2,
          'interviewsUsed': 1,
          'interviewsRemaining': 1,
          'maxQuestionsPerSession': 5,
          'canUseVoice': false,
          'canUseAdvancedPersonas': false,
          'canUseDeepDive': false,
          'canUseFullEvaluation': false,
          'canUseFullRoadmap': false,
          'canUseAdvancedAnalytics': false,
          'canExportPdf': false,
          'maxResumeScans': 1,
          'resumeScansUsed': 0,
          'resumeScansRemaining': 1,
        },
      };

      final sub = SubscriptionModel.fromJson(json);

      expect(sub.planTier, PlanTier.free);
      expect(sub.isFree, isTrue);
      expect(sub.isPro, isFalse);
      expect(sub.interviewsLimit, 2);
      expect(sub.interviewsUsed, 1);
      expect(sub.interviewsRemaining, 1);
      expect(sub.maxQuestionsPerSession, 5);
      expect(sub.canUseVoice, isFalse);
      expect(sub.canUseDeepDive, isFalse);
      expect(sub.canUseAdvancedPersonas, isFalse);
      expect(sub.canUseFullEvaluation, isFalse);
      expect(sub.canUseFullRoadmap, isFalse);
      expect(sub.canUseAdvancedAnalytics, isFalse);
      expect(sub.canExportPdf, isFalse);
      expect(sub.maxResumeScans, 1);
      expect(sub.resumeScansRemaining, 1);
    });

    test('Correctly parses PRO entitlement from backend API payload', () {
      final json = {
        'id': 'sub_pro_789',
        'userId': 'usr_456',
        'planId': 'plan_pro_monthly',
        'status': 'ACTIVE',
        'planCode': 'PRO_MONTHLY',
        'billingInterval': 'MONTHLY',
        'amount': 29900,
        'currency': 'INR',
        'entitlement': {
          'tier': 'PRO',
          'isPremium': true,
          'interviewsLimit': 30,
          'interviewsUsed': 4,
          'interviewsRemaining': 26,
          'maxQuestionsPerSession': 12,
          'canUseVoice': true,
          'canUseAdvancedPersonas': true,
          'canUseDeepDive': true,
          'canUseFullEvaluation': true,
          'canUseFullRoadmap': true,
          'canUseAdvancedAnalytics': true,
          'canExportPdf': true,
          'maxResumeScans': 5,
          'resumeScansUsed': 2,
          'resumeScansRemaining': 3,
        },
      };

      final sub = SubscriptionModel.fromJson(json);

      expect(sub.planTier, PlanTier.pro);
      expect(sub.isPro, isTrue);
      expect(sub.isFree, isFalse);
      expect(sub.interviewsLimit, 30);
      expect(sub.interviewsUsed, 4);
      expect(sub.interviewsRemaining, 26);
      expect(sub.maxQuestionsPerSession, 12);
      expect(sub.canUseVoice, isTrue);
      expect(sub.canUseDeepDive, isTrue);
      expect(sub.canUseAdvancedPersonas, isTrue);
      expect(sub.canUseFullEvaluation, isTrue);
      expect(sub.canUseFullRoadmap, isTrue);
      expect(sub.canUseAdvancedAnalytics, isTrue);
      expect(sub.canExportPdf, isTrue);
      expect(sub.maxResumeScans, 5);
      expect(sub.resumeScansRemaining, 3);
    });

    test('SubscriptionController exposes correct defaults and getters', () {
      final fakeRepo = FakeSubscriptionRepository();
      final controller = SubscriptionController(repository: fakeRepo);

      // Default state when no subscription is loaded yet
      expect(controller.planTier, PlanTier.free);
      expect(controller.isFree, isTrue);
      expect(controller.isPro, isFalse);
      expect(controller.interviewsRemaining, 2);
      expect(controller.maxQuestionsPerSession, 5);
      expect(controller.canUseVoice, isFalse);
      expect(controller.canUseDeepDive, isFalse);
      expect(controller.canExportPdf, isFalse);
    });
  });
}
