import { prisma } from '../../config/database';
import { NotFoundError } from '../../errors/AppError';
import { convertToCsv } from './admin.helper';

export interface InterviewListParams {
  page?: number;
  limit?: number;
  search?: string;
  role?: string;
  difficulty?: string;
  type?: string;
  scoreMin?: number;
  scoreMax?: number;
  startDate?: string;
  endDate?: string;
}

export class AdminInterviewsService {
  async listInterviews(params: InterviewListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.search && params.search.trim().length > 0) {
      const q = params.search.trim();
      where.OR = [
        { id: { equals: q } },
        { role: { contains: q, mode: 'insensitive' } },
        { user: { email: { contains: q, mode: 'insensitive' } } },
      ];
    }

    if (params.role) {
      where.role = { contains: params.role, mode: 'insensitive' };
    }
    if (params.difficulty) {
      where.difficulty = { equals: params.difficulty, mode: 'insensitive' };
    }
    if (params.type) {
      where.type = { equals: params.type, mode: 'insensitive' };
    }

    if (params.scoreMin !== undefined || params.scoreMax !== undefined) {
      where.score = {};
      if (params.scoreMin !== undefined) where.score.gte = Number(params.scoreMin);
      if (params.scoreMax !== undefined) where.score.lte = Number(params.scoreMax);
    }

    if (params.startDate || params.endDate) {
      where.createdAt = {};
      if (params.startDate) where.createdAt.gte = new Date(params.startDate);
      if (params.endDate) where.createdAt.lte = new Date(params.endDate);
    }

    const [total, sessions] = await Promise.all([
      prisma.interviewSession.count({ where }),
      prisma.interviewSession.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, email: true, profile: { select: { fullName: true } } },
          },
          _count: { select: { questions: true } },
        },
      }),
    ]);

    return {
      interviews: sessions.map((s: any) => ({
        id: s.id,
        userId: s.userId,
        userName: s.user.profile?.fullName || 'Anonymous',
        userEmail: s.user.email,
        role: s.role,
        type: s.type,
        difficulty: s.difficulty,
        questionCount: s.questionCount,
        questionsAnswered: s._count.questions,
        score: s.score,
        hiringBand: s.hiringBand,
        durationSecs: s.durationSecs,
        createdAt: s.createdAt.toISOString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getInterviewDetail(sessionId: string) {
    const session = await prisma.interviewSession.findUnique({
      where: { id: sessionId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            profile: { select: { fullName: true, targetRole: true } },
          },
        },
        questions: {
          orderBy: { questionNumber: 'asc' },
        },
      },
    });

    if (!session) {
      throw new NotFoundError(`Interview session ${sessionId} not found`);
    }

    // Retrieve AI telemetry recorded for this session
    const aiTelemetry = await prisma.aiTelemetryLog.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });

    return {
      session: {
        id: session.id,
        userId: session.userId,
        userEmail: session.user.email,
        userName: session.user.profile?.fullName || 'Anonymous',
        role: session.role,
        type: session.type,
        difficulty: session.difficulty,
        questionCount: session.questionCount,
        score: session.score,
        hiringBand: session.hiringBand,
        summary: session.summary,
        strengths: session.strengths,
        areasToImprove: session.areasToImprove,
        skillScores: session.skillScores,
        durationSecs: session.durationSecs,
        createdAt: session.createdAt.toISOString(),
      },
      questions: session.questions.map((q: any) => ({
        id: q.id,
        questionNumber: q.questionNumber,
        question: q.question,
        candidateAnswer: q.candidateAnswer,
        expectedAnswer: q.expectedAnswer,
        feedback: q.feedback,
        score: q.score,
        topic: q.topic,
        type: q.type,
      })),
      aiTelemetry: aiTelemetry.map((t: any) => ({
        id: t.id,
        operation: t.operation,
        provider: t.provider,
        model: t.model,
        latencyMs: t.latencyMs,
        aiLatencyMs: t.aiLatencyMs,
        promptBuildMs: t.promptBuildMs,
        parseMs: t.parseMs,
        inputTokens: t.inputTokens,
        outputTokens: t.outputTokens,
        totalTokens: t.totalTokens,
        attemptCount: t.attemptCount,
        retryCount: t.retryCount,
        status: t.status,
        degraded: t.degraded,
        createdAt: t.createdAt.toISOString(),
      })),
    };
  }

  async exportInterviewsCsv(params: InterviewListParams): Promise<string> {
    const result = await this.listInterviews({ ...params, limit: 1000 });
    const rows = result.interviews.map((i: any) => ({
      ID: i.id,
      User: i.userEmail,
      Role: i.role,
      Type: i.type,
      Difficulty: i.difficulty,
      Questions: i.questionsAnswered,
      Score: i.score,
      'Hiring Band': i.hiringBand,
      'Duration (s)': i.durationSecs,
      'Created At': i.createdAt,
    }));

    return convertToCsv(rows);
  }
}

export const adminInterviewsService = new AdminInterviewsService();
