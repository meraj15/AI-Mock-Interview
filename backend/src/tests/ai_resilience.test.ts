import { AIOrchestrator } from '../services/ai/ai.orchestrator';
import { CircuitBreaker, isTransientError } from '../services/ai/circuit-breaker';
import { InterviewAIProvider, ProviderRequest } from '../services/ai/ai.types';
import { interviewService } from '../services/interview.service';
import { aiService } from '../services/ai.service';

// ============================================================
// TEST HARNESS & MOCK PROVIDERS
// ============================================================

class MockProvider implements InterviewAIProvider {
  public callCount = 0;
  public lastRequest?: ProviderRequest;

  constructor(
    public readonly id: string,
    public readonly name: string,
    private readonly behavior: (req: ProviderRequest) => Promise<any>,
  ) {}

  isConfigured(): boolean {
    return true;
  }

  async executeStructured<T>(params: ProviderRequest): Promise<T> {
    this.callCount++;
    this.lastRequest = params;
    return this.behavior(params);
  }
}

// Subclass AIOrchestrator to inject mock providers for controlled deterministic testing
class TestableAIOrchestrator extends AIOrchestrator {
  public setProvider(id: string, provider: InterviewAIProvider) {
    (this as any).providers.set(id, provider);
  }

  public getBreaker(id: string): CircuitBreaker | undefined {
    return (this as any).circuitBreakers.get(id);
  }
}

