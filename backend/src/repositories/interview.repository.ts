import { prisma } from '../config/database';
import { InterviewSession } from '@prisma/client';

// ── Input / output types ──────────────────────────────────────────────────────

export interface CreateInterviewSessionInput {
  userId: string;
  role: string;
  type?: string;

  questionCount: number;

  score: number; // 0–100
  hiringBand: string;
  summary: string;

  strengths: string[];
  areasToImprove: string[];

  // Example:
  // {
  //   "Dart Fundamentals": 88,
  //   "Flutter Architecture": 82,
  //   "State Management": 91
  // }
  skillScores: Record<string, number>;

  durationSecs: number;
}

export interface InterviewStats {
  averageScore: number;
  totalInterviews: number;
  thisWeekCount: number;
  bestScore: number;
  currentStreak: number;
  monthlyChange: number;

  // ── Analytics extras ─────────────────────────────────────────────────────
  scoreHistory: number[];
  skillAverages: Record<string, number>;
  completionRate: number;
  overallChange: number;
}

// Re-export for consumers
export type { InterviewSession };

// ── Repository ────────────────────────────────────────────────────────────────

export class InterviewRepository {
  /**
   * Persist a completed interview session.
   *
   * Difficulty is intentionally NOT part of the application-level input.
   *
   * The existing Prisma schema may still have a required `difficulty`
   * column, so we temporarily save "Adaptive" internally for backward
   * compatibility.
   *
   * Once the Prisma difficulty column is removed, this field can also
   * be removed from here.
   */
  async create(
    data: CreateInterviewSessionInput,
  ): Promise<InterviewSession> {
    return prisma.interviewSession.create({
      data: {
        ...data,

        type: data.type ?? 'technical',

        // Backward compatibility with the existing Prisma schema.
        // Difficulty is NOT user-controlled.
        difficulty: 'Adaptive',
      },
    });
  }

  /**
   * List all sessions for a user, newest first.
   */
  async findByUserId(
    userId: string,
    limit = 20,
    offset = 0,
  ): Promise<InterviewSession[]> {
    return prisma.interviewSession.findMany({
      where: {
        userId,
      },

      orderBy: {
        createdAt: 'desc',
      },

      take: limit,
      skip: offset,
    });
  }

  /**
   * Get a single interview session.
   *
   * Ownership is checked in the service layer.
   */
  async findById(
    id: string,
  ): Promise<InterviewSession | null> {
    return prisma.interviewSession.findUnique({
      where: {
        id,
      },
    });
  }

