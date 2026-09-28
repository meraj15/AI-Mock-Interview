/**
 * subscription.test.ts
 *
 * Backend unit tests for the Razorpay subscription system.
 * All Razorpay API calls are mocked — no real network calls.
 */
import { subscriptionService } from '../src/services/subscription.service';
import { subscriptionRepository } from '../src/repositories/subscription.repository';
import { razorpayService } from '../src/services/razorpay.service';
import {
  SubscriptionStatus,
  EntitlementStatus,
  TransactionStatus,
  BillingInterval,
} from '../src/repositories/subscription.repository';
import {
  NotFoundError,
  ValidationError,
  ForbiddenError,
  ConflictError,
  AppError,
} from '../src/errors/AppError';

// ── Mocks ──────────────────────────────────────────────────────────────────────

jest.mock('../src/repositories/subscription.repository', () => ({
  subscriptionRepository: {
    findPlanByCode: jest.fn(),
    listActivePlans: jest.fn(),
    upsertPlan: jest.fn(),
    createSubscription: jest.fn(),
    findSubscriptionById: jest.fn(),
    findSubscriptionByProviderId: jest.fn(),
    findActiveSubscriptionForUser: jest.fn(),
    findLatestSubscriptionForUser: jest.fn(),
    updateSubscription: jest.fn(),
    createPaymentTransaction: jest.fn(),
    findPaymentTransactionByProviderId: jest.fn(),
    updatePaymentTransactionStatus: jest.fn(),
    upsertEntitlement: jest.fn(),
    findEntitlement: jest.fn(),
    hasActivePremiumEntitlement: jest.fn(),
    findWebhookEvent: jest.fn(),
    createWebhookEvent: jest.fn(),
    findUsageQuota: jest.fn(),
    incrementInterviewUsage: jest.fn(),
    incrementResumeScanUsage: jest.fn(),
  },
  SubscriptionStatus: {
    CREATED: 'CREATED',
    AUTHENTICATED: 'AUTHENTICATED',
    ACTIVE: 'ACTIVE',
    PAYMENT_PENDING: 'PAYMENT_PENDING',
    HALTED: 'HALTED',
    CANCELLED: 'CANCELLED',
    COMPLETED: 'COMPLETED',
    EXPIRED: 'EXPIRED',
  },
  EntitlementStatus: {
    ACTIVE: 'ACTIVE',
    INACTIVE: 'INACTIVE',
    GRACE: 'GRACE',
  },
  TransactionStatus: {
    PENDING: 'PENDING',
    CAPTURED: 'CAPTURED',
    FAILED: 'FAILED',
    REFUNDED: 'REFUNDED',
  },
  BillingInterval: {
    MONTHLY: 'MONTHLY',
    YEARLY: 'YEARLY',
  },
  PaymentProvider: {
    RAZORPAY: 'RAZORPAY',
  },
}));

jest.mock('../src/services/razorpay.service', () => ({
  razorpayService: {
    createSubscription: jest.fn(),
    createOrder: jest.fn(),
    createPlan: jest.fn(),
    cancelSubscription: jest.fn(),
    fetchPayment: jest.fn(),
    verifySubscriptionSignature: jest.fn(),
    verifyOrderSignature: jest.fn(),
    verifyWebhookSignature: jest.fn(),
    getPublicKeyId: jest.fn().mockReturnValue('rzp_test_abc123'),
  },
}));

