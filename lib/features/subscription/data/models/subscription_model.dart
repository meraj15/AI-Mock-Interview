import '../../domain/entities/subscription_entity.dart';

/// Data model for Subscription — handles JSON deserialization from backend response.
class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    super.subscriptionId,
    super.plan,
    super.status,
    required super.isPremium,
    super.currentPeriodStart,
    super.currentPeriodEnd,
    super.autoRenew,
    super.cancelledAt,
    super.planTier,
    super.interviewsLimit,
    super.interviewsUsed,
    super.interviewsRemaining,
    super.maxQuestionsPerSession,
    super.canUseVoice,
    super.canUseAdvancedPersonas,
    super.canUseDeepDive,
    super.canUseFullEvaluation,
    super.canUseFullRoadmap,
    super.canUseAdvancedAnalytics,
    super.canExportPdf,
    super.maxResumeScans,
    super.resumeScansUsed,
    super.resumeScansRemaining,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final entJson = json['entitlement'] as Map<String, dynamic>?;
    final isPremium = (json['isPremium'] as bool?) ?? (entJson?['isPremium'] as bool?) ?? false;
    final tierStr = (entJson?['tier'] as String?)?.toUpperCase();
    final tier = (tierStr == 'PRO' || isPremium) ? PlanTier.pro : PlanTier.free;

    return SubscriptionModel(
      subscriptionId: json['subscriptionId'] as String?,
      plan: json['plan'] as String?,
      status: json['status'] as String?,
      isPremium: isPremium,
      currentPeriodStart: _parseDate(json['currentPeriodStart']),
      currentPeriodEnd: _parseDate(json['currentPeriodEnd']),
      autoRenew: (json['autoRenew'] as bool?) ?? false,
      cancelledAt: _parseDate(json['cancelledAt']),
      planTier: tier,
      interviewsLimit: (entJson?['interviewsLimit'] as num?)?.toInt() ?? (isPremium ? 30 : 2),
      interviewsUsed: (entJson?['interviewsUsed'] as num?)?.toInt() ?? 0,
      interviewsRemaining: (entJson?['interviewsRemaining'] as num?)?.toInt() ?? (isPremium ? 30 : 2),
      maxQuestionsPerSession: (entJson?['maxQuestionsPerSession'] as num?)?.toInt() ?? (isPremium ? 12 : 5),
      canUseVoice: (entJson?['canUseVoice'] as bool?) ?? isPremium,
      canUseAdvancedPersonas: (entJson?['canUseAdvancedPersonas'] as bool?) ?? isPremium,
      canUseDeepDive: (entJson?['canUseDeepDive'] as bool?) ?? isPremium,
      canUseFullEvaluation: (entJson?['canUseFullEvaluation'] as bool?) ?? isPremium,
      canUseFullRoadmap: (entJson?['canUseFullRoadmap'] as bool?) ?? isPremium,
      canUseAdvancedAnalytics: (entJson?['canUseAdvancedAnalytics'] as bool?) ?? isPremium,
      canExportPdf: (entJson?['canExportPdf'] as bool?) ?? isPremium,
      maxResumeScans: (entJson?['maxResumeScans'] as num?)?.toInt() ?? (isPremium ? 5 : 1),
      resumeScansUsed: (entJson?['resumeScansUsed'] as num?)?.toInt() ?? 0,
      resumeScansRemaining: (entJson?['resumeScansRemaining'] as num?)?.toInt() ?? (isPremium ? 5 : 1),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
