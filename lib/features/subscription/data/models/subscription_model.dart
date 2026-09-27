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
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      subscriptionId: json['subscriptionId'] as String?,
      plan: json['plan'] as String?,
      status: json['status'] as String?,
      isPremium: (json['isPremium'] as bool?) ?? false,
      currentPeriodStart: _parseDate(json['currentPeriodStart']),
      currentPeriodEnd: _parseDate(json['currentPeriodEnd']),
      autoRenew: (json['autoRenew'] as bool?) ?? false,
      cancelledAt: _parseDate(json['cancelledAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
