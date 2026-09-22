// ============================================================
// DOMAIN TYPES FOR INTERVIEWS
// ============================================================

export interface InterviewTopic {
  name: string;
  objective: string;
}

export interface InterviewBlueprint {
  topics: InterviewTopic[];
  firstQuestion: string;
}

export interface ConversationalTurn {
  acknowledgement: string;
  action: 'follow_up' | 'new_topic' | 'end_interview';
  nextQuestion: string;
  nextTopic: string;
  conversationSummary: string;
}

export interface QuestionReview {
  question: string;
  answer: string;
  expectedAnswer?: string;
  feedback: string;
  score: number;
}

export interface FinalInterviewEvaluation {
  overallScore: number;
  performanceLevel:
    | 'Excellent'
    | 'Good'
    | 'Average'
    | 'Needs Improvement';
  summary: string;
  strengths: string[];
  areasToImprove: string[];
  skillPerformance: Record<string, number>;
  recommendations: string[];
  questionReviews: QuestionReview[];
}

export interface TranscriptEntry {
  question: string;
  answer: string;
  topic: string;
  type: 'primary' | 'follow_up';
  timestamp?: string;
}

// ============================================================
// PARAMETER TYPES
// ============================================================

export interface InterviewPlanParams {
  role: string;
  experience?: string;
  skills?: string[];
  questionCount?: number;
  previousQuestions?: string[];
}

export interface ConversationalTurnParams {
  role: string;
  experience?: string;
  skills?: string[];
  previousQuestion: string;
  candidateAnswer: string;
  conversationSummary: string;
  areasExplored: string[];
  followUpsUsed: number;
  recentQuestions?: string[];
  currentSessionQuestions?: string[];
  turnNumber?: number;
  maxTurns?: number;
  previousQuestions?: string[];
  previouslyCoveredTopics?: string[];
}

export interface FinalEvaluationParams {
  role: string;
  experience?: string;
  skills?: string[];
  transcript: TranscriptEntry[];
}

// ============================================================
// TELEMETRY & EXECUTION METADATA
// ============================================================

export type AIOperation = 'plan' | 'live_turn' | 'final_evaluation';

/**
 * Token usage from the AI provider.
 * Captured from provider response metadata where available (e.g. Gemini usageMetadata).
 * Never derived from prompt text (which may contain PII).
 */
export interface TokenUsage {
  /** Input/prompt tokens consumed. */
  inputTokens?: number;
  /** Output/completion tokens generated. */
  outputTokens?: number;
  /** Total tokens (input + output). */
  totalTokens?: number;
}

/**
 * Granular latency + cost telemetry emitted as structured [TELEMETRY] JSON log lines.
 * Never includes API keys, JWTs, passwords, full resumes, or sensitive personal data.
 */
export interface LatencyTelemetry {
  operation: AIOperation;
  provider: string;
  model: string;
  /** Wall-clock ms from first byte of request to last byte of parsed AI response. */
  latencyMs: number;
  attemptCount: number;
  cacheHit: boolean;
  /** ms spent constructing the prompt string before the AI call. */
  promptBuildMs?: number;
  /** ms the AI provider took to return (excludes prompt build and DB). */
  aiLatencyMs?: number;
  /** ms to parse/validate the structured JSON response. */
  parseMs?: number;
  /** ms spent on database persistence after AI response. */
  dbMs?: number;
  /** End-to-end ms for this operation (prompt → AI → parse → DB). */
  totalLatencyMs?: number;
  /** HTTP status/reason that triggered a retry, e.g. "503". */
  retryReason?: string;
  /** True when an existing cached/persisted result was returned without calling AI. */
  idempotencyHit?: boolean;
  /** sessionId for correlation (never contains PII). */
  sessionId?: string;
  /** Turn number for correlation. */
  turnNumber?: number;
  /** Token counts from provider response metadata. */
  tokenUsage?: TokenUsage;
  /** Number of retries beyond the first attempt. */
  retryCount?: number;
  /** Total previous questions known for user. */
  questionHistoryCount?: number;
  /** Previous questions/topics included in prompt context. */
  questionHistoryContextCount?: number;
  /** ms taken to query question history. */
  questionHistoryQueryMs?: number;
  /** True when a duplicate question was avoided. */
  duplicateAvoided?: boolean;
}

export interface AIExecutionMetadata {
  requestId: string;
  operation: AIOperation;
  provider: string;
  model: string;
  circuitState: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
  latencyMs: number;
  fallbackUsed: boolean;
  fallbackReason?: string;
  attemptCount: number;
  promptBuildMs?: number;
  aiLatencyMs?: number;
  parseMs?: number;
  tokenUsage?: TokenUsage;
}

export interface AIExecutionResult<T> {
  data: T;
  metadata: AIExecutionMetadata;
}

// ============================================================
// PROVIDER ABSTRACTION INTERFACES
// ============================================================

/**
 * Provider response envelope returned by executeStructured.
 * Wraps the parsed data with optional token usage metadata.
 */
export interface ProviderResponse<T> {
  data: T;
  tokenUsage?: TokenUsage;
}

export interface ProviderRequest {
  model: string;
  prompt: string;
  geminiSchema?: any;
  openAISchema?: any;
  schemaName: string;
  temperature?: number;
  thinkingLevel?: 'minimal' | 'low' | 'medium' | 'high';
  /** Hard limit on generated output tokens. Keep small for live turns to control cost. */
  maxOutputTokens?: number;
  timeoutMs?: number;
  abortSignal?: AbortSignal;
}

export interface ProviderHealth {
  healthy: boolean;
  consecutiveFailures: number;
  lastFailureAt?: number;
  cooldownUntil?: number;
  circuitState: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
}

export interface InterviewAIProvider {
  readonly id: string;
  readonly name: string;

  isConfigured(): boolean;

  /**
   * Execute a structured AI request and return parsed data + optional token usage.
   * The token usage is sourced from provider response metadata — never inferred from prompts.
   */
  executeStructured<T>(params: ProviderRequest): Promise<ProviderResponse<T>>;
}
