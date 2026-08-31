import { randomUUID } from 'crypto';
import {
  interviewRepository,
  CreateInterviewSessionInput,
  InterviewStats,
  InterviewSession,
} from '../repositories/interview.repository';
import {
  aiService,
  InterviewTopic,
  TranscriptEntry,
  FinalInterviewEvaluation,
} from './ai.service';
import { logger } from '../utils/logger';

export interface ActiveConversationalSession {
  id: string;
  userId: string;
  role: string;
  difficulty: string;
  skills: string[];
  experience?: string;
  topics: InterviewTopic[];
  currentTopicIndex: number;
  topicsCovered: string[];
  followUpsUsedForCurrentTopic: number;
  totalTurns: number;
  maxTurns: number;
  conversationSummary: string;
  interactions: TranscriptEntry[];
  status: 'in_progress' | 'completed';
  finalEvaluation?: FinalInterviewEvaluation;
  createdAt: Date;
  startedAt: number; // timestamp in ms for duration calculation
}

export class InterviewService {
  // In-memory active conversational sessions map (sessionId -> ActiveConversationalSession)
  private activeSessions = new Map<string, ActiveConversationalSession>();

  /**
   * STAGE 1: Start a new conversational interview session.
   * Generates the blueprint and first natural question via Gemini.
   */
  async startConversationalInterview(
    userId: string,
    params: {
      role: string;
      skills?: string[];
      difficulty?: string;
      experience?: string;
      questionCount?: number;
    }
  ): Promise<{
    sessionId: string;
    role: string;
    topics: InterviewTopic[];
    currentTopic: string;
    currentTopicIndex: number;
    totalTopics: number;
    firstQuestion: string;
  }> {
    const { role, skills = [], difficulty = 'Medium', experience, questionCount = 5 } = params;

    const plan = await aiService.generateInterviewPlan({
      role,
      skills,
      difficulty,
      experience,
      questionCount,
    });

    const sessionId = randomUUID();
    const session: ActiveConversationalSession = {
      id: sessionId,
      userId,
      role,
      difficulty,
      skills,
      experience,
      topics: plan.topics,
      currentTopicIndex: 0,
      topicsCovered: [],
      followUpsUsedForCurrentTopic: 0,
      totalTurns: 1,
      maxTurns: Math.min(12, Math.max(6, plan.topics.length * 2)),
      conversationSummary: '',
      interactions: [
        {
          question: plan.firstQuestion,
          answer: '',
          topic: plan.topics[0]?.name || 'Introduction',
          type: 'primary',
          timestamp: new Date().toISOString(),
        },
      ],
      status: 'in_progress',
      createdAt: new Date(),
      startedAt: Date.now(),
    };

    this.activeSessions.set(sessionId, session);

    logger.info(`[InterviewService] Started conversational interview ${sessionId} for user=${userId} role="${role}"`);

    return {
      sessionId,
      role,
      topics: session.topics,
      currentTopic: session.topics[0]?.name || 'Introduction',
      currentTopicIndex: 0,
      totalTopics: session.topics.length,
      firstQuestion: plan.firstQuestion,
    };
  }

