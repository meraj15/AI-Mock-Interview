import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

// ── Payment State ──────────────────────────────────────────────────────────────

enum SubscriptionLoadStatus { initial, loading, loaded, error }

enum PaymentState {
  idle,
  creatingSubscription,   // Calling backend to get Razorpay subscription ID
  openingCheckout,        // Razorpay SDK checkout is open
  verifying,              // Verifying payment with backend after success callback
  success,                // Backend confirmed Premium
  failed,                 // Payment failed
  cancelled,              // User cancelled checkout
  networkError,           // Payment may have succeeded; network lost
}

class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository _repository;
  final Razorpay _razorpay = Razorpay();

  // ── State ──────────────────────────────────────────────────────────────────

  SubscriptionLoadStatus _loadStatus = SubscriptionLoadStatus.initial;
  PaymentState _paymentState = PaymentState.idle;

  List<PlanEntity> _plans = [];
  SubscriptionEntity _subscription = SubscriptionEntity.free;

  String? _errorMessage;
  String? _selectedPlanCode;
  bool _isSubscribing = false; // Prevents duplicate tap
  bool _isCancelling = false;

  // Holds the razorpaySubscriptionId during an active checkout
  String? _activeRazorpaySubscriptionId;

  // ── Constructor ────────────────────────────────────────────────────────────

  SubscriptionController({required SubscriptionRepository repository})
      : _repository = repository {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  SubscriptionLoadStatus get loadStatus => _loadStatus;
  PaymentState get paymentState => _paymentState;
  List<PlanEntity> get plans => _plans;
  SubscriptionEntity get subscription => _subscription;
  String? get errorMessage => _errorMessage;
  String? get selectedPlanCode => _selectedPlanCode;
  bool get isLoading => _loadStatus == SubscriptionLoadStatus.loading;
  bool get isSubscribing => _isSubscribing;
  bool get isCancelling => _isCancelling;
  bool get isPremium => _subscription.isPremium;

  PlanEntity? get selectedPlan {
    if (_selectedPlanCode == null) return null;
    try {
      return _plans.firstWhere((p) => p.code == _selectedPlanCode);
    } catch (_) {
      return null;
    }
  }

  PlanEntity? get monthlyPlan {
    try {
      return _plans.firstWhere((p) => p.isMonthly);
    } catch (_) {
      return null;
    }
  }

  PlanEntity? get yearlyPlan {
    try {
      return _plans.firstWhere((p) => p.isYearly);
    } catch (_) {
      return null;
    }
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  /// Load plans and current subscription status from the backend.
  /// Call this when the Premium screen opens.
  Future<void> loadAll() async {
    _loadStatus = SubscriptionLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getPlans(),
        _repository.getMySubscription(),
      ]);

      _plans = results[0] as List<PlanEntity>;
      _subscription = results[1] as SubscriptionEntity;

      // Auto-select the cheaper plan if nothing selected yet
      if (_selectedPlanCode == null && _plans.isNotEmpty) {
        _selectedPlanCode = _plans.first.code;
      }

      _loadStatus = SubscriptionLoadStatus.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _loadStatus = SubscriptionLoadStatus.error;
    }

    notifyListeners();
  }

  /// Refresh only the subscription status (e.g. after payment, app resume).
  Future<void> refreshSubscription() async {
    try {
      _subscription = await _repository.getMySubscription();
      notifyListeners();
    } catch (_) {
      // Silently ignore refresh errors — don't disrupt UI
    }
  }

  // ── Plan Selection ─────────────────────────────────────────────────────────

  void selectPlan(String planCode) {
    if (_selectedPlanCode != planCode) {
      _selectedPlanCode = planCode;
      notifyListeners();
    }
  }

  // ── Subscribe Flow ─────────────────────────────────────────────────────────

  /// Main subscribe action. Prevents duplicate simultaneous requests.
  ///
  /// Flow:
  ///   1. Call backend → get Razorpay subscription ID + key ID
  ///   2. Open Razorpay Checkout
  ///   3. On success → call backend verify
  ///   4. On failure/cancel → show user-friendly state
  Future<void> subscribe() async {
    if (_isSubscribing || _selectedPlanCode == null) return;
    if (_paymentState == PaymentState.openingCheckout ||
        _paymentState == PaymentState.creatingSubscription ||
        _paymentState == PaymentState.verifying) { return; }

    _isSubscribing = true;
    _errorMessage = null;
    _paymentState = PaymentState.creatingSubscription;
    notifyListeners();

    try {
      // 1. Backend creates Razorpay subscription and returns checkout params
      final checkoutData = await _repository.createSubscription(_selectedPlanCode!);

      final razorpaySubscriptionId = checkoutData['razorpaySubscriptionId'];
      final razorpayOrderId = checkoutData['razorpayOrderId'];
      final razorpayKeyId = checkoutData['razorpayKeyId'];

      if (razorpaySubscriptionId == null || razorpayKeyId == null) {
        throw ServerException('Checkout configuration invalid. Please try again.');
      }

      _activeRazorpaySubscriptionId = razorpaySubscriptionId;
      _paymentState = PaymentState.openingCheckout;
      notifyListeners();

      final plan = selectedPlan;
      final isOrder = (razorpayOrderId != null && razorpayOrderId.isNotEmpty) ||
          razorpaySubscriptionId.startsWith('order_');
      final effectiveOrderId = (razorpayOrderId != null && razorpayOrderId.isNotEmpty)
          ? razorpayOrderId
          : razorpaySubscriptionId;

      final options = <String, dynamic>{
        'key': razorpayKeyId,
        if (isOrder) 'order_id': effectiveOrderId,
        if (!isOrder) 'subscription_id': razorpaySubscriptionId,
        'name': 'Interview Coach',
        'description': plan?.name ?? 'Premium Subscription',
        'prefill': {},
        'theme': {'color': '#4268E8'},
      };

      _razorpay.open(options);
      // Control flow continues in callbacks below
    } on NetworkException catch (e) {
      _isSubscribing = false;
      _paymentState = PaymentState.networkError;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isSubscribing = false;
      _paymentState = PaymentState.failed;
      _errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  // ── Razorpay Checkout Callbacks ────────────────────────────────────────────

  /// Called by Razorpay SDK when payment completes in checkout.
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId;
    final signature = response.signature;
    final subscriptionId = _activeRazorpaySubscriptionId;

    if (paymentId == null || signature == null || subscriptionId == null) {
      _paymentState = PaymentState.failed;
      _errorMessage = 'Payment response was incomplete. Please check your subscription status.';
      _isSubscribing = false;
      notifyListeners();
      return;
    }

    // Notify UI that we're verifying (not done yet — backend is authoritative)
    _paymentState = PaymentState.verifying;
    notifyListeners();

    // Verify with backend asynchronously
    _verifyWithBackend(
      razorpayPaymentId: paymentId,
      razorpaySubscriptionId: subscriptionId,
      razorpaySignature: signature,
    );
  }

  /// Called by Razorpay SDK on payment failure.
  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentState = PaymentState.failed;
    _isSubscribing = false;

    // Map Razorpay error codes to user-friendly messages
    final code = response.code;
    if (code == Razorpay.NETWORK_ERROR) {
      // Payment may have gone through — do NOT tell user payment failed
      _paymentState = PaymentState.networkError;
      _errorMessage =
          'Your payment may have been completed. We\'re checking your subscription status.';
      // Attempt a background refresh
      refreshSubscription();
    } else if (code == Razorpay.PAYMENT_CANCELLED) {
      _paymentState = PaymentState.cancelled;
      _errorMessage = 'Payment was cancelled.';
    } else {
      _errorMessage = 'Payment could not be completed. Please try again.';
    }

    notifyListeners();
  }

  /// Called by Razorpay SDK when external wallet is selected.
  void _handleExternalWallet(ExternalWalletResponse response) {
    // Treat as cancelled for now — user chose an external wallet
    _paymentState = PaymentState.cancelled;
    _isSubscribing = false;
    _errorMessage = 'External wallet selected. Please complete payment in the wallet app.';
    notifyListeners();
  }

  /// Send payment identifiers to backend for server-side verification.
  /// CRITICAL: Do not grant Premium based on Flutter callback alone.
  Future<void> _verifyWithBackend({
    required String razorpayPaymentId,
    required String razorpaySubscriptionId,
    required String razorpaySignature,
  }) async {
    try {
      final isPremiumNow = await _repository.verifyPayment(
        razorpayPaymentId: razorpayPaymentId,
        razorpaySubscriptionId: razorpaySubscriptionId,
        razorpaySignature: razorpaySignature,
      );

      if (isPremiumNow) {
        _paymentState = PaymentState.success;
        // Refresh the full subscription object from backend
        await refreshSubscription();
      } else {
        // Backend says not yet activated (webhook may be in-flight)
        _paymentState = PaymentState.verifying;
        _errorMessage =
            'Payment processing... Your subscription will activate shortly.';
        // Retry once after a short delay
        await Future.delayed(const Duration(seconds: 3));
        await refreshSubscription();
        _paymentState = _subscription.isPremium
            ? PaymentState.success
            : PaymentState.verifying;
      }
    } on NetworkException {
      // Network lost AFTER payment — do NOT say payment failed
      _paymentState = PaymentState.networkError;
      _errorMessage =
          'Your payment may have been completed. We\'re checking your subscription status.';
      await refreshSubscription();
    } catch (e) {
      _paymentState = PaymentState.failed;
      _errorMessage = _friendlyError(e);
    } finally {
      _isSubscribing = false;
      _activeRazorpaySubscriptionId = null;
      notifyListeners();
    }
  }

  // ── Cancel Subscription ────────────────────────────────────────────────────

  Future<bool> cancelSubscription({bool cancelAtCycleEnd = true}) async {
    final sub = _subscription;
    if (sub.status == null || sub.isFree) return false;

    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // We use the subscriptionId from the subscription entity.
      // The controller does not have the internal ID directly — we refresh
      // to get the actual sub data. For the MVP, we'll use a special cancel
      // endpoint that the backend can match by userId (the auth token identifies the user).
      // For now, pass an empty string — the backend uses the user's active subscription.
      // In a more complete implementation you'd store the subscriptionId in the entity.
      await _repository.cancelSubscription('me', cancelAtCycleEnd: cancelAtCycleEnd);
      await refreshSubscription();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void resetPaymentState() {
    _paymentState = PaymentState.idle;
    _errorMessage = null;
    _isSubscribing = false;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    if (e is NetworkException) return e.message;
    if (e is ServerException) return e.message;
    if (e is AuthException) return e.message;
    if (e is ValidationException) return e.message;
    return 'Something went wrong. Please try again.';
  }
}
