import { prisma } from '../../config/database';
import { NotFoundError } from '../../errors/AppError';
import { telemetryService } from '../telemetry.service';

export class AdminPlansService {
  async listPlans() {
    const plans = await prisma.plan.findMany({
      orderBy: { priceInPaise: 'asc' },
      include: {
        _count: {
          select: { subscriptions: true },
        },
      },
    });

    return plans.map((p: any) => ({
      id: p.id,
      name: p.name,
      code: p.code,
      description: p.description,
      priceRupees: Math.round(p.priceInPaise / 100),
      priceInPaise: p.priceInPaise,
      currency: p.currency,
      tier: p.tier,
      billingInterval: p.billingInterval,
      razorpayPlanId: p.razorpayPlanId,
      isActive: p.isActive,
      subscriberCount: p._count.subscriptions,
      createdAt: p.createdAt.toISOString(),
      updatedAt: p.updatedAt.toISOString(),
    }));
  }

  async updatePlan(
    adminId: string,
    planId: string,
    data: { description?: string; isActive?: boolean },
    ipAddress?: string
  ) {
    const plan = await prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) {
      throw new NotFoundError(`Plan ${planId} not found`);
    }

    const previousValue = {
      description: plan.description,
      isActive: plan.isActive,
    };

    const updateData: any = {};
    if (data.description !== undefined) updateData.description = data.description;
    if (data.isActive !== undefined) updateData.isActive = data.isActive;

    const updated = await prisma.plan.update({
      where: { id: planId },
      data: updateData,
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'PLAN_UPDATE',
      targetType: 'PLAN',
      targetId: planId,
      previousValue,
      newValue: updateData,
      reason: `Plan ${plan.name} configuration updated`,
      ipAddress,
    });

    return {
      success: true,
      message: `Plan ${plan.name} updated successfully`,
      plan: updated,
    };
  }
}

export const adminPlansService = new AdminPlansService();
