import '../../features/interview/domain/entities/interview_config_entity.dart';
import '../../features/resume/domain/entities/resume_entity.dart';

class AIQuestionPrompt {
  final String primaryQuestion;
  final String followUpQuestion;
  final String category;
  final String contextHint;

  const AIQuestionPrompt({
    required this.primaryQuestion,
    required this.followUpQuestion,
    required this.category,
    required this.contextHint,
  });
}

class AIEvaluationResult {
  final int overallScore;
  final String performanceLabel;
  final Map<String, int> skillScores;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<String> recommendedTopics;
  final String summary;

  const AIEvaluationResult({
    required this.overallScore,
    required this.performanceLabel,
    required this.skillScores,
    required this.strengths,
    required this.areasToImprove,
    required this.recommendedTopics,
    required this.summary,
  });
}

abstract class AIInterviewService {
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  });

  Future<String> generateFollowUp({
    required String question,
    required String answer,
    required String role,
  });

  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  });
}

class MockAIInterviewService implements AIInterviewService {
  @override
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final skills = resume.skills.take(3).join(', ');

    return [
      AIQuestionPrompt(
        primaryQuestion:
            'Hi Meraj, welcome! I noticed $skills on your resume. Walk me through a key project where you architected these together.',
        followUpQuestion:
            'You described a solid architectural foundation. What was the most difficult technical trade-off you had to negotiate?',
        category: 'Project Architecture',
        contextHint: 'Take your time. A concrete example with metrics will make your answer stand out.',
      ),
      AIQuestionPrompt(
        primaryQuestion:
            'How did you approach state management in your application, and what criteria guided your selection?',
        followUpQuestion:
            'You chose Provider/Riverpod. How did you structure dependency injection and manage testability across modules?',
        category: 'Technical Knowledge',
        contextHint: 'Highlight separation of concerns and maintainability.',
      ),
      AIQuestionPrompt(
        primaryQuestion:
            'How do you engineer network resilience and API failure handling so the end user never experiences a broken state?',
        followUpQuestion:
            'How do you observe, track, and debug intermittent API exceptions in production?',
        category: 'Resilience & Debugging',
        contextHint: 'Explain graceful degradation and offline state handling.',
      ),
      AIQuestionPrompt(
        primaryQuestion:
            'Tell me about a situation where a critical deadline was at risk. How did you prioritize tasks and communicate with the team?',
        followUpQuestion:
            'If a stakeholder insisted on adding a high-risk feature right before launch, how would you respond?',
        category: 'Behavioral & Leadership',
        contextHint: 'Use the STAR method (Situation, Task, Action, Result).',
      ),
      AIQuestionPrompt(
        primaryQuestion:
            'If you were asked to design an offline-first mobile sync engine for ${config.role}, what core data structures would you use?',
        followUpQuestion:
            'How would you resolve concurrent write conflicts between local SQLite and backend PostgreSQL?',
        category: 'System Design',
        contextHint: 'Discuss conflict resolution strategies (e.g. CRDTs or timestamp vectors).',
      ),
    ];
  }

  @override
  Future<String> generateFollowUp({
    required String question,
    required String answer,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (answer.toLowerCase().contains('state') || answer.toLowerCase().contains('provider')) {
      return 'You mentioned your state management approach. How did you prevent unnecessary rebuilds in high-frequency streams?';
    }
    return 'That is a clear start. Can you dive deeper into how you measured performance and validated this in production?';
  }

  @override
  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    return const AIEvaluationResult(
      overallScore: 82,
      performanceLabel: 'Strong Performance',
      skillScores: {
        'Technical Knowledge': 86,
        'Communication & Clarity': 78,
        'Problem Solving': 84,
        'Confidence & Delivery': 75,
        'Role Knowledge': 88,
      },
      strengths: [
        'Strong grasp of Flutter core principles and clean architectural separation.',
        'Articulate explanation of real project workflows and API integration.',
        'Effective articulation of state management trade-offs.',
      ],
      areasToImprove: [
        'Go deeper on system design trade-offs and offline sync edge cases.',
        'Include measurable metrics and business impact in behavioral answers.',
        'Clarify production telemetry and observability strategies.',
      ],
      recommendedTopics: [
        'Clean Architecture in Mobile',
        'State Management & Dependency Injection',
        'Offline-First Data Sync & Conflict Resolution',
        'Production Error Monitoring & Telemetry',
      ],
      summary:
          'You demonstrated strong technical mastery in Flutter and Dart with clear architectural foundations. Deepening your explanations on distributed trade-offs will make your delivery top-tier.',
    );
  }
}
