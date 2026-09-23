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
  LatencyTelemetry,
  ProviderHealth,
  QuestionReview,
  TokenUsage,
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
// TOKEN OUTPUT BUDGETS
// ============================================================
//
// Interview plan only returns { firstQuestion: string }. 150 tokens is plenty.
// Live interview turns return compact JSON (~120-150 tokens expected).
// 320 tokens provides a safe margin preventing any incomplete JSON truncation.
// Final evaluation is a full scorecard with question reviews. 4096 tokens.
const PLAN_MAX_OUTPUT_TOKENS = 150;
const TURN_MAX_OUTPUT_TOKENS = 320;
const EVAL_MAX_OUTPUT_TOKENS = 4096;

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
  // TELEMETRY HELPER
  // ==========================================================

  private emitTelemetry(telemetry: LatencyTelemetry): void {
    if (!config.ai.enableTelemetry) return;
    // Never log API keys, JWTs, passwords, full resumes, or raw candidate answers.
    console.log('[TELEMETRY]', JSON.stringify(telemetry));
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
        const timeoutErr: any = new Error(`[AIOrchestrator] ${label} timed out after ${timeoutMs}ms`);
        timeoutErr.status = 504; // Gateway Timeout — let isTransientError recognize it
        timeoutErr.statusCode = 504;
        timeoutErr.isTimeout = true;
        reject(timeoutErr);
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

  /**
   * Returns a jittered backoff delay.
   * Live turns: ~1.0-1.5s (1000ms base + 0-500ms jitter).
   * Eval: longer delays since it is not real-time.
   * Jitter prevents thundering-herd retry storms.
   */
  private jitteredDelay(attemptIndex: number, isLive: boolean): number {
    const bases = isLive ? [1000] : [1000, 2000, 4000];
    const base = bases[attemptIndex] ?? (isLive ? 1000 : 4000);
    const jitter = Math.floor(Math.random() * 500);
    return base + jitter;
  }

  // ==========================================================
  // CORE EXECUTION WITH BACKOFF + JITTER
  // ==========================================================

  /**
   * COST DESIGN:
   *
   * Live turns:  maxRetries = 1 → max 2 total Gemini calls per answer
   * Eval:        maxRetries = 2 → max 3 total Gemini calls for final evaluation
   *
   * Keeping live retries low is critical:
   * - Each retry is a real API cost
   * - Flutter may also retry, creating a multiplicative effect
   * - Idempotency prevents duplicate AI calls from Flutter retries
   */
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
    thinkingLevel?: 'minimal' | 'low' | 'medium' | 'high' | null;
    maxOutputTokens?: number;
    promptBuildMs?: number;
    sessionId?: string;
    turnNumber?: number;
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
      maxOutputTokens,
      promptBuildMs,
      sessionId,
      turnNumber,
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

    // Check circuit breaker before any attempt — avoids a Gemini call entirely when open
    if (primaryBreaker && !primaryBreaker.canExecute()) {
      this.emitTelemetry({
        operation,
        provider: primaryProviderId,
        model: primaryModel,
        latencyMs: 0,
        attemptCount: 0,
        cacheHit: false,
        retryReason: 'CIRCUIT_OPEN',
        sessionId,
        turnNumber,
      });
      throw new AppError(
        'The AI interview service is temporarily unavailable. Please try again in a moment.',
        503,
        'AI_CIRCUIT_OPEN',
      );
    }

    const totalStartTime = Date.now();
    const isLive = operation === 'plan' || operation === 'live_turn';

    /**
     * RETRY BUDGET:
     * - Live turns (plan + live_turn): 1 retry max → 2 Gemini calls maximum
     *   Keeps cost low and avoids long wait for candidate.
     * - Final evaluation: 2 retries max → 3 Gemini calls maximum
     *   More generous because it runs once post-interview.
     *
     * Flutter-level retries are separately protected by the idempotency layer.
     */
    const maxRetries = isLive ? 1 : 2;

    let lastError: any = null;
    let lastRetryReason: string | undefined;
    let retryCount = 0;
    let finalTokenUsage: TokenUsage | undefined;

    for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
      const attemptStart = Date.now();
      try {
        console.log(
          `[AIOrchestrator] requestId=${requestId} operation=${operation} provider=${primaryProviderId} model=${primaryModel} (attempt ${attempt}/${maxRetries + 1})`,
        );

        const providerResponse = await this.executeWithTimeout(
          (signal) =>
            primaryProvider.executeStructured<T>({
              model: primaryModel,
              prompt,
              geminiSchema,
              openAISchema,
              schemaName,
              temperature,
              thinkingLevel: thinkingLevel ?? undefined,
              maxOutputTokens,
              timeoutMs,
              abortSignal: signal,
            }),
          timeoutMs,
          `${operation}:${primaryProviderId}`,
        );

        primaryBreaker?.recordSuccess();

        const aiLatencyMs = Date.now() - attemptStart;
        const totalLatencyMs = Date.now() - totalStartTime;
        finalTokenUsage = providerResponse.tokenUsage;

        const metadata: AIExecutionMetadata = {
          requestId,
          operation,
          provider: primaryProviderId,
          model: primaryModel,
          circuitState: primaryBreaker?.getHealth().circuitState || 'CLOSED',
          latencyMs: totalLatencyMs,
          fallbackUsed: false,
          attemptCount: attempt,
          promptBuildMs,
          aiLatencyMs,
          tokenUsage: finalTokenUsage,
        };

        this.emitTelemetry({
          operation,
          provider: primaryProviderId,
          model: primaryModel,
          promptBuildMs,
          aiLatencyMs,
          latencyMs: totalLatencyMs,
          totalLatencyMs,
          attemptCount: attempt,
          retryCount,
          cacheHit: false,
          retryReason: lastRetryReason,
          tokenUsage: finalTokenUsage,
          sessionId,
          turnNumber,
        });

        return { data: providerResponse.data, metadata };
      } catch (err: any) {
        lastError = err;
        const isTransient = isTransientError(err);
        const aiLatencyMs = Date.now() - attemptStart;

        // Extract Retry-After header if present (Gemini 429 may include it)
        const rawRetryAfter = this.extractRetryAfterMs(err);
        // Cap Retry-After to avoid indefinite client freezes: 2.5s max for live turns, 10s max for eval
        const retryAfterMs = rawRetryAfter !== undefined
          ? Math.min(rawRetryAfter, isLive ? 2500 : 10000)
          : undefined;

        // Derive status and error reason for telemetry (safe — no PII)
        const errStatus =
          Number(err?.status || err?.statusCode || err?.code || err?.error?.status) || (isTransient ? 503 : 400);
        lastRetryReason = String(errStatus);
        const willRetry = isTransient && attempt <= maxRetries;

        // Structured [AI_ERROR] telemetry log for operational observability
        console.error(
          `[AI_ERROR] ${JSON.stringify({
            operation,
            provider: primaryProviderId,
            model: primaryModel,
            status: errStatus,
            attempt,
            maxAttempts: maxRetries + 1,
            retrying: willRetry,
            sessionId,
            turnNumber,
            aiLatencyMs,
            errorType: isTransient ? 'transient' : 'permanent',
            errorMessage: err?.message || 'Unknown error',
          })}`,
        );

        // Fail-fast on permanent non-transient errors — do not retry, count on circuit breaker
        if (!isTransient) {
          primaryBreaker?.recordFailure(err);
          this.emitTelemetry({
            operation,
            provider: primaryProviderId,
            model: primaryModel,
            promptBuildMs,
            latencyMs: Date.now() - totalStartTime,
            totalLatencyMs: Date.now() - totalStartTime,
            attemptCount: attempt,
            retryCount,
            cacheHit: false,
            retryReason: lastRetryReason,
            sessionId,
            turnNumber,
          });
          throw new AppError(
            `AI service error: ${err?.message || 'Permanent client/auth error'}`,
            400,
            'AI_PERMANENT_ERROR',
          );
        }

        // If we still have retries remaining, wait with exponential backoff + jitter
        if (willRetry) {
          retryCount++;
          const delayMs = retryAfterMs ?? this.jitteredDelay(attempt - 1, isLive);
          console.log(
            `[AIOrchestrator] requestId=${requestId} Retrying ${operation} in ${delayMs}ms (reason: ${lastRetryReason}, retryCount=${retryCount})`,
          );
          await this.sleep(delayMs);
        }
      }
    }

    // Record circuit breaker failure once for the entire logical operation when all retries are exhausted
    primaryBreaker?.recordFailure(lastError);

    // Structured [AI_ERROR] telemetry on final exhaustion
    console.error(
      `[AI_ERROR] ${JSON.stringify({
        operation,
        provider: primaryProviderId,
        model: primaryModel,
        status: Number(lastError?.status || lastError?.statusCode || 503) || 503,
        attempt: maxRetries + 1,
        retrying: false,
        sessionId,
        turnNumber,
        errorType: 'transient_exhausted',
        errorMessage: lastError?.message || 'Unavailable',
      })}`,
    );

    // Optional Gemini fallback model (sequential, configuration-driven)
    if (config.ai.fallbackModel && config.ai.fallbackModel !== primaryModel) {
      console.log(
        `[AIOrchestrator] Primary model ${primaryModel} exhausted retries. Attempting fallback model: ${config.ai.fallbackModel}`,
      );
      try {
        const fallbackStart = Date.now();
        const fallbackResponse = await this.executeWithTimeout(
          (signal) =>
            primaryProvider.executeStructured<T>({
              model: config.ai.fallbackModel,
              prompt,
              geminiSchema,
              openAISchema,
              schemaName,
              temperature,
              thinkingLevel: thinkingLevel ?? undefined,
              maxOutputTokens,
              timeoutMs,
              abortSignal: signal,
            }),
          timeoutMs,
          `${operation}:fallback:${config.ai.fallbackModel}`,
        );

        primaryBreaker?.recordSuccess();
        const totalLatencyMs = Date.now() - totalStartTime;

        this.emitTelemetry({
          operation,
          provider: primaryProviderId,
          model: config.ai.fallbackModel,
          promptBuildMs,
          aiLatencyMs: Date.now() - fallbackStart,
          latencyMs: totalLatencyMs,
          totalLatencyMs,
          attemptCount: maxRetries + 2,
          retryCount,
          cacheHit: false,
          tokenUsage: fallbackResponse.tokenUsage,
          sessionId,
          turnNumber,
        });

        return {
          data: fallbackResponse.data,
          metadata: {
            requestId,
            operation,
            provider: primaryProviderId,
            model: config.ai.fallbackModel,
            circuitState: primaryBreaker?.getHealth().circuitState || 'CLOSED',
            latencyMs: totalLatencyMs,
            fallbackUsed: true,
            fallbackReason: `Primary model ${primaryModel} exhausted retries`,
            attemptCount: maxRetries + 2,
            promptBuildMs,
            aiLatencyMs: Date.now() - fallbackStart,
            tokenUsage: fallbackResponse.tokenUsage,
          },
        };
      } catch (fallbackErr: any) {
        console.error(
          `[AIOrchestrator] Fallback model ${config.ai.fallbackModel} also failed: ${fallbackErr?.message || 'Unavailable'}`,
        );
      }
    }

    // All retries exhausted — emit final telemetry and throw controlled error
    const totalLatencyMs = Date.now() - totalStartTime;
    this.emitTelemetry({
      operation,
      provider: primaryProviderId,
      model: primaryModel,
      promptBuildMs,
      latencyMs: totalLatencyMs,
      totalLatencyMs,
      attemptCount: maxRetries + 1,
      retryCount,
      cacheHit: false,
      retryReason: lastRetryReason,
      sessionId,
      turnNumber,
    });

    throw new AppError(
      'The AI interview service is currently experiencing high demand. Please try again in a moment.',
      503,
      'AI_SERVICE_UNAVAILABLE',
    );
  }

  /**
   * Safely extract a Retry-After delay in milliseconds from a provider error.
   * Returns undefined when no actionable header is present.
   */
  private extractRetryAfterMs(err: any): number | undefined {
    try {
      const retryAfterHeader =
        err?.headers?.['retry-after'] ||
        err?.error?.headers?.['retry-after'] ||
        err?.response?.headers?.['retry-after'];

      if (!retryAfterHeader) return undefined;

      const seconds = parseInt(String(retryAfterHeader), 10);
      if (!isNaN(seconds) && seconds > 0 && seconds < 120) {
        // Cap at 2 minutes to avoid blocking the request indefinitely
        return seconds * 1000;
      }
    } catch {
      // Ignore errors in header extraction
    }
    return undefined;
  }

  // ==========================================================
  // SANITIZATION HELPERS
  // ==========================================================

  private enforceSingleQuestion(rawQuestion: string, fallback: string): string {
    let q = (rawQuestion || '').trim().replace(/^[\"']|[\"']$/g, '');
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

    const promptStart = Date.now();
    const prompt = buildInterviewPlanPrompt(params);
    const promptBuildMs = Date.now() - promptStart;

    try {
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
        thinkingLevel: config.ai.liveThinkingLevel,
        maxOutputTokens: PLAN_MAX_OUTPUT_TOKENS,
        promptBuildMs,
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
    } catch (err: any) {
      if (
        err instanceof AppError &&
        (err.code === 'AI_SERVICE_UNAVAILABLE' || err.code === 'AI_CIRCUIT_OPEN')
      ) {
        console.warn(
          `[AIOrchestrator] Gracefully degrading generateInterviewPlan due to ${err.code}: using fallback welcome question.`,
        );
        const defaultFirstQ = `Welcome! Could you introduce yourself and share your background as a ${role.trim()}?`;
        return {
          data: { topics: [], firstQuestion: defaultFirstQ },
          metadata: {
            requestId: randomUUID(),
            operation: 'plan',
            provider: config.ai.livePrimaryProvider,
            model: config.ai.livePrimaryModel,
            circuitState:
              this.circuitBreakers.get(config.ai.livePrimaryProvider)?.getHealth().circuitState || 'OPEN',
            latencyMs: Date.now() - promptStart,
            fallbackUsed: false,
            attemptCount: 1,
            degraded: true,
          },
        };
      }
      throw err;
    }
  }

  async generateInterviewPlan(params: InterviewPlanParams): Promise<InterviewBlueprint> {
    const res = await this.generateInterviewPlanWithMeta(params);
    return res.data;
  }

  // ==========================================================
  // STAGE 2: LIVE ADAPTIVE CONVERSATIONAL TURN
  // ==========================================================

  async getNextConversationalTurnWithMeta(
    params: ConversationalTurnParams & { sessionId?: string },
  ): Promise<AIExecutionResult<ConversationalTurn>> {
    const promptStart = Date.now();
    const { prompt, currentTurn, totalMaxTurns } = buildConversationalTurnPrompt(params);
    const promptBuildMs = Date.now() - promptStart;

    try {
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
        thinkingLevel: config.ai.liveThinkingLevel,
        maxOutputTokens: TURN_MAX_OUTPUT_TOKENS,
        promptBuildMs,
        sessionId: params.sessionId,
        turnNumber: params.turnNumber,
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
    } catch (err: any) {
      if (
        err instanceof AppError &&
        (err.code === 'AI_SERVICE_UNAVAILABLE' || err.code === 'AI_CIRCUIT_OPEN')
      ) {
        console.warn(
          `[AIOrchestrator] Gracefully degrading getNextConversationalTurn due to ${err.code}: turn=${currentTurn}/${totalMaxTurns}.`,
        );
        const isFinalClosingTurn = currentTurn >= totalMaxTurns;
        const action: 'continue_topic' | 'new_topic' | 'end_interview' = isFinalClosingTurn
          ? 'end_interview'
          : 'new_topic';

        const fallbackQuestion = isFinalClosingTurn
          ? "Thank you for sharing your experience. We'll conclude the interview here!"
          : `Could you tell me more about your experience as a ${params.role}?`;

        const fallbackTopic =
          (params.areasExplored && params.areasExplored.length > 0
            ? params.areasExplored[params.areasExplored.length - 1]
            : undefined) || 'Role Competency';

        return {
          data: {
            acknowledgement: 'Got it.',
            action,
            nextQuestion: fallbackQuestion,
            nextTopic: fallbackTopic,
            conversationSummary: params.conversationSummary || 'Interview in progress.',
          },
          metadata: {
            requestId: randomUUID(),
            operation: 'live_turn',
            provider: config.ai.livePrimaryProvider,
            model: config.ai.livePrimaryModel,
            circuitState:
              this.circuitBreakers.get(config.ai.livePrimaryProvider)?.getHealth().circuitState || 'OPEN',
            latencyMs: Date.now() - promptStart,
            fallbackUsed: false,
            attemptCount: 1,
            degraded: true,
          },
        };
      }
      throw err;
    }
  }

  async getNextConversationalTurn(
    params: ConversationalTurnParams & { sessionId?: string },
  ): Promise<ConversationalTurn> {
    const res = await this.getNextConversationalTurnWithMeta(params);
    return res.data;
  }

  // ==========================================================
  // STAGE 3: DEEP FINAL EVALUATION
  // ==========================================================

  async generateFinalEvaluationWithMeta(
    params: FinalEvaluationParams & { sessionId?: string },
  ): Promise<AIExecutionResult<FinalInterviewEvaluation>> {
    if (!params.transcript || params.transcript.length === 0) {
      throw new Error('Interview transcript is required');
    }

    const promptStart = Date.now();
    const prompt = buildFinalEvaluationPrompt(params);
    const promptBuildMs = Date.now() - promptStart;

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
      maxOutputTokens: EVAL_MAX_OUTPUT_TOKENS,
      promptBuildMs,
      sessionId: params.sessionId,
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
    params: FinalEvaluationParams & { sessionId?: string },
  ): Promise<FinalInterviewEvaluation> {
    const res = await this.generateFinalEvaluationWithMeta(params);
    return res.data;
  }
}

// ============================================================
// SINGLETON INSTANCE
// ============================================================

export const aiOrchestrator = new AIOrchestrator();
