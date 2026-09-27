import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PlanEntity>> getPlans() {
    return remoteDataSource.getPlans();
  }

  @override
  Future<SubscriptionEntity> getMySubscription() {
    return remoteDataSource.getMySubscription();
  }

  @override
  Future<Map<String, String>> createSubscription(String planCode) {
    return remoteDataSource.createSubscription(planCode);
  }

  @override
  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  }) {
    return remoteDataSource.verifyPayment(
      razorpayPaymentId: razorpayPaymentId,
      razorpaySubscriptionId: razorpaySubscriptionId,
      razorpaySignature: razorpaySignature,
    );
  }

  @override
  Future<void> cancelSubscription(
    String subscriptionId, {
    bool cancelAtCycleEnd = true,
  }) {
    return remoteDataSource.cancelSubscription(
      subscriptionId,
      cancelAtCycleEnd: cancelAtCycleEnd,
    );
  }
}
