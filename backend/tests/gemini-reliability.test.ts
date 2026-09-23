import { aiOrchestrator } from '../src/services/ai/ai.orchestrator';
import { GeminiProvider } from '../src/services/ai/providers/gemini.provider';
import { CircuitBreaker } from '../src/services/ai/circuit-breaker';
import { AppError } from '../src/errors/AppError';

describe('Gemini Latency + 503 Reliability Optimization', () => {
  let mockGeminiExecute: jest.SpyInstance;
  let geminiProvider: GeminiProvider;
  let circuitBreaker: CircuitBreaker;

  const mockLiveResponse = {
    acknowledgement: 'Understood.',
    action: 'new_topic' as const,
    nextQuestion: 'Can you explain the widget lifecycle in Flutter?',
    nextTopic: 'Flutter Widgets',
    conversationSummary: 'Candidate answered initial question on Flutter.',
  };

  const mockTokenUsage = {
    inputTokens: 350,
    outputTokens: 48,
    totalTokens: 398,
  };

  const baseTurnParams = {
    role: 'Flutter Developer',
    previousQuestion: 'What is a StatelessWidget?',
    candidateAnswer: 'It is a widget that does not require mutable state.',
    conversationSummary: 'Interview in progress.',
    areasExplored: ['Introduction'],
    followUpsUsed: 0,
    turnNumber: 2,
    maxTurns: 8,
  };

  beforeEach(() => {
    jest.setTimeout(15000);
    jest.clearAllMocks();

    // Access the registered Gemini provider and circuit breaker on the singleton
    geminiProvider = (aiOrchestrator as any).providers.get('gemini');
    circuitBreaker = (aiOrchestrator as any).circuitBreakers.get('gemini');

    // Reset circuit breaker state before each test
    circuitBreaker.recordSuccess();

    // Mock executeStructured on GeminiProvider
    mockGeminiExecute = jest.spyOn(geminiProvider, 'executeStructured');

    // Ensure isConfigured returns true
    jest.spyOn(geminiProvider, 'isConfigured').mockReturnValue(true);
  });

  afterEach(() => {
    mockGeminiExecute.mockRestore();
  });

  it('1. Gemini 503 on first attempt should retry and succeed on second attempt (exactly 2 attempts)', async () => {
    const error503 = Object.assign(new Error('503 Service Unavailable: The model is overloaded.'), {
      status: 503,
      statusCode: 503,
    });

    mockGeminiExecute
      .mockRejectedValueOnce(error503)
      .mockResolvedValueOnce({
        data: mockLiveResponse,
        tokenUsage: mockTokenUsage,
      });

    const result = await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
    });

    expect(mockGeminiExecute).toHaveBeenCalledTimes(2);
    expect(result.nextQuestion).toBe('Can you explain the widget lifecycle in Flutter?');
    // Circuit breaker should be closed (healthy) after successful retry
    expect(circuitBreaker.getHealth().circuitState).toBe('CLOSED');
  });

  it('2. Gemini 503 on live turn gracefully degrades with degraded: true after strictly 2 attempts, while evaluation throws normally', async () => {
    const error503 = Object.assign(new Error('503 Service Unavailable: High demand spikes.'), {
      status: 503,
      statusCode: 503,
    });

    mockGeminiExecute.mockRejectedValue(error503);

    // Live turn should gracefully degrade instead of breaking the interview
    const result = await aiOrchestrator.getNextConversationalTurnWithMeta({
      ...baseTurnParams,
    });

    // 2 attempts on primary model + 1 attempt on fallback model
    expect(mockGeminiExecute).toHaveBeenCalledTimes(3);
    expect(result.metadata.degraded).toBe(true);
    expect(result.data.nextQuestion).toContain('experience as a Flutter Developer');
    expect(result.data.action).toBe('new_topic');
    // Circuit breaker failure count should be incremented once for the logical operation
    expect(circuitBreaker.getHealth().consecutiveFailures).toBe(1);

    // Final evaluation must NOT degrade with fabricated data — it should throw 503
    await expect(
      aiOrchestrator.generateFinalEvaluation({
        role: 'Flutter Developer',
        transcript: [{ question: 'Q1', answer: 'A1', topic: 'Flutter', type: 'primary' }],
      }),
    ).rejects.toThrow(AppError);
  });

  it('3. Gemini 429 quota error should be classified as transient and retried with capped backoff', async () => {
    const error429 = Object.assign(new Error('429 Resource has been exhausted: quota exceeded.'), {
      status: 429,
      headers: { 'retry-after': '1' },
    });

    mockGeminiExecute
      .mockRejectedValueOnce(error429)
      .mockResolvedValueOnce({
        data: mockLiveResponse,
        tokenUsage: mockTokenUsage,
      });

    const result = await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
      previousQuestion: 'What is Provider?',
      candidateAnswer: 'A state management wrapper around InheritedWidget.',
    });

    expect(mockGeminiExecute).toHaveBeenCalledTimes(2);
    expect(result.nextTopic).toBe('Flutter Widgets');
  });

  it('4. Gemini 400 / 401 permanent error should fail-fast with NO retry (exactly 1 attempt)', async () => {
    const error401 = Object.assign(new Error('API key not valid. Please pass a valid API key.'), {
      status: 401,
      statusCode: 401,
    });

    mockGeminiExecute.mockRejectedValue(error401);

    await expect(
      aiOrchestrator.getNextConversationalTurn({
        ...baseTurnParams,
      }),
    ).rejects.toThrow('AI service error');

    // Exactly 1 attempt — no retries for permanent errors
    expect(mockGeminiExecute).toHaveBeenCalledTimes(1);
  });

  it('5. Request timeout tags error with status 504 and isTimeout: true, enabling retry', async () => {
    // 5a. Verify executeWithTimeout rejects with status 504 and isTimeout
    let caughtErr: any;
    try {
      await (aiOrchestrator as any).executeWithTimeout(
        async (signal?: AbortSignal) => {
          await new Promise((resolve, reject) => {
            const timer = setTimeout(resolve, 500);
            signal?.addEventListener('abort', () => {
              clearTimeout(timer);
              reject(new Error('Aborted'));
            });
          });
        },
        30,
        'test-timeout',
      );
    } catch (err: any) {
      caughtErr = err;
    }

    expect(caughtErr).toBeDefined();
    expect(caughtErr.message).toContain('timed out after 30ms');
    expect(caughtErr.status).toBe(504);
    expect(caughtErr.statusCode).toBe(504);
    expect(caughtErr.isTimeout).toBe(true);

    // 5b. Verify timeout error is classified as transient by circuit-breaker helper
    const { isTransientError } = require('../src/services/ai/circuit-breaker');
    expect(isTransientError(caughtErr)).toBe(true);

    // 5c. Verify timeout on first attempt is retried and succeeds on second attempt
    mockGeminiExecute
      .mockImplementationOnce(async () => {
        const timeoutErr = Object.assign(new Error('[AIOrchestrator] test timed out'), {
          status: 504,
          statusCode: 504,
          isTimeout: true,
        });
        throw timeoutErr;
      })
      .mockResolvedValueOnce({
        data: mockLiveResponse,
        tokenUsage: mockTokenUsage,
      });

    const turnRes = await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
    });

    expect(mockGeminiExecute).toHaveBeenCalledTimes(2);
    expect(turnRes.nextQuestion).toBe('Can you explain the widget lifecycle in Flutter?');
  });

  it('6. Circuit breaker OPEN state immediately skips Gemini: live turns degrade gracefully, evaluations throw fast', async () => {
    const error503 = Object.assign(new Error('503 Service Unavailable'), { status: 503 });

    // Manually trip the circuit breaker by recording failures up to threshold (3)
    circuitBreaker.recordFailure(error503);
    circuitBreaker.recordFailure(error503);
    circuitBreaker.recordFailure(error503);

    expect(circuitBreaker.canExecute()).toBe(false);
    expect(circuitBreaker.getHealth().circuitState).toBe('OPEN');

    // Live turn when circuit is OPEN degrades gracefully without calling Gemini
    const degradedTurn = await aiOrchestrator.getNextConversationalTurnWithMeta({
      ...baseTurnParams,
    });

    expect(mockGeminiExecute).toHaveBeenCalledTimes(0);
    expect(degradedTurn.metadata.degraded).toBe(true);
    expect(degradedTurn.data.nextQuestion).toContain('experience as a Flutter Developer');

    // Evaluation when circuit is OPEN throws fast without fabricating scores
    await expect(
      aiOrchestrator.generateFinalEvaluation({
        role: 'Flutter Developer',
        transcript: [{ question: 'Q1', answer: 'A1', topic: 'Flutter', type: 'primary' }],
      }),
    ).rejects.toThrow('The AI interview service is temporarily unavailable.');

    expect(mockGeminiExecute).toHaveBeenCalledTimes(0);
  });

  it('7. Circuit breaker in HALF_OPEN state recovers to CLOSED on successful request', () => {
    const error503 = Object.assign(new Error('503 Service Unavailable'), { status: 503 });
    circuitBreaker.recordFailure(error503);
    circuitBreaker.recordFailure(error503);
    circuitBreaker.recordFailure(error503);

    expect(circuitBreaker.getHealth().circuitState).toBe('OPEN');

    // Simulate cooldown elapsed
    (circuitBreaker as any).cooldownUntil = Date.now() - 1000;
    expect(circuitBreaker.canExecute()).toBe(true);
    expect(circuitBreaker.getHealth().circuitState).toBe('HALF_OPEN');

    // Successful request probe closes the circuit
    circuitBreaker.recordSuccess();
    expect(circuitBreaker.getHealth().circuitState).toBe('CLOSED');
    expect(circuitBreaker.getHealth().consecutiveFailures).toBe(0);
  });

  it('8. Live conversational turns should pass thinkingLevel: "low"', async () => {
    mockGeminiExecute.mockResolvedValueOnce({
      data: mockLiveResponse,
      tokenUsage: mockTokenUsage,
    });

    await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
    });

    expect(mockGeminiExecute).toHaveBeenCalledTimes(1);
    const callArgs = mockGeminiExecute.mock.calls[0][0];
    expect(callArgs.thinkingLevel).toBe('low');
  });

  it('9. Output token budgets should be 320 for live turns and 150 for plan', async () => {
    // 1. Live Turn Budget
    mockGeminiExecute.mockResolvedValueOnce({
      data: mockLiveResponse,
      tokenUsage: mockTokenUsage,
    });

    await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
    });

    expect(mockGeminiExecute.mock.calls[0][0].maxOutputTokens).toBe(320);

    // 2. Plan Budget
    mockGeminiExecute.mockResolvedValueOnce({
      data: { firstQuestion: 'Welcome! Can you share your background in Flutter?' },
      tokenUsage: { inputTokens: 120, outputTokens: 18, totalTokens: 138 },
    });

    await aiOrchestrator.generateInterviewPlan({
      role: 'Flutter Developer',
    });

    expect(mockGeminiExecute.mock.calls[1][0].maxOutputTokens).toBe(150);
  });

  it('10. Token usage from provider should be captured in metadata and emitted in telemetry', async () => {
    mockGeminiExecute.mockResolvedValueOnce({
      data: mockLiveResponse,
      tokenUsage: {
        inputTokens: 420,
        outputTokens: 75,
        totalTokens: 495,
      },
    });

    const resultWithMeta = await aiOrchestrator.getNextConversationalTurnWithMeta({
      ...baseTurnParams,
      sessionId: 'session-telemetry-test',
    });

    expect(resultWithMeta.metadata.tokenUsage).toEqual({
      inputTokens: 420,
      outputTokens: 75,
      totalTokens: 495,
    });
    expect(resultWithMeta.metadata.provider).toBe('gemini');
  });

  it('11. Works seamlessly in Gemini-only environment without OpenAI credentials', async () => {
    // Ensure OpenAI provider being unconfigured does not break Gemini orchestrator
    const openAIProvider = (aiOrchestrator as any).providers.get('openai');
    jest.spyOn(openAIProvider, 'isConfigured').mockReturnValue(false);

    mockGeminiExecute.mockResolvedValueOnce({
      data: mockLiveResponse,
      tokenUsage: mockTokenUsage,
    });

    const result = await aiOrchestrator.getNextConversationalTurn({
      ...baseTurnParams,
      role: 'Backend Engineer',
    });

    expect(result.nextQuestion).toBeDefined();
    expect(mockGeminiExecute).toHaveBeenCalledTimes(1);
  });

  it('12. Interview plan gracefully degrades with welcome question when Gemini is unavailable', async () => {
    const error503 = Object.assign(new Error('503 Service Unavailable: High demand.'), {
      status: 503,
      statusCode: 503,
    });

    mockGeminiExecute.mockRejectedValue(error503);

    const planRes = await aiOrchestrator.generateInterviewPlanWithMeta({
      role: 'Flutter Developer',
    });

    // 2 attempts on primary model + 1 attempt on fallback model
    expect(mockGeminiExecute).toHaveBeenCalledTimes(3);
    expect(planRes.metadata.degraded).toBe(true);
    expect(planRes.data.firstQuestion).toContain('introduce yourself and share your background as a Flutter Developer');
  });
});