  /**
   * STAGE 2: Receive candidate's answer and produce the next conversational turn.
   */
  async submitAnswer(
    sessionId: string,
    userId: string,
    answer: string
  ): Promise<{
    acknowledgement: string;
    action: 'follow_up' | 'new_topic' | 'end_interview';
    nextQuestion: string;
    nextTopic: string;
    currentTopicIndex: number;
    totalTopics: number;
    isComplete: boolean;
  }> {
    const session = this.activeSessions.get(sessionId);

    if (!session) {
      throw Object.assign(new Error('Active interview session not found or expired'), { statusCode: 404 });
    }

    if (session.userId !== userId) {
      throw Object.assign(new Error('Forbidden: session does not belong to user'), { statusCode: 403 });
    }

    if (session.status === 'completed') {
      return {
        acknowledgement: '',
        action: 'end_interview',
        nextQuestion: 'The interview is already completed.',
        nextTopic: 'Completed',
        currentTopicIndex: session.currentTopicIndex,
        totalTopics: session.topics.length,
        isComplete: true,
      };
    }

    // Save candidate's answer to the last interaction
    const lastInteraction = session.interactions[session.interactions.length - 1];
    if (lastInteraction) {
      lastInteraction.answer = answer.trim();
    }

    const currentTopicObj = session.topics[session.currentTopicIndex] || {
      name: 'General',
      objective: 'Evaluate technical competence',
    };

    const topicsRemaining = session.topics
      .slice(session.currentTopicIndex + 1)
      .map((t) => t.name);

    // Check if max turns reached or no remaining topics
    const isAtMaxTurns = session.totalTurns >= session.maxTurns;
    const isAtLastTopicAndUsedFollowUp =
      session.currentTopicIndex >= session.topics.length - 1 &&
      session.followUpsUsedForCurrentTopic >= 1;

    if (isAtMaxTurns || isAtLastTopicAndUsedFollowUp) {
      session.status = 'completed';
      const wrapUpMsg =
        'Alright, that gives me a clear and thorough understanding of your experience and technical background. Thank you for your time!';

      logger.info(`[InterviewService] Interview ${sessionId} completed naturally after ${session.totalTurns} turns.`);

      return {
        acknowledgement: 'Got it.',
        action: 'end_interview',
        nextQuestion: wrapUpMsg,
        nextTopic: currentTopicObj.name,
        currentTopicIndex: session.currentTopicIndex,
        totalTopics: session.topics.length,
        isComplete: true,
      };
    }

    // Call Gemini for next turn
    const recentQuestions = session.interactions
      .slice(-8)
      .map((i) => i.question)
      .filter(Boolean);

    const turn = await aiService.getNextConversationalTurn({
      role: session.role,
      experience: session.experience,
      skills: session.skills,
      difficulty: session.difficulty,
      currentTopic: currentTopicObj.name,
      topicObjective: currentTopicObj.objective,
      previousQuestion: lastInteraction?.question || '',
      candidateAnswer: answer,
      conversationSummary: session.conversationSummary,
      topicsCovered: session.topicsCovered,
      topicsRemaining,
      followUpsUsed: session.followUpsUsedForCurrentTopic,
      recentQuestions,
      turnNumber: session.totalTurns,
      maxTurns: session.maxTurns,
    });

    session.conversationSummary = turn.conversationSummary;

    let finalAction: 'follow_up' | 'new_topic' | 'end_interview' = turn.action;
    let nextQuestion = turn.nextQuestion;
    let nextTopic = turn.nextTopic;

    // Enforce max 1 follow-up per topic rule on the backend
    if (finalAction === 'follow_up') {
      if (session.followUpsUsedForCurrentTopic >= 1) {
        finalAction = 'new_topic';
      } else {
        session.followUpsUsedForCurrentTopic++;
      }
    }

    if (finalAction === 'new_topic') {
      session.topicsCovered.push(currentTopicObj.name);
      session.currentTopicIndex++;
      session.followUpsUsedForCurrentTopic = 0;

      if (session.currentTopicIndex >= session.topics.length) {
        session.status = 'completed';
        finalAction = 'end_interview';
        nextQuestion =
          'Alright, that covers everything I wanted to discuss today. Thank you so much for walking me through your experience!';
        nextTopic = 'Wrap Up';
      } else {
        nextTopic = session.topics[session.currentTopicIndex]?.name || nextTopic;
      }
    }

    if (finalAction !== 'end_interview') {
      session.totalTurns++;
      session.interactions.push({
        question: nextQuestion,
        answer: '',
        topic: nextTopic,
        type: finalAction === 'follow_up' ? 'follow_up' : 'primary',
        timestamp: new Date().toISOString(),
      });
    }

    return {
      acknowledgement: turn.acknowledgement,
      action: finalAction,
      nextQuestion,
      nextTopic,
      currentTopicIndex: session.currentTopicIndex,
      totalTopics: session.topics.length,
      isComplete: session.status === 'completed' || finalAction === 'end_interview',
    };
  }

  /**
   * STAGE 3: Generate and retrieve final evaluation scorecard, persisting to DB.
   */
  async getFinalResult(
    sessionId: string,
    userId: string
  ): Promise<FinalInterviewEvaluation> {
    const session = this.activeSessions.get(sessionId);

    if (!session) {
      throw Object.assign(new Error('Interview session not found or already archived'), { statusCode: 404 });
    }

    if (session.userId !== userId) {
      throw Object.assign(new Error('Forbidden: session does not belong to user'), { statusCode: 403 });
    }

    if (!session.finalEvaluation) {
      // Generate final evaluation via Gemini
      const evaluation = await aiService.generateFinalEvaluation({
        role: session.role,
        experience: session.experience,
        difficulty: session.difficulty,
        skills: session.skills,
        transcript: session.interactions.filter((i) => i.answer.trim().length > 0),
      });

      session.finalEvaluation = evaluation;
      session.status = 'completed';

      // Persist to database
      const durationSecs = Math.max(1, Math.round((Date.now() - session.startedAt) / 1000));
      const hiringBand =
        evaluation.performanceLevel === 'Excellent'
          ? 'Strong Hire'
          : evaluation.performanceLevel === 'Good'
          ? 'Hire'
          : evaluation.performanceLevel === 'Average'
          ? 'Leaning Hire'
          : 'Needs Practice';

      try {
        await interviewRepository.create({
          userId,
          role: session.role,
          type: 'technical',
          difficulty: session.difficulty,
          questionCount: session.interactions.length,
          score: evaluation.overallScore,
          hiringBand,
          summary: evaluation.summary,
          strengths: evaluation.strengths,
          areasToImprove: evaluation.areasToImprove,
          skillScores: evaluation.skillPerformance ?? {},
          durationSecs,
        });
        logger.info(`[InterviewService] Saved interview ${sessionId} into database for user=${userId}`);
      } catch (dbErr) {
        logger.error(`[InterviewService] Failed to save session to DB:`, dbErr);
      }
    }

    return session.finalEvaluation;
  }

  /** Save a manual completed interview session. */
  async saveSession(
    userId: string,
    data: Omit<CreateInterviewSessionInput, 'userId'>
  ): Promise<InterviewSession> {
    const session = await interviewRepository.create({ ...data, userId });
    logger.info(`Interview saved — user=${userId} score=${data.score} band=${data.hiringBand}`);
    return session;
  }

  /** List sessions for a user (paginated). */
  async listSessions(userId: string, limit = 20, offset = 0): Promise<InterviewSession[]> {
    return interviewRepository.findByUserId(userId, limit, offset);
  }

  /** Get a single session from DB, verifying ownership. */
  async getSession(sessionId: string, userId: string): Promise<InterviewSession> {
    const session = await interviewRepository.findById(sessionId);
    if (!session) {
      throw Object.assign(new Error('Interview session not found'), { statusCode: 404 });
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
