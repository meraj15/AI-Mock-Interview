import { randomUUID } from 'crypto';
import { config } from '../../config';
import { AppError } from '../../errors/AppError';
import {
  AIOperation,
  AIExecutionMetadata,
  AIExecutionResult,
  ConversationalTurn,
  ConversationalTurnParams,
  FinalEvaluationParams,
  FinalInterviewEvaluation,
  InterviewBlueprint,
  InterviewPlanParams,
  InterviewAIProvider,
  ProviderHealth,
  QuestionReview,
} from './ai.types';
import { CircuitBreaker, isTransientError } from './circuit-breaker';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAIProvider } from './providers/openai.provider';
import { buildInterviewPlanPrompt } from './prompts/interview-plan.prompt';
import { buildConversationalTurnPrompt } from './prompts/conversational-turn.prompt';
import { buildFinalEvaluationPrompt } from './prompts/final-evaluation.prompt';
import {
  interviewPlanGeminiSchema,
  interviewPlanOpenAISchema,
} from './schemas/interview-plan.schema';
import {
  conversationalTurnGeminiSchema,
  conversationalTurnOpenAISchema,
} from './schemas/conversational-turn.schema';
import {
  finalEvaluationGeminiSchema,
  finalEvaluationOpenAISchema,
} from './schemas/final-evaluation.schema';

// ============================================================
// AI ORCHESTRATOR
// ============================================================

export class AIOrchestrator {
  private providers: Map<string, InterviewAIProvider> = new Map();
  private circuitBreakers: Map<string, CircuitBreaker> = new Map();

  constructor() {
    this.registerProvider(new GeminiProvider());
    this.registerProvider(new OpenAIProvider());
  }

  private registerProvider(provider: InterviewAIProvider): void {
    this.providers.set(provider.id, provider);
    this.circuitBreakers.set(
      provider.id,
      new CircuitBreaker(
        provider.id,
        config.ai.circuitFailureThreshold,
        config.ai.circuitCooldownMs,
      ),
    );
  }

  public getProviderHealth(): Record<string, ProviderHealth> {
    const health: Record<string, ProviderHealth> = {};
    for (const [id, breaker] of this.circuitBreakers.entries()) {
      health[id] = breaker.getHealth();
    }
    return health;
  }

  // ==========================================================
  // TIMEOUT EXECUTOR
  // ==========================================================