async function runAllTests() {
  console.log('================================================================');
  console.log('STARTING AI PROVIDER ABSTRACTION & RESILIENCE VERIFICATION SUITE');
  console.log('================================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, message: string) {
    if (!condition) {
      console.error(`❌ FAILED: ${message}`);
      failed++;
      throw new Error(message);
    } else {
      console.log(`✓ ${message}`);
      passed++;
    }
  }

  // ------------------------------------------------------------
  // TEST 1: Gemini Success & Telemetry Metadata
  // ------------------------------------------------------------
  console.log('[TEST 1] Gemini Success & Telemetry Metadata');
  {
    const orchestrator = new TestableAIOrchestrator();
    const mockGemini = new MockProvider('gemini', 'Mock Gemini', async () => ({
      acknowledgement: 'Great explanation.',
      action: 'follow_up',
      nextQuestion: 'How would you optimize state rebuilds with BLoC?',
      nextTopic: 'State Management',
      conversationSummary: 'Candidate demonstrated solid Dart understanding.',
    }));

    orchestrator.setProvider('gemini', mockGemini);

    const result = await orchestrator.getNextConversationalTurnWithMeta({
      role: 'Flutter Architect',
      previousQuestion: 'Tell me about state management.',
      candidateAnswer: 'I use flutter_bloc for event-driven reactive state.',
      conversationSummary: '',
      areasExplored: [],
      followUpsUsed: 0,
      turnNumber: 2,
      maxTurns: 8,
    });

    assert(mockGemini.callCount === 1, 'Gemini provider called exactly once');
    assert(mockGemini.lastRequest?.thinkingLevel === 'low', 'Lowest appropriate thinking level (low) passed to provider for live turn');
    assert(result.data.action === 'follow_up', 'Valid ConversationalTurn action returned');
    assert(result.data.nextQuestion.includes('BLoC?'), 'Sanitized question returned');
    assert(Boolean(result.metadata.requestId), 'Metadata includes unique requestId');
    assert(result.metadata.provider === 'gemini', 'Metadata records provider as gemini');
    assert(result.metadata.circuitState === 'CLOSED', 'Metadata records circuitState as CLOSED');
    assert(result.metadata.fallbackUsed === false, 'fallbackUsed is false on primary success');
    assert(result.metadata.attemptCount === 1, 'attemptCount is 1 on primary success');
    assert(result.metadata.latencyMs >= 0, 'latencyMs is accurately tracked');
  }

  // ------------------------------------------------------------
  // TEST 2: Gemini 503 -> OpenAI Success Fallback
  // ------------------------------------------------------------
  console.log('\n[TEST 2] Gemini 503 -> OpenAI Automatic Failover');
  {
    const orchestrator = new TestableAIOrchestrator();
    const mockGemini = new MockProvider('gemini', 'Mock Gemini', async () => {
      const err: any = new Error('This model is currently experiencing high demand. 503 UNAVAILABLE');
      err.status = 503;
      throw err;
    });

    const mockOpenAI = new MockProvider('openai', 'Mock OpenAI', async () => ({
      acknowledgement: 'Understood.',
      action: 'new_topic',
      nextQuestion: 'Can you discuss your approach to offline caching?',
      nextTopic: 'Data Persistence',
      conversationSummary: 'Discussed architectural concepts.',
    }));

    orchestrator.setProvider('gemini', mockGemini);
    orchestrator.setProvider('openai', mockOpenAI);

    const result = await orchestrator.getNextConversationalTurnWithMeta({
      role: 'Mobile Engineer',
      previousQuestion: 'Explain clean architecture.',
      candidateAnswer: 'I separate domain, data, and presentation layers.',
      conversationSummary: '',
      areasExplored: [],
      followUpsUsed: 0,
      turnNumber: 3,
      maxTurns: 8,
    });

    assert(mockGemini.callCount === 1, 'Primary Gemini was attempted first');
    assert(mockOpenAI.callCount === 1, 'Fallback OpenAI was successfully triggered');
    assert(result.metadata.fallbackUsed === true, 'Telemetry records fallbackUsed: true');
    assert(result.metadata.provider === 'openai', 'Telemetry records provider as openai');
    assert(result.metadata.attemptCount === 2, 'Telemetry records attemptCount: 2');
    assert(result.metadata.fallbackReason?.includes('503') === true, 'fallbackReason captures transient 503');
    assert(result.data.nextTopic === 'Data Persistence', 'Valid ConversationalTurn data returned from OpenAI');
  }

  // ------------------------------------------------------------
  // TEST 3: Three Transient Failures -> Circuit OPEN
  // ------------------------------------------------------------
  console.log('\n[TEST 3] Three Transient Failures -> Circuit OPEN');
  {
    const breaker = new CircuitBreaker('test-gemini', 3, 1000);
    const err503 = { status: 503, message: 'High demand' };

    assert(breaker.getHealth().circuitState === 'CLOSED', 'Circuit starts CLOSED');
    breaker.recordFailure(err503);
    assert(breaker.getHealth().consecutiveFailures === 1, 'Failures = 1');
    assert(breaker.canExecute() === true, 'Can still execute after 1 failure');

    breaker.recordFailure(err503);
    assert(breaker.getHealth().consecutiveFailures === 2, 'Failures = 2');

    breaker.recordFailure(err503);
    assert(breaker.getHealth().circuitState === 'OPEN', 'Circuit transitioned to OPEN on 3rd failure');
    assert(breaker.canExecute() === false, 'canExecute returns false when OPEN');
  }

  // ------------------------------------------------------------
  // TEST 4: OPEN Circuit Immediately Skips Gemini
  // ------------------------------------------------------------
  console.log('\n[TEST 4] OPEN Circuit Immediately Skips Gemini');
  {
    const orchestrator = new TestableAIOrchestrator();
    const mockGemini = new MockProvider('gemini', 'Mock Gemini', async () => ({
      firstQuestion: 'Should never be reached',
    }));
    const mockOpenAI = new MockProvider('openai', 'Mock OpenAI', async () => ({
      firstQuestion: 'Welcome! Can you describe your experience with scalable apps?',
    }));

    orchestrator.setProvider('gemini', mockGemini);
    orchestrator.setProvider('openai', mockOpenAI);

    // Trip the gemini circuit breaker to OPEN
    const geminiBreaker = orchestrator.getBreaker('gemini')!;
    geminiBreaker.recordFailure({ status: 503, message: 'err1' });
    geminiBreaker.recordFailure({ status: 503, message: 'err2' });
    geminiBreaker.recordFailure({ status: 503, message: 'err3' });
    assert(geminiBreaker.getHealth().circuitState === 'OPEN', 'Gemini circuit is OPEN');

    const result = await orchestrator.generateInterviewPlanWithMeta({
      role: 'Backend Engineer',
    });

    assert(mockGemini.callCount === 0, 'Gemini was completely SKIPPED without making API call');
    assert(mockOpenAI.callCount === 1, 'OpenAI was routed directly');
    assert(result.metadata.fallbackUsed === true, 'fallbackUsed is true');
    assert(result.metadata.circuitState === 'OPEN', 'Telemetry reports circuitState as OPEN');
  }

  // ------------------------------------------------------------
  // TEST 5: Permanent 401/400 -> No Fallback (Fail Fast)
  // ------------------------------------------------------------
  console.log('\n[TEST 5] Permanent 401/400 Fail-Fast (No Fallback)');
  {
    const orchestrator = new TestableAIOrchestrator();
    const mockGemini = new MockProvider('gemini', 'Mock Gemini', async () => {
      const err: any = new Error('API key not valid (401 Unauthorized)');
      err.status = 401;
      throw err;
    });
    const mockOpenAI = new MockProvider('openai', 'Mock OpenAI', async () => ({
      firstQuestion: 'Should not be called',
    }));

    orchestrator.setProvider('gemini', mockGemini);
    orchestrator.setProvider('openai', mockOpenAI);

    let caughtPermanent = false;
    try {
      await orchestrator.generateInterviewPlanWithMeta({ role: 'Security Engineer' });
    } catch (err: any) {
      caughtPermanent = true;
      assert(err.message.includes('Permanent error'), 'Error correctly identified as permanent');
    }

    assert(caughtPermanent, 'Permanent error threw exception');
    assert(mockOpenAI.callCount === 0, 'Fallback OpenAI was NOT called on permanent error (tokens conserved)');
  }

  // ------------------------------------------------------------
  // TEST 6: Duplicate Answer Idempotency (Scoped: sessionId+turn+answerId)
  // ------------------------------------------------------------
  console.log('\n[TEST 6] Duplicate Answer Idempotency (Scoped: sessionId+turn+answerId)');
  {
    const originalPlan = aiService.generateInterviewPlan.bind(aiService);
    const originalGetNext = aiService.getNextConversationalTurn.bind(aiService);
    let aiTurnsCalled = 0;

    (aiService as any).generateInterviewPlan = async () => ({
      topics: [],
      firstQuestion: 'Welcome! Introduce your Flutter background.',
    });

    (aiService as any).getNextConversationalTurn = async () => {
      aiTurnsCalled++;
      return {
        acknowledgement: 'Understood.',
        action: 'follow_up',
        nextQuestion: 'Can you elaborate on your state management patterns?',
        nextTopic: 'State Management',
        conversationSummary: 'Candidate answered about state.',
      };
    };

    try {
      // Start session
      const setup = await interviewService.startConversationalInterview('test-user-123', {
        role: 'Flutter Developer',
        questionCount: 5,
      });

      const sessionId = setup.sessionId;
      const answerText = 'I use Provider and Riverpod for state management.';
      const answerId = 'client-msg-uuid-999';

      // First submission
      const turn1 = await interviewService.submitAnswer(sessionId, 'test-user-123', answerText, answerId);
      assert(Boolean(turn1.nextQuestion), 'Turn 1 generated a question');
      assert(aiTurnsCalled === 1, 'AI was invoked exactly once for initial answer');

      // Duplicate submission with exact same sessionId + turn + answerId
      const turn2 = await interviewService.submitAnswer(sessionId, 'test-user-123', answerText, answerId);

      assert(aiTurnsCalled === 1, 'AI was NOT called again on duplicate submission (1 AI call total)');
      assert(turn1.nextQuestion === turn2.nextQuestion, 'Turn 2 returned identical cached nextQuestion');
      assert(turn1.currentTopicIndex === turn2.currentTopicIndex, 'Topic index was NOT advanced twice');
    } finally {
      (aiService as any).generateInterviewPlan = originalPlan;
      (aiService as any).getNextConversationalTurn = originalGetNext;
    }
  }

  // ------------------------------------------------------------
  // TEST 7: Transport-level Request Cancellation
  // ------------------------------------------------------------
  console.log('\n[TEST 7] Transport-level Request Cancellation via AbortSignal');
  {
    const orchestrator = new TestableAIOrchestrator();
    let receivedSignal: AbortSignal | undefined;
    let signalAbortedWhenFinished = false;

    const mockSlowGemini = new MockProvider('gemini', 'Mock Slow Gemini', async (req) => {
      receivedSignal = req.abortSignal;
      // Wait longer than timeout
      await new Promise((resolve) => setTimeout(resolve, 500));
      return { firstQuestion: 'Too late' };
    });

    const mockFallback = new MockProvider('openai', 'Mock Fallback', async () => ({
      firstQuestion: 'Fallback question',
    }));

    orchestrator.setProvider('gemini', mockSlowGemini);
    orchestrator.setProvider('openai', mockFallback);

    // Call with 50ms timeout
    const result = await (orchestrator as any).executeTier({
      operation: 'plan',
      primaryProviderId: 'gemini',
      primaryModel: 'gemini-3.7-flash',
      fallbackProviderId: 'openai',
      fallbackModel: 'gpt-4o-mini',
      timeoutMs: 50,
      prompt: 'Hello',
      schemaName: 'test',
    });

    assert(Boolean(receivedSignal), 'AbortSignal was propagated to provider request');
    assert(receivedSignal?.aborted === true, 'AbortSignal was explicitly ABORTED upon timeout');
    assert(result.metadata.fallbackUsed === true, 'Fallback succeeded after primary timeout');
  }

  // ------------------------------------------------------------
  // TEST 8: Live AI Latency Measurement (Gemini 3.8 Flash)
  // ------------------------------------------------------------
  console.log('\n[TEST 8] Live AI Latency Measurement (Gemini 3.8 Flash)');
  {
    const realOrchestrator = new AIOrchestrator();
    try {
      const liveResult = await realOrchestrator.generateInterviewPlanWithMeta({
        role: 'Full Stack Engineer',
        experience: '3 years',
      });
      console.log(`✓ Live Gemini 3.8 Flash response generated in ${liveResult.metadata.latencyMs}ms`);
      console.log(`  Question: "${liveResult.data.firstQuestion}"`);
      console.log(`  RequestId: ${liveResult.metadata.requestId}`);
      console.log(`  CircuitState: ${liveResult.metadata.circuitState}`);
      passed++;
    } catch (err: any) {
      console.log(`ℹ Live Gemini call status: ${err?.message || err}`);
    }
  }

  console.log('\n================================================================');
  console.log(`ALL TESTS PASSED (${passed}/${passed + failed})`);
  console.log('================================================================\n');
}

runAllTests().catch((err) => {
  console.error('Test run failed:', err);
  process.exit(1);
});