  /**
   * Compute all home-screen performance statistics for a user.
   */
  async getStats(
    userId: string,
  ): Promise<InterviewStats> {
    // ────────────────────────────────────────────────────────────────────────
    // 1. Aggregate: average / count / max
    // ────────────────────────────────────────────────────────────────────────

    const agg =
      await prisma.interviewSession.aggregate({
        where: {
          userId,
        },

        _count: {
          id: true,
        },

        _avg: {
          score: true,
        },

        _max: {
          score: true,
        },
      });

    const totalInterviews =
      agg._count.id;

    const averageScore =
      Math.round(
        agg._avg.score ?? 0,
      );

    const bestScore =
      agg._max.score ?? 0;

    // ────────────────────────────────────────────────────────────────────────
    // 2. This week
    //
    // Monday 00:00 UTC → now
    // ────────────────────────────────────────────────────────────────────────

    const now = new Date();

    const dayOfWeek =
      now.getUTCDay();

    // 0 = Sunday
    // 1 = Monday
    // ...
    // 6 = Saturday

    const diffToMonday =
      (dayOfWeek + 6) % 7;

    const monday =
      new Date(now);

    monday.setUTCDate(
      now.getUTCDate() -
        diffToMonday,
    );

    monday.setUTCHours(
      0,
      0,
      0,
      0,
    );

    const thisWeekCount =
      await prisma.interviewSession.count(
        {
          where: {
            userId,

            createdAt: {
              gte: monday,
            },
          },
        },
      );

    // ────────────────────────────────────────────────────────────────────────
    // 3. Monthly change
    // ────────────────────────────────────────────────────────────────────────

    const startOfThisMonth =
      new Date(
        Date.UTC(
          now.getUTCFullYear(),
          now.getUTCMonth(),
          1,
        ),
      );

    const startOfPreviousMonth =
      new Date(
        Date.UTC(
          now.getUTCFullYear(),
          now.getUTCMonth() - 1,
          1,
        ),
      );

    const [
      thisMonthAgg,
      previousMonthAgg,
    ] = await Promise.all([
      prisma.interviewSession.aggregate(
        {
          where: {
            userId,

            createdAt: {
              gte: startOfThisMonth,
            },
          },

          _avg: {
            score: true,
          },
        },
      ),

      prisma.interviewSession.aggregate(
        {
          where: {
            userId,

            createdAt: {
              gte: startOfPreviousMonth,
              lt: startOfThisMonth,
            },
          },

          _avg: {
            score: true,
          },
        },
      ),
    ]);

    const monthlyChange =
      Math.round(
        (thisMonthAgg._avg.score ?? 0) -
          (previousMonthAgg._avg.score ?? 0),
      );

    // ────────────────────────────────────────────────────────────────────────
    // 4. Current streak
    // ────────────────────────────────────────────────────────────────────────

    const currentStreak =
      await this._calculateStreak(
        userId,
      );

    // ────────────────────────────────────────────────────────────────────────
    // 5. Score history
    //
    // Last 10 sessions.
    // Returned oldest → newest for charts.
    // ────────────────────────────────────────────────────────────────────────

    const lastTen =
      await prisma.interviewSession.findMany(
        {
          where: {
            userId,
          },

          select: {
            score: true,
          },

          orderBy: {
            createdAt: 'desc',
          },

          take: 10,
        },
      );

    const scoreHistory =
      lastTen
        .map(
          (session) =>
            session.score,
        )
        .reverse();

    // ────────────────────────────────────────────────────────────────────────
    // 6. Skill averages
    //
    // These are based on the skill/competency scores generated by the AI
    // during evaluation, not necessarily the user's selected skills.
    // ────────────────────────────────────────────────────────────────────────

    const allSessions =
      await prisma.interviewSession.findMany(
        {
          where: {
            userId,
          },

          select: {
            skillScores: true,
          },
        },
      );

    const skillTotals: Record<
      string,
      {
        sum: number;
        count: number;
      }
    > = {};

    for (const session of allSessions) {
      const scores =
        session.skillScores as Record<
          string,
          number
        >;

      if (
        scores &&
        typeof scores === 'object' &&
        !Array.isArray(scores)
      ) {
        for (const [
          key,
          value,
        ] of Object.entries(scores)) {
          if (
            typeof value !==
            'number'
          ) {
            continue;
          }

          if (
            !skillTotals[key]
          ) {
            skillTotals[key] = {
              sum: 0,
              count: 0,
            };
          }

          skillTotals[key]!.sum +=
            value;

          skillTotals[key]!.count +=
            1;
        }
      }
    }

    const skillAverages: Record<
      string,
      number
    > = {};

    for (const [
      key,
      value,
    ] of Object.entries(
      skillTotals,
    )) {
      if (value.count === 0) {
        continue;
      }

      skillAverages[key] =
        Math.round(
          value.sum /
            value.count,
        );
    }

    // ────────────────────────────────────────────────────────────────────────
    // 7. Completion rate
    //
    // Currently uses duration > 30 seconds as the completion proxy.
    // ────────────────────────────────────────────────────────────────────────

    const completedCount =
      await prisma.interviewSession.count(
        {
          where: {
            userId,

            durationSecs: {
              gt: 30,
            },
          },
        },
      );

    const completionRate =
      totalInterviews > 0
        ? Math.round(
            (completedCount /
              totalInterviews) *
              100,
          )
        : 0;

    // ────────────────────────────────────────────────────────────────────────
    // 8. Overall change
    //
    // Compares the average score of the first half of interviews
    // against the second half.
    // ────────────────────────────────────────────────────────────────────────

    let overallChange = 0;

    if (totalInterviews >= 2) {
      const all =
        await prisma.interviewSession.findMany(
          {
            where: {
              userId,
            },

            select: {
              score: true,
            },

            orderBy: {
              createdAt: 'asc',
            },
          },
        );

      const midpoint =
        Math.floor(
          all.length / 2,
        );

      const firstHalf =
        all
          .slice(
            0,
            midpoint,
          )
          .map(
            (session) =>
              session.score,
          );

      const secondHalf =
        all
          .slice(midpoint)
          .map(
            (session) =>
              session.score,
          );

      const calculateAverage =
        (
          values: number[],
        ): number => {
          if (
            values.length === 0
          ) {
            return 0;
          }

          return (
            values.reduce(
              (
                total,
                value,
              ) =>
                total + value,
              0,
            ) /
            values.length
          );
        };

      overallChange =
        Math.round(
          calculateAverage(
            secondHalf,
          ) -
            calculateAverage(
              firstHalf,
            ),
        );
    }

    // ────────────────────────────────────────────────────────────────────────
    // Return stats
    // ────────────────────────────────────────────────────────────────────────

    return {
      averageScore,
      totalInterviews,
      thisWeekCount,
      bestScore,
      currentStreak,
      monthlyChange,
      scoreHistory,
      skillAverages,
      completionRate,
      overallChange,
    };
  }

  /**
   * Calculate consecutive calendar days ending today/yesterday
   * where the user completed at least one interview.
   *
   * Uses UTC dates to stay consistent with the rest of the statistics.
   */
  private async _calculateStreak(
    userId: string,
  ): Promise<number> {
    const sessions =
      await prisma.interviewSession.findMany(
        {
          where: {
            userId,
          },

          select: {
            createdAt: true,
          },

          orderBy: {
            createdAt: 'desc',
          },
        },
      );

    if (
      sessions.length === 0
    ) {
      return 0;
    }

    // Convert timestamps into unique UTC dates.
    const uniqueDays = [
      ...new Set(
        sessions.map(
          (session) =>
            session.createdAt
              .toISOString()
              .slice(0, 10),
        ),
      ),
    ].sort(
      (a, b) =>
        a > b ? -1 : 1,
    );

    const today =
      new Date();

    const todayStr =
      today
        .toISOString()
        .slice(0, 10);

    const yesterday =
      new Date();

    yesterday.setUTCDate(
      yesterday.getUTCDate() - 1,
    );

    const yesterdayStr =
      yesterday
        .toISOString()
        .slice(0, 10);

    // The streak can start today or yesterday.
    if (
      uniqueDays[0] !==
        todayStr &&
      uniqueDays[0] !==
        yesterdayStr
    ) {
      return 0;
    }

    let streak = 1;

    for (
      let i = 1;
      i < uniqueDays.length;
      i++
    ) {
      const previous =
        new Date(
          uniqueDays[i - 1]!,
        );

      const current =
        new Date(
          uniqueDays[i]!,
        );

      const diffDays =
        (
          previous.getTime() -
          current.getTime()
        ) /
        (1000 * 60 * 60 * 24);

      if (
        diffDays === 1
      ) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Singleton
// ─────────────────────────────────────────────────────────────────────────────

export const interviewRepository =
  new InterviewRepository();