  private async executeWithTimeout<T>(
    fn: (signal?: AbortSignal) => Promise<T>,
    timeoutMs: number,
    label: string,
  ): Promise<T> {
    const controller = new AbortController();
    let timer: NodeJS.Timeout;

    const timeoutPromise = new Promise<never>((_, reject) => {
      timer = setTimeout(() => {
        controller.abort();
        reject(new Error(`[AIOrchestrator] ${label} timed out after ${timeoutMs}ms`));
      }, timeoutMs);
    });

    try {
      return await Promise.race([fn(controller.signal), timeoutPromise]);
    } finally {
      clearTimeout(timer!);
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  // ==========================================================
  // GEMINI EXECUTION WITH EXPONENTIAL BACKOFF RETRIES
  // ==========================================================

  private async executeTier<T>(options: {
    operation: AIOperation;
    primaryProviderId: string;
    primaryModel: string;
    timeoutMs: number;
    prompt: string;
    geminiSchema?: any;
    openAISchema?: any;
    schemaName: string;
    temperature?: number;
    thinkingLevel?: 'minimal' | 'low' | 'medium' | 'high';
  }): Promise<AIExecutionResult<T>> {
    const {
      operation,
      primaryProviderId,
      primaryModel,
      timeoutMs,
      prompt,
      geminiSchema,
      openAISchema,
      schemaName,
      temperature,
      thinkingLevel,
    } = options;

    const requestId = randomUUID();
    const primaryProvider = this.providers.get(primaryProviderId);
    const primaryBreaker = this.circuitBreakers.get(primaryProviderId);

    if (!primaryProvider || !primaryProvider.isConfigured()) {
      throw new AppError(
        'Gemini API key is not configured. Please set GEMINI_API_KEY in your backend .env file.',
        500,
        'GEMINI_NOT_CONFIGURED',
      );
    }

    const startTime = Date.now();
    const maxRetries = 3; // 1 initial attempt + 3 retries = 4 attempts total
    const backoffDelays = [1000, 2000, 4000]; // 1s, 2s, 4s

    let lastError: any = null;

    for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
      try {
        console.log(
          `[AIOrchestrator] requestId=${requestId} operation=${operation} provider=${primaryProviderId} model=${primaryModel} (attempt ${attempt}/${maxRetries + 1})`,
        );

        const data = await this.executeWithTimeout(
          (signal) =>
            primaryProvider.executeStructured<T>({
              model: primaryModel,
              prompt,
              geminiSchema,
              openAISchema,
              schemaName,
              temperature,
              thinkingLevel,
              timeoutMs,
              abortSignal: signal,
            }),
          timeoutMs,
          `${operation}:${primaryProviderId}`,
        );

        primaryBreaker?.recordSuccess();

        const metadata: AIExecutionMetadata = {
          requestId,
          operation,
          provider: primaryProviderId,
          model: primaryModel,
          circuitState: primaryBreaker?.getHealth().circuitState || 'CLOSED',
          latencyMs: Date.now() - startTime,
          fallbackUsed: false,
          attemptCount: attempt,
        };

        return { data, metadata };
      } catch (err: any) {
        lastError = err;
        const isTransient = isTransientError(err);
        primaryBreaker?.recordFailure(err);

        console.warn(
          `[AIOrchestrator] requestId=${requestId} ${primaryProviderId} failed on ${operation} (attempt ${attempt}/${maxRetries + 1}, transient=${isTransient}): ${err?.message || 'Unknown error'}`,
        );

        // Fail-fast on permanent non-transient errors (e.g. 400 Bad Request, 401 Unauthorized, 404 Model Not Found)
        if (!isTransient) {
          throw new AppError(
            `Gemini service error: ${err?.message || 'Permanent client/auth error'}`,
            400,
            'AI_PERMANENT_ERROR',
          );
        }

        // If we still have retries remaining, wait with exponential backoff
        if (attempt <= maxRetries) {
          const delayMs = backoffDelays[attempt - 1] || 4000;
          console.log(
            `[AIOrchestrator] requestId=${requestId} Retrying ${operation} with ${primaryProviderId} in ${delayMs}ms (transient failure)...`,
          );
          await this.sleep(delayMs);
        }
      }
    }

    // All retries exhausted
    console.error(
      `[AIOrchestrator] requestId=${requestId} All ${maxRetries + 1} attempts failed for ${operation}: ${lastError?.message || 'Unavailable'}`,
    );

    throw new AppError(
      'The AI interview service is currently experiencing high demand. Please try again in a moment.',
      503,
      'AI_SERVICE_UNAVAILABLE',
    );
  }

  // ==========================================================
  // SANITIZATION HELPERS
  // ==========================================================

  private enforceSingleQuestion(rawQuestion: string, fallback: string): string {
    let q = (rawQuestion || '').trim().replace(/^["']|["']$/g, '');
    if (!q) return fallback;

    // Strip conversational reactions / acknowledgements if prepended
    q = q.replace(
      /^(Understood[.,!]?|Got it,?( that makes sense)?[.,!]?|Makes (total )?sense[.,!]?|Fair (point|enough)[.,!]?|Right on[.,!]?|Thank you[.,!]?|Thanks for (sharing|that)[.,!]?|Certainly!?|Sure!?|Alright,?|Okay,?|Now,?|Moving on,?|Next question:?)\s*/i,
      '',
    );

    // Extract only first question if multiple question marks exist
    if (q.includes('?')) {
      const parts = q.split('?');
      if (parts.length > 2) {
        q = parts[0].trim() + '?';
      }
    }

    // Ensure ending question mark
    if (!q.endsWith('?') && !q.endsWith('!')) {
      if (q.match(/^(can|could|how|what|why|where|when|which|tell|walk|explain)/i)) {
        q = q.replace(/[.,;:]+$/, '') + '?';
      }
    }

    // Clean up compound questions joined with "and how / and why / and what"
    q = q.replace(/,\s*and\s+(how|why|what|can|could|where)\b.*\?/i, '?');

    return q;
  }

  private clamp(value: any): number {
    return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
  }

  // ==========================================================
  // STAGE 1: INTERVIEW PLAN (WARM OPENING)
  // ==========================================================

  async generateInterviewPlanWithMeta(
    params: InterviewPlanParams,
  ): Promise<AIExecutionResult<InterviewBlueprint>> {
    const { role } = params;
    if (!role || typeof role !== 'string' || !role.trim()) {
      throw new Error('Role is required');
    }

    const prompt = buildInterviewPlanPrompt(params);

    const result = await this.executeTier<{ firstQuestion: string }>({
      operation: 'plan',
      primaryProviderId: config.ai.livePrimaryProvider,
      primaryModel: config.ai.livePrimaryModel,
      timeoutMs: config.ai.liveTimeoutMs,
      prompt,
      geminiSchema: interviewPlanGeminiSchema,
      openAISchema: interviewPlanOpenAISchema,
      schemaName: 'interview_plan',
      temperature: 0.7,
      thinkingLevel: 'low',
    });

    const defaultFirstQ = `Welcome! Could you introduce yourself and share your background as a ${role.trim()}?`;
    const firstQuestion = this.enforceSingleQuestion(
      String(result.data.firstQuestion || '').trim(),
      defaultFirstQ,
    );

    return {
      data: { topics: [], firstQuestion },
      metadata: result.metadata,
    };
  }

  async generateInterviewPlan(params: InterviewPlanParams): Promise<InterviewBlueprint> {
    const res = await this.generateInterviewPlanWithMeta(params);
    return res.data;
  }

  // ==========================================================
  // STAGE 2: LIVE ADAPTIVE CONVERSATIONAL TURN
  // ==========================================================

  async getNextConversationalTurnWithMeta(
    params: ConversationalTurnParams,
  ): Promise<AIExecutionResult<ConversationalTurn>> {
    const { prompt, currentTurn, totalMaxTurns } = buildConversationalTurnPrompt(params);

    const result = await this.executeTier<ConversationalTurn>({
      operation: 'live_turn',
      primaryProviderId: config.ai.livePrimaryProvider,
      primaryModel: config.ai.livePrimaryModel,
      timeoutMs: config.ai.liveTimeoutMs,
      prompt,
      geminiSchema: conversationalTurnGeminiSchema,
      openAISchema: conversationalTurnOpenAISchema,
      schemaName: 'conversational_turn',
      temperature: 0.7,
      thinkingLevel: 'low',
    });

    const raw = result.data;
    const isPenultimateTurn = currentTurn === totalMaxTurns - 1;
    const isFinalClosingTurn = currentTurn >= totalMaxTurns;

    // Normalization & guards
    let acknowledgement = (raw.acknowledgement || '').trim();
    if (acknowledgement.split(/\s+/).length > 6) {
      acknowledgement = acknowledgement.split(/\s+/).slice(0, 4).join(' ') + '.';
    }

    let action = raw.action;
    if (isFinalClosingTurn) {
      action = 'end_interview';
    } else if (action === 'end_interview' && currentTurn < totalMaxTurns) {
      action = 'new_topic';
    }

    const fallbackQuestion =
      action === 'end_interview'
        ? "Thank you for sharing your experience. We'll conclude the interview here!"
        : `Could you tell me more about your experience as a ${params.role}?`;

    const nextQuestion = this.enforceSingleQuestion(raw.nextQuestion, fallbackQuestion);
    const nextTopic = (raw.nextTopic || 'Role Competency').trim();
    const conversationSummary = (
      raw.conversationSummary || params.conversationSummary || 'Interview in progress.'
    ).trim();

    return {
      data: {
        acknowledgement,
        action,
        nextQuestion,
        nextTopic,
        conversationSummary,
      },
      metadata: result.metadata,
    };
  }

  async getNextConversationalTurn(
    params: ConversationalTurnParams,
  ): Promise<ConversationalTurn> {
    const res = await this.getNextConversationalTurnWithMeta(params);
    return res.data;
  }

  // ==========================================================
  // STAGE 3: DEEP FINAL EVALUATION
  // ==========================================================

  async generateFinalEvaluationWithMeta(
    params: FinalEvaluationParams,
  ): Promise<AIExecutionResult<FinalInterviewEvaluation>> {
    if (!params.transcript || params.transcript.length === 0) {
      throw new Error('Interview transcript is required');
    }

    const prompt = buildFinalEvaluationPrompt(params);

    const result = await this.executeTier<any>({
      operation: 'final_evaluation',
      primaryProviderId: config.ai.evalPrimaryProvider,
      primaryModel: config.ai.evalPrimaryModel,
      timeoutMs: config.ai.evalTimeoutMs,
      prompt,
      geminiSchema: finalEvaluationGeminiSchema,
      openAISchema: finalEvaluationOpenAISchema,
      schemaName: 'final_evaluation',
      temperature: 0.3, // Lower temperature for objective, consistent scoring
    });

    const raw = result.data;

    // Normalize skill performance
    const rawSkillPerformance = raw.skillPerformance || {};
    const skillPerformance: Record<string, number> = {};
    for (const [key, value] of Object.entries(rawSkillPerformance)) {
      skillPerformance[key] = this.clamp(value);
    }
    if (
      skillPerformance['Role Mastery'] === undefined &&
      skillPerformance['Technical Knowledge'] !== undefined
    ) {
      skillPerformance['Role Mastery'] = skillPerformance['Technical Knowledge'];
    }

    // Normalize question reviews
    const questionReviews: QuestionReview[] = Array.isArray(raw.questionReviews)
      ? raw.questionReviews.map((review: any) => ({
          question: String(review?.question || '').trim(),
          answer: String(review?.answer || '').trim(),
          expectedAnswer: String(review?.expectedAnswer || '').trim(),
          feedback: String(review?.feedback || '').trim(),
          score: this.clamp(review?.score),
        }))
      : [];

    const evaluation: FinalInterviewEvaluation = {
      overallScore: this.clamp(raw.overallScore),
      performanceLevel: raw.performanceLevel || 'Average',
      summary: String(raw.summary || '').trim(),
      strengths: Array.isArray(raw.strengths)
        ? raw.strengths.map((s: any) => String(s).trim()).filter(Boolean)
        : [],
      areasToImprove: Array.isArray(raw.areasToImprove)
        ? raw.areasToImprove.map((a: any) => String(a).trim()).filter(Boolean)
        : [],
      skillPerformance,
      recommendations: Array.isArray(raw.recommendations)
        ? raw.recommendations.map((r: any) => String(r).trim()).filter(Boolean)
        : [],
      questionReviews,
    };

    return {
      data: evaluation,
      metadata: result.metadata,
    };
  }

  async generateFinalEvaluation(
    params: FinalEvaluationParams,
  ): Promise<FinalInterviewEvaluation> {
    const res = await this.generateFinalEvaluationWithMeta(params);
    return res.data;
  }
}

// ============================================================
// SINGLETON INSTANCE
// ============================================================

export const aiOrchestrator = new AIOrchestrator();
