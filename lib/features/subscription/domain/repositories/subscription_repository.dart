import '../entities/plan_entity.dart';
import '../entities/subscription_entity.dart';

/// Abstract repository interface for subscriptions.
/// Follows the same Clean Architecture pattern as auth feature.
abstract class SubscriptionRepository {
  /// Fetch available plans from backend.
  Future<List<PlanEntity>> getPlans();

  /// Get current user's subscription status.
  /// Flutter calls this on app start / profile load to restore state.
  Future<SubscriptionEntity> getMySubscription();

  /// Create a Razorpay subscription for the given plan code.
  /// Returns [razorpaySubscriptionId] and [razorpayKeyId] needed for checkout.
  Future<Map<String, String>> createSubscription(String planCode);

  /// Verify a payment after Razorpay checkout success callback.
  Future<bool> verifyPayment({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  });

  /// Cancel a subscription (defaults to cancel-at-end-of-cycle).
  Future<void> cancelSubscription(String subscriptionId, {bool cancelAtCycleEnd = true});
}
