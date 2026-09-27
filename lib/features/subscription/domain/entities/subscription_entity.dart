/// Subscription entity — mirrors the backend /api/v1/subscriptions/me response.
/// isPremium is the authoritative entitlement flag from the backend.
/// Flutter must NOT permanently store isPremium locally as source of truth.
class SubscriptionEntity {
  final String? subscriptionId; // Internal DB subscription ID
  final String? plan; // e.g. "PREMIUM_MONTHLY" | "FREE"
  final String? status; // e.g. "ACTIVE", "CANCELLED" …
  final bool isPremium; // backend-authoritative entitlement
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool autoRenew;
  final DateTime? cancelledAt;

  const SubscriptionEntity({
    this.subscriptionId,
    this.plan,
    this.status,
    required this.isPremium,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.autoRenew = false,
    this.cancelledAt,
  });

  static const SubscriptionEntity free = SubscriptionEntity(
    plan: 'FREE',
    isPremium: false,
  );

  bool get isFree => !isPremium;
  bool get isActive => status == 'ACTIVE';
  bool get isCancelled => status == 'CANCELLED';
  bool get isMonthly => plan == 'PREMIUM_MONTHLY';
  bool get isYearly => plan == 'PREMIUM_YEARLY';

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
