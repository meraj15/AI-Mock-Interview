import { prisma } from '../../config/database';
import { convertToCsv } from './admin.helper';

export interface PaymentListParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  startDate?: string;
  endDate?: string;
}

export class AdminPaymentsService {
  async listPayments(params: PaymentListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.search && params.search.trim().length > 0) {
      const q = params.search.trim();
      where.OR = [
        { providerPaymentId: { contains: q, mode: 'insensitive' } },
        { providerOrderId: { contains: q, mode: 'insensitive' } },
        { user: { email: { contains: q, mode: 'insensitive' } } },
      ];
    }

    if (params.status && params.status !== 'ALL') {
      where.status = params.status;
    }

    if (params.startDate || params.endDate) {
      where.createdAt = {};
      if (params.startDate) where.createdAt.gte = new Date(params.startDate);
      if (params.endDate) where.createdAt.lte = new Date(params.endDate);
    }

    const [total, transactions] = await Promise.all([
      prisma.paymentTransaction.count({ where }),
      prisma.paymentTransaction.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, email: true, profile: { select: { fullName: true } } },
          },
          subscription: {
            include: { plan: { select: { name: true, billingInterval: true } } },
          },
        },
      }),
    ]);

    return {
      payments: transactions.map((t: any) => ({
        id: t.id,
        userId: t.userId,
        userName: t.user.profile?.fullName || 'Anonymous',
        userEmail: t.user.email,
        planName: t.subscription?.plan?.name || 'Pro Plan',
        billingInterval: t.subscription?.plan?.billingInterval || 'MONTHLY',
        amountRupees: Math.round(t.amount / 100),
        currency: t.currency,
        status: t.status,
        provider: t.provider,
        providerPaymentId: t.providerPaymentId,
        providerOrderId: t.providerOrderId,
        paidAt: t.paidAt ? t.paidAt.toISOString() : null,
        createdAt: t.createdAt.toISOString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getPaymentStats() {
    const [capturedSum, refundedSum, countsByStatus] = await Promise.all([
      prisma.paymentTransaction.aggregate({
        where: { status: 'CAPTURED' },
        _sum: { amount: true },
        _count: { id: true },
      }),
      prisma.paymentTransaction.aggregate({
        where: { status: 'REFUNDED' },
        _sum: { amount: true },
        _count: { id: true },
      }),
      prisma.paymentTransaction.groupBy({
        by: ['status'],
        _count: { id: true },
      }),
    ]);

    const statusMap = new Map<string, number>(countsByStatus.map((c: any) => [c.status, c._count.id]));
    const capturedCount: number = statusMap.get('CAPTURED') ?? 0;
    const failedCount: number = statusMap.get('FAILED') ?? 0;
    const refundedCount: number = statusMap.get('REFUNDED') ?? 0;
    const pendingCount: number = statusMap.get('PENDING') ?? 0;
    const totalTransactions: number = capturedCount + failedCount + refundedCount + pendingCount;

    const grossRevenueRupees = Math.round((capturedSum._sum.amount ?? 0) / 100);
    const refundRupees = Math.round((refundedSum._sum.amount ?? 0) / 100);
    const netRevenueRupees = grossRevenueRupees - refundRupees;

    const successRatePercent =
      totalTransactions > 0
        ? Math.round((capturedCount / (capturedCount + failedCount)) * 1000) / 10
        : 100;

    return {
      grossRevenueRupees,
      refundRupees,
      netRevenueRupees,
      capturedCount,
      failedCount,
      refundedCount,
      pendingCount,
      totalTransactions,
      successRatePercent,
    };
  }

  async listWebhooks(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, events] = await Promise.all([
      prisma.webhookEvent.count(),
      prisma.webhookEvent.findMany({
        skip,
        take: limit,
        orderBy: { processedAt: 'desc' },
      }),
    ]);

    return {
      events: events.map((e: any) => ({
        id: e.id,
        eventId: e.eventId,
        eventType: e.eventType,
        provider: e.provider,
        payloadSummary: typeof e.payload === 'object' ? Object.keys(e.payload as any) : [],
        processedAt: e.processedAt.toISOString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async exportPaymentsCsv(params: PaymentListParams): Promise<string> {
    const result = await this.listPayments({ ...params, limit: 1000 });
    const rows = result.payments.map((p: any) => ({
      ID: p.id,
      User: p.userEmail,
      Plan: p.planName,
      Amount: p.amountRupees,
      Currency: p.currency,
      Status: p.status,
      'Razorpay Payment ID': p.providerPaymentId ?? 'N/A',
      'Paid At': p.paidAt ?? 'N/A',
      'Created At': p.createdAt,
    }));

    return convertToCsv(rows);
  }
}

export const adminPaymentsService = new AdminPaymentsService();
