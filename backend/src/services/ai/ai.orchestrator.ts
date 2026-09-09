import { randomUUID } from 'crypto';
import { config } from '../../config';
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

  // ==========================================================
  // TIER ROUTING WITH RESILIENT FALLBACK
  // ==========================================================

  private async executeTier<T>(options: {
    operation: AIOperation;
    primaryProviderId: string;
    primaryModel: string;
    fallbackProviderId: string;
    fallbackModel: string;
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
      fallbackProviderId,
      fallbackModel,
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
    const fallbackProvider = this.providers.get(fallbackProviderId);
    const fallbackBreaker = this.circuitBreakers.get(fallbackProviderId);

    const startTime = Date.now();
    let primaryError: any = null;

    // Check if primary is available and circuit is closed/half-open
    const canUsePrimary =
      primaryProvider?.isConfigured() && primaryBreaker?.canExecute();

    if (canUsePrimary && primaryProvider) {
      try {
        console.log(
          `[AIOrchestrator] requestId=${requestId} operation=${operation} provider=${primaryProviderId} model=${primaryModel}`,
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
          attemptCount: 1,
        };

        return { data, metadata };
      } catch (err: any) {
        primaryError = err;
        const isTransient = isTransientError(err);
        primaryBreaker?.recordFailure(err);

        console.warn(
          `[AIOrchestrator] requestId=${requestId} Primary provider ${primaryProviderId} failed on ${operation} (transient=${isTransient}): ${err?.message || 'Unknown error'}`,
        );

        // Fail-fast on permanent non-transient errors (e.g. 400 bad request, 401 unauthorized)
        if (!isTransient) {
          throw new Error(
            `[AIOrchestrator] Permanent error from ${primaryProviderId}: ${err?.message || 'Client/Auth error'}`,
          );
        }
      }
    } else {
      const reason = !primaryProvider?.isConfigured()
        ? 'Not configured / missing API key'
        : 'Circuit breaker is OPEN (cooling down)';
      console.warn(
        `[AIOrchestrator] requestId=${requestId} Skipping primary provider ${primaryProviderId} for ${operation}: ${reason}`,
      );
      primaryError = new Error(`Primary provider skipped: ${reason}`);
    }

    // ----------------------------------------------------------
    // FALLBACK EXECUTION
    // ----------------------------------------------------------

    if (!fallbackProvider || !fallbackProvider.isConfigured()) {
      throw new Error(
        `[AIOrchestrator] Primary provider ${primaryProviderId} failed (${primaryError?.message}) and fallback provider ${fallbackProviderId} is not configured.`,
      );
    }

    if (!fallbackBreaker?.canExecute()) {
      throw new Error(
        `[AIOrchestrator] Both primary (${primaryProviderId}) and fallback (${fallbackProviderId}) are currently unavailable / circuit open.`,
      );
    }

    console.log(
      `[AIOrchestrator] requestId=${requestId} Triggering FALLBACK to ${fallbackProviderId} (${fallbackModel}) for ${operation}`,
    );

    const fallbackStartTime = Date.now();
    try {
      const data = await this.executeWithTimeout(
        (signal) =>
          fallbackProvider.executeStructured<T>({
            model: fallbackModel,
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
        `${operation}:${fallbackProviderId}`,
      );

      fallbackBreaker.recordSuccess();

      const metadata: AIExecutionMetadata = {
        requestId,
        operation,
        provider: fallbackProviderId,
        model: fallbackModel,
        circuitState: primaryBreaker?.getHealth().circuitState || fallbackBreaker.getHealth().circuitState,
        latencyMs: Date.now() - fallbackStartTime,
        fallbackUsed: true,
        fallbackReason: primaryError?.message || 'Primary unavailable',
        attemptCount: 2,
      };

      return { data, metadata };
    } catch (fallbackErr: any) {
      fallbackBreaker.recordFailure(fallbackErr);
      console.error(
        `[AIOrchestrator] requestId=${requestId} Fallback provider ${fallbackProviderId} also failed on ${operation}: ${fallbackErr?.message || 'Unknown error'}`,
      );

      throw new Error(
        `[AIOrchestrator] All providers failed for ${operation}. Primary: ${primaryError?.message} | Fallback: ${fallbackErr?.message}`,
      );
    }
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
      fallbackProviderId: config.ai.liveFallbackProvider,
      fallbackModel: config.ai.liveFallbackModel,
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
      fallbackProviderId: config.ai.liveFallbackProvider,
      fallbackModel: config.ai.liveFallbackModel,
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
    } else if (action === 'end_interview' && !isPenultimateTurn && currentTurn < totalMaxTurns - 2) {
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
      fallbackProviderId: config.ai.evalFallbackProvider,
      fallbackModel: config.ai.evalFallbackModel,
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
      skillPerformance['Flutter/Dart Role Mastery'] !== undefined &&
      skillPerformance['Role Mastery'] === undefined
    ) {
      skillPerformance['Role Mastery'] = skillPerformance['Flutter/Dart Role Mastery'];
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
