import { prisma } from '../../config/database';

export interface AuditLogListParams {
  page?: number;
  limit?: number;
  adminId?: string;
  action?: string;
  targetType?: string;
  startDate?: string;
  endDate?: string;
}

export class AdminAuditService {
  async listAuditLogs(params: AuditLogListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.adminId) where.adminId = params.adminId;
    if (params.action && params.action !== 'ALL') where.action = params.action;
    if (params.targetType && params.targetType !== 'ALL') where.targetType = params.targetType;

    if (params.startDate || params.endDate) {
      where.createdAt = {};
      if (params.startDate) where.createdAt.gte = new Date(params.startDate);
      if (params.endDate) where.createdAt.lte = new Date(params.endDate);
    }

    const [total, logs] = await Promise.all([
      prisma.auditLog.count({ where }),
      prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    // Fetch admin emails for readable UI
    const adminIds = Array.from(new Set(logs.map((l: any) => l.adminId)));
    const admins = await prisma.user.findMany({
      where: { id: { in: adminIds } },
      select: { id: true, email: true },
    });
    const adminEmailMap = new Map(admins.map((a: any) => [a.id, a.email]));

    return {
      logs: logs.map((l: any) => ({
        id: l.id,
        adminId: l.adminId,
        adminEmail: adminEmailMap.get(l.adminId) || 'System / Admin',
        action: l.action,
        targetType: l.targetType,
        targetId: l.targetId,
        previousValue: l.previousValue,
        newValue: l.newValue,
        reason: l.reason,
        ipAddress: l.ipAddress,
        createdAt: l.createdAt.toISOString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}

export const adminAuditService = new AdminAuditService();
