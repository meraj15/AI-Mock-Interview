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
  startedAt: number;
}

export class InterviewService {
  private activeSessions = new Map<
    string,
    ActiveConversationalSession
  >();

  /**
   * STAGE 1
   *
   * Starts a conversational interview.
   *
   * Important:
   * - There is NO user-selected difficulty.
   * - Gemini generates only the first question synchronously.
   * - Interview topics are generated in the background.
   */
  async startConversationalInterview(
    userId: string,
    params: {
      role: string;
      skills?: string[];
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
    const {
      role,
      skills = [],
      experience,
      questionCount = 5,
    } = params;

    if (!role?.trim()) {
      throw Object.assign(
        new Error('Role is required'),
        { statusCode: 400 },
      );
    }

    const normalizedSkills = skills
      .filter(
        (skill): skill is string =>
          typeof skill === 'string' &&
          skill.trim().length > 0,
      )
      .map((skill) => skill.trim());

    const plan =
      await aiService.generateInterviewPlan({
        role: role.trim(),
        skills: normalizedSkills,
        experience,
        questionCount,
      });

    const placeholderTopics: InterviewTopic[] = [
      {
        name: 'Introduction',
        objective:
          'Open the interview naturally and understand the candidate background.',
      },
    ];

    const sessionId = randomUUID();

    const maxTurns = Math.max(
      6,
      Math.min(12, questionCount * 2),
    );

    const session: ActiveConversationalSession = {
      id: sessionId,
      userId,
      role: role.trim(),
      skills: normalizedSkills,
      experience,

      topics: placeholderTopics,
      currentTopicIndex: 0,
      topicsCovered: [],
      followUpsUsedForCurrentTopic: 0,

      totalTurns: 1,
      maxTurns,

      conversationSummary: '',

      interactions: [
        {
          question: plan.firstQuestion,
          answer: '',
          topic: 'Introduction',
          type: 'primary',
          timestamp: new Date().toISOString(),
        },
      ],

      status: 'in_progress',
      createdAt: new Date(),
      startedAt: Date.now(),
    };

    this.activeSessions.set(
      sessionId,
      session,
    );

    // Do not block the first-question response.
    this.populateTopicsAsync(sessionId, {
      role: session.role,
      skills: session.skills,
      experience: session.experience,
    });

    logger.info(
      `[InterviewService] Started conversational interview ${sessionId} for user=${userId} role="${session.role}"`,
    );

    return {
      sessionId,
      role: session.role,
      topics: session.topics,
      currentTopic: session.topics[0].name,
      currentTopicIndex: 0,
      totalTopics: session.topics.length,
      firstQuestion: plan.firstQuestion,
    };
  }

  /**
   * Generates the broad Flutter/Dart topic pool in the background.
   *
   * Candidate skills are passed as context only. The AI service is
   * responsible for ensuring they do not restrict the interview.
   */
  private populateTopicsAsync(
    sessionId: string,
    params: {
      role: string;
      skills?: string[];
      experience?: string;
    },
  ): void {
    aiService
      .generateTopics(params)
      .then((topics) => {
        const session =
          this.activeSessions.get(sessionId);

        if (
          !session ||
          session.status === 'completed'
        ) {
          return;
        }

        if (topics.length === 0) {
          logger.warn(
            `[InterviewService] No topics generated for session ${sessionId}`,
          );
          return;
        }

        session.topics = topics;

        session.maxTurns = Math.min(
          12,
          Math.max(6, topics.length * 2),
        );

        // The first interaction is an opening question,
        // not a technical topic.
        if (
          session.interactions[0]?.topic ===
          'Introduction'
        ) {
          session.interactions[0].topic =
            'Introduction';
        }

        logger.info(
          `[InterviewService] Topics populated for session ${sessionId}: ${topics
            .map((topic) => topic.name)
            .join(', ')}`,
        );
      })
      .catch((err) => {
        // Topic generation must never crash an active interview.
        logger.warn(
          `[InterviewService] Background topic generation failed for session ${sessionId}: ${
            err?.message || err
          }`,
        );
      });
  }

  /**
   * STAGE 2
   *
   * Receives one candidate answer and asks Gemini what should happen next.
   *
   * The AI dynamically decides:
   * - answer quality
   * - follow-up vs new topic
   * - next question
   * - next topic
   *
   * There is no difficulty field.
   */
  async submitAnswer(
    sessionId: string,
    userId: string,
    answer: string,
  ): Promise<{
    acknowledgement: string;
    action:
      | 'follow_up'
      | 'new_topic'
      | 'end_interview';
    answerQuality:
      | 'weak'
      | 'average'
      | 'strong'
      | 'excellent';
    nextQuestion: string;
    nextTopic: string;
    currentTopicIndex: number;
    totalTopics: number;
    isComplete: boolean;
  }> {
    const session =
      this.activeSessions.get(sessionId);

    if (!session) {
      throw Object.assign(
        new Error(
          'Active interview session not found or expired',
        ),
        { statusCode: 404 },
      );
    }

    if (session.userId !== userId) {
      throw Object.assign(
        new Error(
          'Forbidden: session does not belong to user',
        ),
        { statusCode: 403 },
      );
    }

    if (session.status === 'completed') {
      return {
        acknowledgement: '',
        action: 'end_interview',
        answerQuality: 'average',
        nextQuestion:
          'The interview is already completed.',
        nextTopic: 'Completed',
        currentTopicIndex:
          session.currentTopicIndex,
        totalTopics: session.topics.length,
        isComplete: true,
      };
    }

    const cleanedAnswer =
      typeof answer === 'string'
        ? answer.trim()
        : '';

    if (!cleanedAnswer) {
      throw Object.assign(
        new Error('Answer is required'),
        { statusCode: 400 },
      );
    }

    // Save candidate answer to the current/last interaction.
    const lastInteraction =
      session.interactions[
        session.interactions.length - 1
      ];

    if (lastInteraction) {
      lastInteraction.answer = cleanedAnswer;
    }

    const currentTopic =
      session.topics[
        session.currentTopicIndex
      ] || {
        name: 'General',
        objective:
          'Evaluate general Flutter/Dart technical competence.',
      };

    const topicsRemaining =
      session.topics
        .slice(
          session.currentTopicIndex + 1,
        )
        .map((topic) => topic.name);

    const isAtMaxTurns =
      session.totalTurns >= session.maxTurns;

    if (isAtMaxTurns) {
      return this.completeInterview(
        session,
        currentTopic.name,
        'Maximum interview turns reached.',
      );
    }

    const recentQuestions =
      session.interactions
        .slice(-10)
        .map((interaction) =>
          interaction.question?.trim(),
        )
        .filter(
          (question): question is string =>
            Boolean(question),
        );

    const turn =
      await aiService.getNextConversationalTurn({
        role: session.role,
        experience: session.experience,
        skills: session.skills,

        currentTopic: currentTopic.name,
        topicObjective:
          currentTopic.objective,

        previousQuestion:
          lastInteraction?.question || '',

        candidateAnswer: cleanedAnswer,

        conversationSummary:
          session.conversationSummary,

        topicsCovered:
          session.topicsCovered,

        topicsRemaining,

        followUpsUsed:
          session.followUpsUsedForCurrentTopic,

        recentQuestions,

        turnNumber: session.totalTurns,
        maxTurns: session.maxTurns,
      });

    session.conversationSummary =
      turn.conversationSummary;

    let finalAction:
      | 'follow_up'
      | 'new_topic'
      | 'end_interview' =
      turn.action;

    let nextQuestion =
      turn.nextQuestion.trim();

    let nextTopic =
      turn.nextTopic.trim();

    // ----------------------------------------------------------
    // Backend safety rule:
    // Never allow more than 2 follow-ups for one topic.
    // ----------------------------------------------------------

    if (
      finalAction === 'follow_up'
    ) {
      if (
        session.followUpsUsedForCurrentTopic >=
        2
      ) {
        finalAction = 'new_topic';
      } else {
        session.followUpsUsedForCurrentTopic++;
      }
    }

    // ----------------------------------------------------------
    // Move to a new topic only when AI selected new_topic.
    // Synchronize the topic index with the topic AI selected.
    // ----------------------------------------------------------

    if (
      finalAction === 'new_topic'
    ) {
      if (currentTopic.name) {
        if (
          !session.topicsCovered.includes(
            currentTopic.name,
          )
        ) {
          session.topicsCovered.push(
            currentTopic.name,
          );
        }
      }

      const matchedTopicIndex =
        session.topics.findIndex(
          (topic, index) =>
            index >
              session.currentTopicIndex &&
            topic.name
              .trim()
              .toLowerCase() ===
              nextTopic
                .trim()
                .toLowerCase(),
        );

      if (matchedTopicIndex >= 0) {
        session.currentTopicIndex =
          matchedTopicIndex;
      } else {
        const nextIndex =
          session.currentTopicIndex + 1;

        if (
          nextIndex >=
          session.topics.length
        ) {
          return this.completeInterview(
            session,
            currentTopic.name,
            'All interview topics have been covered.',
          );
        }

        session.currentTopicIndex =
          nextIndex;

        nextTopic =
          session.topics[
            nextIndex
          ]?.name || nextTopic;
      }

      session.followUpsUsedForCurrentTopic = 0;
    }

    // ----------------------------------------------------------
    // Final safety check.
    // ----------------------------------------------------------

    if (!nextQuestion) {
      throw new Error(
        'AI did not return a next interview question',
      );
    }

    if (
      session.totalTurns + 1 >
      session.maxTurns
    ) {
      return this.completeInterview(
        session,
        currentTopic.name,
        'Interview duration reached its limit.',
      );
    }

    // Add the next interviewer question.
    session.totalTurns++;

    session.interactions.push({
      question: nextQuestion,
      answer: '',
      topic: nextTopic,
      type:
        finalAction === 'follow_up'
          ? 'follow_up'
          : 'primary',
      timestamp:
        new Date().toISOString(),
    });

    logger.info(
      `[InterviewService] Session ${sessionId}: turn=${session.totalTurns}, action=${finalAction}, quality=${turn.answerQuality}, topic="${nextTopic}"`,
    );

    return {
      acknowledgement:
        turn.acknowledgement,

      action: finalAction,

      answerQuality:
        turn.answerQuality,

      nextQuestion,

      nextTopic,

      currentTopicIndex:
        session.currentTopicIndex,

      totalTopics:
        session.topics.length,

      isComplete: false,
    };
  }

  /**
   * Completes the active interview without generating another question.
   */
  private completeInterview(
    session: ActiveConversationalSession,
    topic: string,
    reason: string,
  ): {
    acknowledgement: string;
    action: 'end_interview';
    answerQuality:
      | 'weak'
      | 'average'
      | 'strong'
      | 'excellent';
    nextQuestion: string;
    nextTopic: string;
    currentTopicIndex: number;
    totalTopics: number;
    isComplete: true;
  } {
    session.status = 'completed';

    logger.info(
      `[InterviewService] Interview ${session.id} completed: ${reason}`,
    );

    return {
      acknowledgement: 'Thank you.',
      action: 'end_interview',
      answerQuality: 'average',
      nextQuestion:
        'That covers the interview. Thank you for your time!',
      nextTopic: topic,
      currentTopicIndex:
        session.currentTopicIndex,
      totalTopics: session.topics.length,
      isComplete: true,
    };
  }

  /**
   * STAGE 3
   *
   * Generates the final evaluation and persists it.
   *
   * Difficulty is intentionally NOT passed to the AI.
   */
  async getFinalResult(
    sessionId: string,
    userId: string,
  ): Promise<FinalInterviewEvaluation> {
    const session =
      this.activeSessions.get(sessionId);

    if (!session) {
      throw Object.assign(
        new Error(
          'Interview session not found or already archived',
        ),
        { statusCode: 404 },
      );
    }

    if (session.userId !== userId) {
      throw Object.assign(
        new Error(
          'Forbidden: session does not belong to user',
        ),
        { statusCode: 403 },
      );
    }

    if (!session.finalEvaluation) {
      const transcript =
        session.interactions.filter(
          (interaction) =>
            interaction.answer.trim().length > 0,
        );

      if (transcript.length === 0) {
        throw Object.assign(
          new Error(
            'No completed interview answers found',
          ),
          { statusCode: 400 },
        );
      }

      const evaluation =
        await aiService.generateFinalEvaluation({
          role: session.role,
          experience: session.experience,
          skills: session.skills,
          transcript,
        });

      session.finalEvaluation =
        evaluation;

      session.status = 'completed';

      const durationSecs = Math.max(
        1,
        Math.round(
          (Date.now() -
            session.startedAt) /
            1000,
        ),
      );

      const hiringBand =
        evaluation.performanceLevel ===
        'Excellent'
          ? 'Strong Hire'
          : evaluation.performanceLevel ===
            'Good'
          ? 'Hire'
          : evaluation.performanceLevel ===
            'Average'
          ? 'Leaning Hire'
          : 'Needs Practice';

      try {
        /*
         * The repository may still require a legacy `difficulty`
         * database field. We keep the database value as "Adaptive"
         * for backward compatibility, while difficulty is completely
         * removed from the active interview/AI logic.
         *
         * If you remove `difficulty` from the database schema later,
         * remove this field from the repository input as well.
         */
        await interviewRepository.create({
          userId,
          role: session.role,
          type: 'technical',

          questionCount:
            transcript.length,

          score:
            evaluation.overallScore,

          hiringBand,

          summary:
            evaluation.summary,

          strengths:
            evaluation.strengths,

          areasToImprove:
            evaluation.areasToImprove,

          skillScores:
            evaluation.skillPerformance ??
            {},

          durationSecs,
        });

        logger.info(
          `[InterviewService] Saved interview ${sessionId} into database for user=${userId}`,
        );
      } catch (dbErr) {
        logger.error(
          `[InterviewService] Failed to save session to DB:`,
          dbErr,
        );
      }
    }

    return session.finalEvaluation;
  }

  /**
   * Save a manually completed interview session.
   */
  async saveSession(
    userId: string,
    data: Omit<
      CreateInterviewSessionInput,
      'userId'
    >,
  ): Promise<InterviewSession> {
    const session =
      await interviewRepository.create({
        ...data,
        userId,
      });

    logger.info(
      `Interview saved — user=${userId} score=${data.score} band=${data.hiringBand}`,
    );

    return session;
  }

  /**
   * List sessions for a user.
   */
  async listSessions(
    userId: string,
    limit = 20,
    offset = 0,
  ): Promise<InterviewSession[]> {
    return interviewRepository.findByUserId(
      userId,
      limit,
      offset,
    );
  }

  /**
   * Get a single session from DB.
   */
  async getSession(
    sessionId: string,
    userId: string,
  ): Promise<InterviewSession> {
    const session =
      await interviewRepository.findById(
        sessionId,
      );

    if (!session) {
      throw Object.assign(
        new Error(
          'Interview session not found',
        ),
        { statusCode: 404 },
      );
    }

    if (session.userId !== userId) {
      throw Object.assign(
        new Error('Forbidden'),
        { statusCode: 403 },
      );
    }

    return session;
  }

  /**
   * Aggregated performance stats.
   */
  async getStats(
    userId: string,
  ): Promise<InterviewStats> {
    return interviewRepository.getStats(
      userId,
    );
  }
}

export const interviewService =
  new InterviewService();