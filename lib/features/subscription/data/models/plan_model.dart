import '../../domain/entities/plan_entity.dart';

/// Data model for Plan — handles JSON deserialization from backend response.
class PlanModel extends PlanEntity {
  const PlanModel({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.priceInPaise,
    required super.currency,
    required super.billingInterval,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      priceInPaise: json['priceInPaise'] as int,
      currency: (json['currency'] as String?) ?? 'INR',
      billingInterval: json['billingInterval'] as String,
    );
  }
}
