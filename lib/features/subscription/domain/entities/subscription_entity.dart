/// Subscription plan tier enum.
enum PlanTier {
  free,
  pro,
}

/// Subscription entity — mirrors the backend /api/v1/subscriptions/me response.
/// isPremium and planTier are backend-authoritative entitlements.
class SubscriptionEntity {
  final String? subscriptionId; // Internal DB subscription ID
  final String? plan; // e.g. "PRO_MONTHLY" | "FREE"
  final String? status; // e.g. "ACTIVE", "CANCELLED" …
  final bool isPremium; // backend-authoritative entitlement
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool autoRenew;
  final DateTime? cancelledAt;

  // Authoritative entitlement fields
  final PlanTier planTier;
  final int interviewsLimit;
  final int interviewsUsed;
  final int interviewsRemaining;
  final int maxQuestionsPerSession;
  final bool canUseVoice;
  final bool canUseAdvancedPersonas;
  final bool canUseDeepDive;
  final bool canUseFullEvaluation;
  final bool canUseFullRoadmap;
  final bool canUseAdvancedAnalytics;
  final bool canExportPdf;
  final int maxResumeScans;
  final int resumeScansUsed;
  final int resumeScansRemaining;

  const SubscriptionEntity({
    this.subscriptionId,
    this.plan,
    this.status,
    required this.isPremium,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.autoRenew = false,
    this.cancelledAt,
    this.planTier = PlanTier.free,
    this.interviewsLimit = 2,
    this.interviewsUsed = 0,
    this.interviewsRemaining = 2,
    this.maxQuestionsPerSession = 5,
    this.canUseVoice = false,
    this.canUseAdvancedPersonas = false,
    this.canUseDeepDive = false,
    this.canUseFullEvaluation = false,
    this.canUseFullRoadmap = false,
    this.canUseAdvancedAnalytics = false,
    this.canExportPdf = false,
    this.maxResumeScans = 1,
    this.resumeScansUsed = 0,
    this.resumeScansRemaining = 1,
  });

  static const SubscriptionEntity free = SubscriptionEntity(
    plan: 'FREE',
    isPremium: false,
    planTier: PlanTier.free,
    interviewsLimit: 2,
    interviewsUsed: 0,
    interviewsRemaining: 2,
    maxQuestionsPerSession: 5,
    canUseVoice: false,
    canUseAdvancedPersonas: false,
    canUseDeepDive: false,
    canUseFullEvaluation: false,
    canUseFullRoadmap: false,
    canUseAdvancedAnalytics: false,
    canExportPdf: false,
    maxResumeScans: 1,
    resumeScansUsed: 0,
    resumeScansRemaining: 1,
  );

  bool get isFree => planTier == PlanTier.free;
  bool get isPro => planTier == PlanTier.pro;
  bool get isActive => status == 'ACTIVE';
  bool get isCancelled => status == 'CANCELLED';
  bool get isMonthly => plan?.contains('MONTHLY') == true;
  bool get isYearly => plan?.contains('YEARLY') == true;

  /// Formatted renewal / expiry date string.
  String? get periodEndFormatted {
    if (currentPeriodEnd == null) return null;
    final d = currentPeriodEnd!;
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
