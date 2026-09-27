/// Plan entity — represents a subscription plan as returned by the backend.
/// Prices come from the backend (never hardcoded in Flutter).
class PlanEntity {
  final String id;
  final String code; // e.g. "PREMIUM_MONTHLY"
  final String name;
  final String description;
  final int priceInPaise; // smallest currency unit
  final String currency;
  final String billingInterval; // "MONTHLY" | "YEARLY"

  const PlanEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.priceInPaise,
    required this.currency,
    required this.billingInterval,
  });

  /// Formatted price string, e.g. "₹199/month"
  String get formattedPrice {
    final amount = (priceInPaise / 100).toStringAsFixed(0);
    final period = billingInterval == 'MONTHLY' ? 'month' : 'year';
    return '₹$amount/$period';
  }

  bool get isMonthly => billingInterval == 'MONTHLY';
  bool get isYearly => billingInterval == 'YEARLY';
}
