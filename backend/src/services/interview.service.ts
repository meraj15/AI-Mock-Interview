import {
  interviewRepository,
  CreateInterviewSessionInput,
  InterviewStats,
  InterviewSession,
} from '../repositories/interview.repository';
import { logger } from '../utils/logger';

export class InterviewService {
  /** Save a completed interview and return the persisted record. */
  async saveSession(
    userId: string,
    data: Omit<CreateInterviewSessionInput, 'userId'>
  ): Promise<InterviewSession> {
    const session = await interviewRepository.create({ ...data, userId });
    logger.info(
      `Interview saved — user=${userId} score=${data.score} band=${data.hiringBand}`
    );
    return session;
  }

  /** List sessions for a user (paginated). */
  async listSessions(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<InterviewSession[]> {
    return interviewRepository.findByUserId(userId, limit, offset);
  }

  /** Get a single session, verifying ownership. */
  async getSession(
    sessionId: string,
    userId: string
  ): Promise<InterviewSession> {
    const session = await interviewRepository.findById(sessionId);
    if (!session) {
      throw Object.assign(new Error('Interview session not found'), {
        statusCode: 404,
      });
    }
    if (session.userId !== userId) {
      throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    }
    return session;
  }

  /** Aggregated performance stats for the home screen cards. */
  async getStats(userId: string): Promise<InterviewStats> {
    return interviewRepository.getStats(userId);
  }
}

export const interviewService = new InterviewService();