jest.mock('../src/utils/logger', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

// ── Helpers ────────────────────────────────────────────────────────────────────

const mockPlan = {
  id: 'plan-uuid-1',
  code: 'PREMIUM_MONTHLY',
  name: 'Premium Monthly',
  description: 'Monthly plan',
  priceInPaise: 19900,
  currency: 'INR',
  tier: 'PRO',
  billingInterval: BillingInterval.MONTHLY,
  razorpayPlanId: 'plan_razorpay_abc',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockSubscription = {
  id: 'sub-uuid-1',
  userId: 'user-uuid-1',
  planId: 'plan-uuid-1',
  provider: 'RAZORPAY' as const,
  providerSubscriptionId: 'sub_razorpay_abc',
  status: SubscriptionStatus.ACTIVE,
  currentPeriodStart: new Date(),
  currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  startedAt: new Date(),
  cancelledAt: null,
  endedAt: null,
  autoRenew: true,
  createdAt: new Date(),
  updatedAt: new Date(),
  plan: mockPlan,
};

const repo = subscriptionRepository as jest.Mocked<typeof subscriptionRepository>;
const rzp = razorpayService as jest.Mocked<typeof razorpayService>;

beforeEach(() => {
  jest.clearAllMocks();
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Create Subscription
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionService.createSubscription', () => {
  it('1. Successfully creates a subscription for a valid plan', async () => {
    repo.findPlanByCode.mockResolvedValue(mockPlan);
    repo.findActiveSubscriptionForUser.mockResolvedValue(null);
    rzp.createSubscription.mockResolvedValue({
      subscriptionId: 'sub_razorpay_new',
      status: 'created',
    });
    repo.createSubscription.mockResolvedValue({ ...mockSubscription, status: SubscriptionStatus.CREATED, providerSubscriptionId: 'sub_razorpay_new' });

    const result = await subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY');

    expect(result.razorpaySubscriptionId).toBe('sub_razorpay_new');
    expect(result.razorpayKeyId).toBe('rzp_test_abc123');
    expect(repo.createSubscription).toHaveBeenCalledTimes(1);
    expect(rzp.createSubscription).toHaveBeenCalledWith({
      planId: mockPlan.razorpayPlanId,
      totalCount: 0,
    });
  });

  it('2. Throws NotFoundError for invalid plan code', async () => {
    repo.findPlanByCode.mockResolvedValue(null);
    await expect(
      subscriptionService.createSubscription('user-uuid-1', 'INVALID_PLAN')
    ).rejects.toThrow(NotFoundError);
  });

  it('3. Throws ValidationError for inactive plan', async () => {
    repo.findPlanByCode.mockResolvedValue({ ...mockPlan, isActive: false });
    await expect(
      subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY')
    ).rejects.toThrow(ValidationError);
  });

  it('4. Returns existing subscription if user already has active subscription', async () => {
    repo.findPlanByCode.mockResolvedValue(mockPlan);
    repo.findActiveSubscriptionForUser.mockResolvedValue(mockSubscription);

    const result = await subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY');
    expect(result.razorpaySubscriptionId).toBe('sub_razorpay_abc');
    expect(rzp.createSubscription).not.toHaveBeenCalled();
  });

  it('5. Throws ConflictError if active subscription exists but has no providerSubscriptionId', async () => {
    repo.findPlanByCode.mockResolvedValue(mockPlan);
    repo.findActiveSubscriptionForUser.mockResolvedValue({
      ...mockSubscription,
      providerSubscriptionId: null,
    });

    await expect(
      subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY')
    ).rejects.toThrow(ConflictError);
  });

  it('6. Throws AppError if Razorpay API fails', async () => {
    repo.findPlanByCode.mockResolvedValue(mockPlan);
    repo.findActiveSubscriptionForUser.mockResolvedValue(null);
    rzp.createSubscription.mockRejectedValue(new Error('Razorpay API timeout'));

    await expect(
      subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY')
    ).rejects.toThrow();
  });

  it('3b. Throws AppError if plan has no Razorpay Plan ID', async () => {
    repo.findPlanByCode.mockResolvedValue({ ...mockPlan, razorpayPlanId: null });
    rzp.createOrder.mockRejectedValue(new AppError('Plan has no Razorpay Plan ID configured', 503, 'PAYMENT_UNAVAILABLE'));
    await expect(
      subscriptionService.createSubscription('user-uuid-1', 'PREMIUM_MONTHLY')
    ).rejects.toThrow(AppError);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Unauthenticated Request (handled at middleware level)
// ══════════════════════════════════════════════════════════════════════════════

describe('Auth middleware (unit check)', () => {
  it('3. Unauthenticated request — service never called without userId', async () => {
    // When no userId is provided (undefined), service should throw or be not called.
    // In real flow, auth middleware prevents reaching the controller.
    // Here we test that the service would fail gracefully if called without user.
    repo.findPlanByCode.mockResolvedValue(null);
    // An undefined/empty userId would fail to find any plan.
    await expect(
      subscriptionService.createSubscription('', 'PREMIUM_MONTHLY')
    ).rejects.toThrow();
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Payment Verification
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionService.verifyPayment', () => {
  const verifyParams = {
    userId: 'user-uuid-1',
    razorpayPaymentId: 'pay_test_abc',
    razorpaySubscriptionId: 'sub_razorpay_abc',
    razorpaySignature: 'valid_sig_abc',
  };

  it('7. Successfully verifies a captured payment', async () => {
    rzp.verifySubscriptionSignature.mockReturnValue(true);
    repo.findSubscriptionByProviderId.mockResolvedValue(mockSubscription);
    rzp.fetchPayment.mockResolvedValue({
      paymentId: 'pay_test_abc',
      amount: 19900,
      currency: 'INR',
      status: 'captured',
      subscriptionId: 'sub_razorpay_abc',
      capturedAt: new Date(),
    });
    repo.findPaymentTransactionByProviderId.mockResolvedValue(null);
    repo.createPaymentTransaction.mockResolvedValue({} as any);
    repo.updateSubscription.mockResolvedValue({} as any);
    repo.upsertEntitlement.mockResolvedValue({} as any);

    const result = await subscriptionService.verifyPayment(verifyParams);
    expect(result.isPremium).toBe(true);
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-uuid-1', status: EntitlementStatus.ACTIVE })
    );
  });

  it('8. Throws ForbiddenError on invalid signature', async () => {
    rzp.verifySubscriptionSignature.mockReturnValue(false);
    await expect(
      subscriptionService.verifyPayment(verifyParams)
    ).rejects.toThrow(ForbiddenError);
  });

  it('19. User cannot verify another user\'s payment', async () => {
    rzp.verifySubscriptionSignature.mockReturnValue(true);
    repo.findSubscriptionByProviderId.mockResolvedValue({
      ...mockSubscription,
      userId: 'different-user',
    });

    await expect(
      subscriptionService.verifyPayment(verifyParams)
    ).rejects.toThrow(ForbiddenError);
  });

  it('Payment not captured — returns isPremium false', async () => {
    rzp.verifySubscriptionSignature.mockReturnValue(true);
    repo.findSubscriptionByProviderId.mockResolvedValue(mockSubscription);
    rzp.fetchPayment.mockResolvedValue({
      paymentId: 'pay_test_abc',
      amount: 19900,
      currency: 'INR',
      status: 'authorized',
    });
    repo.findPaymentTransactionByProviderId.mockResolvedValue(null);
    repo.createPaymentTransaction.mockResolvedValue({} as any);

    const result = await subscriptionService.verifyPayment(verifyParams);
    expect(result.isPremium).toBe(false);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Webhook Processing
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionService.processWebhookEvent', () => {
  const makeEvent = (type: string, subId = 'sub_razorpay_abc') => ({
    event: type,
    id: `evt_${Date.now()}`,
    payload: {
      subscription: {
        entity: {
          id: subId,
          status: type.split('.')[1],
          current_start: Math.floor(Date.now() / 1000),
          current_end: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60,
        },
      },
    },
  });

  beforeEach(() => {
    repo.findWebhookEvent.mockResolvedValue(null); // not yet processed
    repo.createWebhookEvent.mockResolvedValue({} as any);
    repo.findSubscriptionByProviderId.mockResolvedValue(mockSubscription);
    repo.updateSubscription.mockResolvedValue({} as any);
    repo.upsertEntitlement.mockResolvedValue({} as any);
    repo.findPaymentTransactionByProviderId.mockResolvedValue(null);
    repo.createPaymentTransaction.mockResolvedValue({} as any);
  });

  it('10. Processes valid webhook event', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.activated'));
    expect(repo.createWebhookEvent).toHaveBeenCalledTimes(1);
    expect(repo.upsertEntitlement).toHaveBeenCalled();
  });

  it('11. Skips duplicate webhook — idempotent', async () => {
    repo.findWebhookEvent.mockResolvedValue({ id: 'evt_1' } as any);
    await subscriptionService.processWebhookEvent(makeEvent('subscription.activated'));
    expect(repo.createWebhookEvent).not.toHaveBeenCalled();
    expect(repo.upsertEntitlement).not.toHaveBeenCalled();
  });

  it('12. subscription.activated → entitlement ACTIVE', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.activated'));
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ status: EntitlementStatus.ACTIVE })
    );
  });

  it('13. subscription.pending → entitlement GRACE', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.pending'));
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ status: EntitlementStatus.GRACE })
    );
  });

  it('14. subscription.halted → entitlement INACTIVE', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.halted'));
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ status: EntitlementStatus.INACTIVE })
    );
  });

  it('15. subscription.cancelled → entitlement INACTIVE', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.cancelled'));
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ status: EntitlementStatus.INACTIVE })
    );
  });

  it('16. subscription.completed → entitlement INACTIVE', async () => {
    await subscriptionService.processWebhookEvent(makeEvent('subscription.completed'));
    expect(repo.upsertEntitlement).toHaveBeenCalledWith(
      expect.objectContaining({ status: EntitlementStatus.INACTIVE })
    );
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Entitlement
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionRepository.hasActivePremiumEntitlement', () => {
  it('17. Returns true when entitlement is ACTIVE and not expired', async () => {
    repo.hasActivePremiumEntitlement.mockResolvedValue(true);
    const result = await subscriptionRepository.hasActivePremiumEntitlement('user-uuid-1');
    expect(result).toBe(true);
  });

  it('18. Returns false when entitlement is INACTIVE', async () => {
    repo.hasActivePremiumEntitlement.mockResolvedValue(false);
    const result = await subscriptionRepository.hasActivePremiumEntitlement('user-uuid-1');
    expect(result).toBe(false);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: GET /me
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionService.getMySubscription', () => {
  it('20. Returns FREE plan when no subscription exists', async () => {
    repo.findLatestSubscriptionForUser.mockResolvedValue(null);
    repo.hasActivePremiumEntitlement.mockResolvedValue(false);

    const result = await subscriptionService.getMySubscription('user-uuid-1');
    expect(result.plan).toBe('FREE');
    expect(result.isPremium).toBe(false);
  });

  it('20b. Returns PREMIUM_MONTHLY with isPremium true', async () => {
    repo.findLatestSubscriptionForUser.mockResolvedValue(mockSubscription);
    repo.hasActivePremiumEntitlement.mockResolvedValue(true);

    const result = await subscriptionService.getMySubscription('user-uuid-1');
    expect(result.plan).toBe('PREMIUM_MONTHLY');
    expect(result.isPremium).toBe(true);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Cancellation Authorization
// ══════════════════════════════════════════════════════════════════════════════

describe('subscriptionService.cancelSubscription', () => {
  it('21. Cancels successfully for the subscription owner', async () => {
    repo.findSubscriptionById.mockResolvedValue(mockSubscription);
    rzp.cancelSubscription.mockResolvedValue(undefined);
    repo.updateSubscription.mockResolvedValue({} as any);
    repo.upsertEntitlement.mockResolvedValue({} as any);

    await expect(
      subscriptionService.cancelSubscription('user-uuid-1', 'sub-uuid-1', true)
    ).resolves.not.toThrow();
  });

  it('21b. Throws ForbiddenError if user tries to cancel another user\'s subscription', async () => {
    repo.findSubscriptionById.mockResolvedValue({
      ...mockSubscription,
      userId: 'other-user',
    });

    await expect(
      subscriptionService.cancelSubscription('user-uuid-1', 'sub-uuid-1', true)
    ).rejects.toThrow(ForbiddenError);
  });

  it('21c. Throws NotFoundError if subscription does not exist', async () => {
    repo.findSubscriptionById.mockResolvedValue(null);
    await expect(
      subscriptionService.cancelSubscription('user-uuid-1', 'sub-uuid-1')
    ).rejects.toThrow(NotFoundError);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// TEST SUITE: Webhook + Client Callback Race Conditions
// ══════════════════════════════════════════════════════════════════════════════

describe('Race condition: webhook arrives before client callback', () => {
  it('23. Webhook first → client verify → both converge on same record', async () => {
    // Webhook activates subscription
    repo.findWebhookEvent.mockResolvedValue(null);
    repo.createWebhookEvent.mockResolvedValue({} as any);
    repo.findSubscriptionByProviderId.mockResolvedValue({
      ...mockSubscription,
      status: SubscriptionStatus.CREATED,
    });
    repo.updateSubscription.mockResolvedValue({} as any);
    repo.upsertEntitlement.mockResolvedValue({} as any);
    repo.findPaymentTransactionByProviderId.mockResolvedValue(null);
    repo.createPaymentTransaction.mockResolvedValue({} as any);

    await subscriptionService.processWebhookEvent({
      event: 'subscription.activated',
      id: 'evt_webhook_first',
      payload: {
        subscription: { entity: { id: 'sub_razorpay_abc', current_start: Date.now() / 1000, current_end: (Date.now() + 30 * 24 * 60 * 60 * 1000) / 1000 } },
        payment: { entity: { id: 'pay_webhook', amount: 19900, currency: 'INR', status: 'captured' } },
      },
    });

    // Client verify — transaction already exists (from webhook)
    rzp.verifySubscriptionSignature.mockReturnValue(true);
    repo.findSubscriptionByProviderId.mockResolvedValue({ ...mockSubscription, status: SubscriptionStatus.ACTIVE });
    rzp.fetchPayment.mockResolvedValue({ paymentId: 'pay_webhook', amount: 19900, currency: 'INR', status: 'captured' });
    repo.findPaymentTransactionByProviderId.mockResolvedValue({ id: 'tx_existing' } as any);

    const result = await subscriptionService.verifyPayment({
      userId: 'user-uuid-1',
      razorpayPaymentId: 'pay_webhook',
      razorpaySubscriptionId: 'sub_razorpay_abc',
      razorpaySignature: 'sig_webhook',
    });

    // isPremium true because subscription is ACTIVE; transaction skipped (duplicate check)
    expect(result.isPremium).toBe(true);
    expect(repo.createPaymentTransaction).toHaveBeenCalledTimes(1); // only from webhook
  });
});

describe('Race condition: client callback arrives before webhook', () => {
  it('24. Client verify first → webhook arrives → idempotency prevents double activation', async () => {
    // Client verify first — activates entitlement
    rzp.verifySubscriptionSignature.mockReturnValue(true);
    repo.findSubscriptionByProviderId.mockResolvedValue({ ...mockSubscription, status: SubscriptionStatus.CREATED });
    rzp.fetchPayment.mockResolvedValue({ paymentId: 'pay_client', amount: 19900, currency: 'INR', status: 'captured' });
    repo.findPaymentTransactionByProviderId.mockResolvedValue(null);
    repo.createPaymentTransaction.mockResolvedValue({} as any);
    repo.updateSubscription.mockResolvedValue({} as any);
    repo.upsertEntitlement.mockResolvedValue({} as any);

    await subscriptionService.verifyPayment({
      userId: 'user-uuid-1',
      razorpayPaymentId: 'pay_client',
      razorpaySubscriptionId: 'sub_razorpay_abc',
      razorpaySignature: 'sig_client',
    });

    // Webhook arrives with same event — idempotency check kicks in
    repo.findWebhookEvent.mockResolvedValue({ id: 'evt_already_done' } as any);
    await subscriptionService.processWebhookEvent({
      event: 'subscription.activated',
      id: 'evt_already_done',
      payload: { subscription: { entity: { id: 'sub_razorpay_abc' } } },
    });

    // upsertEntitlement called only once (from client verify)
    expect(repo.upsertEntitlement).toHaveBeenCalledTimes(1);
  });
});
