import { prisma } from '../config/database';
import { InterviewSession } from '@prisma/client';

// ── Input / output types ──────────────────────────────────────────────────────

export interface CreateInterviewSessionInput {
  userId: string;
  role: string;
  type: string;
  difficulty: string;
  questionCount: number;
  score: number;          // 0–100
  hiringBand: string;
  summary: string;
  strengths: string[];
  areasToImprove: string[];
  durationSecs: number;
}

export interface InterviewStats {
  averageScore: number;    // SUM(scores) / COUNT — rounded
  totalInterviews: number; // COUNT(all completed)
  thisWeekCount: number;   // COUNT since Monday 00:00 UTC
  bestScore: number;       // MAX(scores)
  currentStreak: number;   // consecutive days with ≥1 interview
  monthlyChange: number;   // currentMonthAvg - prevMonthAvg, rounded
}

// Re-export for consumers
export type { InterviewSession };

// ── Repository ────────────────────────────────────────────────────────────────

export class InterviewRepository {
  /** Persist a completed interview session. */
  async create(data: CreateInterviewSessionInput): Promise<InterviewSession> {
    return prisma.interviewSession.create({ data });
  }

  /** List all sessions for a user, newest first. */
  async findByUserId(
    userId: string,
    limit = 20,
    offset = 0,
  ): Promise<InterviewSession[]> {
    return prisma.interviewSession.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /** Single session (ownership checked in the service layer). */
  async findById(id: string): Promise<InterviewSession | null> {
    return prisma.interviewSession.findUnique({ where: { id } });
  }

  /**
   * Compute all home-screen performance stats for a user.
   * Runs in ~4 parallel DB queries.
   */
  
  async getStats(userId: string): Promise<InterviewStats> {
    // ── 1. Aggregate: avg / count / max ──────────────────────────────────
    const agg = await prisma.interviewSession.aggregate({
      where: { userId },
      _count: { id: true },
      _avg:   { score: true },
      _max:   { score: true },
    });

    const totalInterviews = agg._count.id;
    const averageScore    = Math.round(agg._avg.score ?? 0);
    const bestScore       = agg._max.score ?? 0;

    // ── 2. This week: Monday 00:00 UTC → now ─────────────────────────────
    const now       = new Date();
    const dayOfWeek = now.getUTCDay();           // 0 = Sunday
    const diffToMon = (dayOfWeek + 6) % 7;       // days since last Monday
    const monday    = new Date(now);
    monday.setUTCDate(now.getUTCDate() - diffToMon);
    monday.setUTCHours(0, 0, 0, 0);

    const thisWeekCount = await prisma.interviewSession.count({
      where: { userId, createdAt: { gte: monday } },
    });

    // ── 3. Monthly change ─────────────────────────────────────────────────
    const startOfThisMonth = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
    );
    const startOfPrevMonth = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1),
    );

    const [thisMonthAgg, prevMonthAgg] = await Promise.all([
      prisma.interviewSession.aggregate({
        where: { userId, createdAt: { gte: startOfThisMonth } },
        _avg: { score: true },
      }),
      prisma.interviewSession.aggregate({
        where: {
          userId,
          createdAt: { gte: startOfPrevMonth, lt: startOfThisMonth },
        },
        _avg: { score: true },
      }),
    ]);

    const monthlyChange = Math.round(
      (thisMonthAgg._avg.score ?? 0) - (prevMonthAgg._avg.score ?? 0),
    );

    // ── 4. Streak ─────────────────────────────────────────────────────────
    const currentStreak = await this._calculateStreak(userId);

    return {
      averageScore,
      totalInterviews,
      thisWeekCount,
      bestScore,
      currentStreak,
      monthlyChange,
    };
  }

  /**
   * Count consecutive calendar days (ending today) where the user
   * completed ≥1 interview.
   */
  private async _calculateStreak(userId: string): Promise<number> {
    const sessions = await prisma.interviewSession.findMany({
      where: { userId },
      select: { createdAt: true },
      orderBy: { createdAt: 'desc' },
    });

    if (sessions.length === 0) return 0;

    // Unique UTC date strings "YYYY-MM-DD", newest first
    const uniqueDays = [
      ...new Set(sessions.map((s) => s.createdAt.toISOString().slice(0, 10))),
    ].sort((a, b) => (a > b ? -1 : 1));

    const todayStr     = new Date().toISOString().slice(0, 10);
    const yesterday    = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const yesterdayStr = yesterday.toISOString().slice(0, 10);

    // Streak must include today or yesterday (timezone grace)
    if (uniqueDays[0] !== todayStr && uniqueDays[0] !== yesterdayStr) return 0;

    let streak = 1;
    for (let i = 1; i < uniqueDays.length; i++) {
      const prev = new Date(uniqueDays[i - 1]!);
      const curr = new Date(uniqueDays[i]!);
      const diffDays =
        (prev.getTime() - curr.getTime()) / (1000 * 60 * 60 * 24);
      if (diffDays === 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}

export const interviewRepository = new InterviewRepository();
