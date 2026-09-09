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
  turnNumber?: number;
  maxTurns?: number;
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
}

export interface AIExecutionResult<T> {
  data: T;
  metadata: AIExecutionMetadata;
}

// ============================================================
// PROVIDER ABSTRACTION INTERFACES
// ============================================================

export interface ProviderRequest {
  model: string;
  prompt: string;
  geminiSchema?: any;
  openAISchema?: any;
  schemaName: string;
  temperature?: number;
  thinkingLevel?: 'minimal' | 'low' | 'medium' | 'high';
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

  executeStructured<T>(params: ProviderRequest): Promise<T>;
}
