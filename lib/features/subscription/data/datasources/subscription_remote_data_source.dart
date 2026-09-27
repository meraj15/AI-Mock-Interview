import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<PlanModel>> getPlans();
  Future<SubscriptionModel> getMySubscription();
  Future<Map<String, String>> createSubscription(String planCode);
  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  });
  Future<void> cancelSubscription(String subscriptionId, {bool cancelAtCycleEnd = true});
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient apiClient;

  SubscriptionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PlanModel>> getPlans() async {
    final response = await apiClient.get(ApiConfig.subscriptionPlansEndpoint);
    final data = response.data as Map<String, dynamic>;
    final plansJson = data['plans'] as List<dynamic>;
    return plansJson
        .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SubscriptionModel> getMySubscription() async {
    final response = await apiClient.get(ApiConfig.subscriptionMeEndpoint);
    final data = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(data);
  }

  @override
  Future<Map<String, String>> createSubscription(String planCode) async {
    final response = await apiClient.post(
      ApiConfig.subscriptionCreateEndpoint,
      body: {'planCode': planCode},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'subscriptionId': data['subscriptionId'] as String,
      'razorpaySubscriptionId': data['razorpaySubscriptionId'] as String,
      'razorpayKeyId': data['razorpayKeyId'] as String,
    };
  }

  @override
  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  }) async {
    final response = await apiClient.post(
      ApiConfig.subscriptionVerifyEndpoint,
      body: {
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySubscriptionId': razorpaySubscriptionId,
        'razorpaySignature': razorpaySignature,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['isPremium'] as bool?) ?? false;
  }

  @override
  Future<void> cancelSubscription(
    String subscriptionId, {
    bool cancelAtCycleEnd = true,
  }) async {
    // Use the /me/cancel convenience endpoint — Flutter doesn't need to
    // manage internal DB subscription IDs.
    await apiClient.post(
      ApiConfig.subscriptionMeCancelEndpoint,
      body: {'cancelAtCycleEnd': cancelAtCycleEnd},
    );
  }
}
