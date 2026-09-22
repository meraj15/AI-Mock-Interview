import { interviewService, ActiveConversationalSession } from '../src/services/interview.service';
import { aiService } from '../src/services/ai.service';
import { interviewRepository } from '../src/repositories/interview.repository';

// Mock dependencies
jest.mock('../src/services/ai.service', () => ({
  aiService: {
    generateFinalEvaluation: jest.fn(),
  },
}));

jest.mock('../src/repositories/interview.repository', () => ({
  interviewRepository: {
    findByIdWithQuestions: jest.fn(),
    createWithQuestions: jest.fn(),
  },
}));

jest.mock('../src/config/database', () => ({
  prisma: {},
}));

describe('InterviewService - In-Flight Evaluation Coalescing', () => {
  const sessionId = 'test-session-coalesce-123';
  const userId = 'user-test-123';

  const mockEvaluation = {
    overallScore: 85,
    performanceLevel: 'Good' as const,
    summary: 'Solid performance across the board.',
    strengths: ['Clear explanations', 'Strong fundamentals'],
    areasToImprove: ['Concurrency handling'],
    skillPerformance: { Flutter: 85 },
    questionReviews: [
      {
        question: 'What is Provider in Flutter?',
        answer: 'It is a wrapper around InheritedWidget.',
        expectedAnswer: 'State management solution based on InheritedWidget.',
        score: 85,
        feedback: 'Good answer.',
      },
    ],
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should coalesce concurrent getFinalResult calls into exactly ONE AI call and ONE DB write', async () => {
    // Setup active session in memory
    const session: ActiveConversationalSession = {
      id: sessionId,
      userId,
      role: 'Flutter Developer',
      skills: ['Flutter'],
      experience: '2 years',
      topics: [],
      currentTopicIndex: 0,
      totalTopics: 1,
      areasExplored: ['Flutter'],
      followUpsUsedForCurrentTopic: 0,
      totalTurns: 1,
      maxTurns: 1,
      conversationSummary: '',
      interactions: [
        {
          question: 'What is Provider in Flutter?',
          answer: 'It is a wrapper around InheritedWidget.',
          topic: 'Flutter',
          type: 'primary',
        },
      ],
      questionHistory: [],
      coveredTopics: [],
      status: 'in_progress',
      createdAt: new Date(),
      startedAt: Date.now() - 60000,
    };

    (interviewService as any).activeSessions.set(sessionId, session);

    // Mock DB not yet having the session
    (interviewRepository.findByIdWithQuestions as jest.Mock).mockResolvedValue(null);
    (interviewRepository.createWithQuestions as jest.Mock).mockResolvedValue({ id: sessionId });

    // Mock AI taking 50ms to simulate in-flight delay
    (aiService.generateFinalEvaluation as jest.Mock).mockImplementation(async () => {
      await new Promise((resolve) => setTimeout(resolve, 50));
      return mockEvaluation;
    });

    // Launch two concurrent getFinalResult calls simultaneously
    const [result1, result2] = await Promise.all([
      interviewService.getFinalResult(sessionId, userId),
      interviewService.getFinalResult(sessionId, userId),
    ]);

    // Both callers should receive the identical evaluation result
    expect(result1).toEqual(mockEvaluation);
    expect(result2).toEqual(mockEvaluation);

    // AI should have been called EXACTLY ONCE
    expect(aiService.generateFinalEvaluation).toHaveBeenCalledTimes(1);

    // DB should have been written to EXACTLY ONCE
    expect(interviewRepository.createWithQuestions).toHaveBeenCalledTimes(1);

    // Session status should be completed
    expect(session.status).toBe('completed');
    expect(session.inFlightEvaluation).toBeUndefined();
    expect(session.finalEvaluation).toEqual(mockEvaluation);

    // Subsequent call should hit in-memory cache with 0 AI calls
    const result3 = await interviewService.getFinalResult(sessionId, userId);
    expect(result3).toEqual(mockEvaluation);
    expect(aiService.generateFinalEvaluation).toHaveBeenCalledTimes(1);
  });
});
