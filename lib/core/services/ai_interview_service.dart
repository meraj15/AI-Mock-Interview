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

class StarScorecard {
  final double situationScore;
  final String situationFeedback;
  final double taskScore;
  final String taskFeedback;
  final double actionScore;
  final String actionFeedback;
  final double resultScore;
  final String resultFeedback;

  const StarScorecard({
    required this.situationScore,
    required this.situationFeedback,
    required this.taskScore,
    required this.taskFeedback,
    required this.actionScore,
    required this.actionFeedback,
    required this.resultScore,
    required this.resultFeedback,
  });

  double get averageScore => (situationScore + taskScore + actionScore + resultScore) / 4;
}

class DetailedQuestionEvaluation {
  final int questionIndex;
  final String primaryQuestion;
  final String category;
  final String candidateAnswer;
  final double score; // 0.0 - 10.0
  final List<String> strengths;
  final List<String> missingPoints;
  final String idealModelAnswer;
  final StarScorecard? starScorecard;
  final String coachTip;

  const DetailedQuestionEvaluation({
    required this.questionIndex,
    required this.primaryQuestion,
    required this.category,
    required this.candidateAnswer,
    required this.score,
    required this.strengths,
    required this.missingPoints,
    required this.idealModelAnswer,
    this.starScorecard,
    required this.coachTip,
  });
}

class RoleBenchmark {
  final int percentile; // e.g. 88 (Top 12%)
  final int industryAverageScore; // e.g. 72
  final String readinessLevel; // e.g. "Senior Tier Ready"
  final String companyCultureAlignment;

  const RoleBenchmark({
    required this.percentile,
    required this.industryAverageScore,
    required this.readinessLevel,
    required this.companyCultureAlignment,
  });
}

class StudyPlanItem {
  final String topic;
  final String priority; // "High", "Medium"
  final String estimatedTime;
  final String rationale;
  final String actionDrill;

  const StudyPlanItem({
    required this.topic,
    required this.priority,
    required this.estimatedTime,
    required this.rationale,
    required this.actionDrill,
  });
}

class AIEvaluationResult {
  final int overallScore;
  final String performanceLabel;
  final String hiringBand; // "Strong Hire", "Hire", "Leaning Hire", "Needs Work"
  final RoleBenchmark benchmark;
  final Map<String, int> skillScores;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<String> recommendedTopics;
  final List<StudyPlanItem> studyPlan;
  final List<DetailedQuestionEvaluation> questionEvaluations;
  final String summary;

  const AIEvaluationResult({
    required this.overallScore,
    required this.performanceLabel,
    required this.hiringBand,
    required this.benchmark,
    required this.skillScores,
    required this.strengths,
    required this.areasToImprove,
    required this.recommendedTopics,
    required this.studyPlan,
    required this.questionEvaluations,
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
  static const _questionBank = <String, List<Map<String, String>>>{
    'State Management': [
      {
        'q': 'Walk me through how you would architect state management for a multi-module Flutter application with shared and isolated states.',
        'f': 'You mentioned your state solution. How did you prevent unnecessary widget rebuilds in high-frequency data streams?',
        'hint': 'Discuss BLoC, Riverpod, or Provider — justify the selection with real trade-offs.',
      },
    ],
    'Clean Architecture': [
      {
        'q': 'Describe how you implement the dependency rule in Clean Architecture. How do your domain entities stay free of framework dependencies?',
        'f': 'If a product manager asks you to add Firebase analytics directly in the domain layer, how do you push back with a technical argument?',
        'hint': 'Domain entities must never import Flutter or Firebase packages — explain layering.',
      },
    ],
    'Performance Optimization': [
      {
        'q': 'What systematic approach do you use to diagnose and eliminate jank in a Flutter application delivering below 60fps?',
        'f': 'Walk me through a real-time case where you reduced frame render time by over 30%. What tooling and metrics did you use?',
        'hint': 'Mention DevTools, RepaintBoundary, const widgets, and isolate offloading.',
      },
    ],
    'System Design': [
      {
        'q': 'Design a real-time messaging feature with offline message queue and delivery receipts for a 5M-user mobile application.',
        'f': 'How would you ensure exactly-once message delivery across unreliable mobile networks?',
        'hint': 'Cover WebSockets, local queue, retry exponential backoff, and idempotency keys.',
      },
    ],
  };

  @override
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final List<AIQuestionPrompt> result = [];
    final topics = config.focusTopics.isNotEmpty
        ? config.focusTopics
        : ['State Management', 'Clean Architecture', 'Performance Optimization', 'System Design'];

    final skills = resume.skills.take(3).join(', ');
    final candidateName = resume.candidateName.split(' ').first;

    // 1. Warm-up
    result.add(AIQuestionPrompt(
      primaryQuestion:
          'Welcome, $candidateName! I see $skills on your profile. Walk me through a recent high-impact project where you leveraged these skills end-to-end.',
      followUpQuestion:
          'What was the most difficult technical trade-off you had to make on this architecture, and how did you resolve it?',
      category: 'Project Architecture',
      contextHint: 'Provide a concrete example with quantified business impact.',
    ));

    // 2. Focus topic questions
    for (final topic in topics) {
      final bank = _questionBank[topic];
      if (bank != null && bank.isNotEmpty) {
        final entry = bank[result.length % bank.length];
        result.add(AIQuestionPrompt(
          primaryQuestion: entry['q']!,
          followUpQuestion: entry['f']!,
          category: topic,
          contextHint: entry['hint']!,
        ));
      }
      if (result.length >= config.questions) break;
    }

    // Pad if necessary
    while (result.length < config.questions) {
      result.add(AIQuestionPrompt(
        primaryQuestion: 'How do you structure automated CI/CD pipelines to validate pull requests with zero flaky test tolerance?',
        followUpQuestion: 'How do you handle credential security and code signing certificates inside automated builders?',
        category: 'CI/CD & DevOps',
        contextHint: 'Discuss GitHub Actions, Fastlane, and automated smoke test matrices.',
      ));
    }

    return result.take(config.questions).toList();
  }

  @override
  Future<String> generateFollowUp({
    required String question,
    required String answer,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 'You identified the root cause effectively. How did you validate this decision in production and measure the performance delta?';
  }

  @override
  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1100));

    int totalWords = 0;
    int techKeywordCount = 0;
    final keywords = [
      'architecture', 'performance', 'state', 'async', 'test', 'layer', 'api',
      'cache', 'design', 'pattern', 'isolate', 'stream', 'repository', 'inject',
      'crdt', 'sqlite', 'metric', 'reduced', 'latency', 'mutex', 'lock'
    ];

    for (final a in answers) {
      totalWords += a.split(' ').where((w) => w.isNotEmpty).length;
      for (final kw in keywords) {
        if (a.toLowerCase().contains(kw)) techKeywordCount++;
      }
    }

    final avgWords = answers.isEmpty ? 0 : totalWords ~/ answers.length;
    final depthScore = (avgWords.clamp(20, 110) / 110 * 100).toInt();
    final techScore = (techKeywordCount.clamp(0, 16) / 16 * 100).toInt();
    final overall = ((depthScore * 0.45 + techScore * 0.55).clamp(65, 96)).toInt();

    final hiringBand = overall >= 88
        ? 'Strong Hire'
        : overall >= 78
            ? 'Hire'
            : overall >= 68
                ? 'Leaning Hire'
                : 'Needs Practice';

    final performanceLabel = overall >= 88
        ? 'Outstanding Senior Mastery'
        : overall >= 78
            ? 'Strong Candidate Profile'
            : overall >= 68
                ? 'Solid Foundations'
                : 'Developing Practitioner';

    // Detailed per-question evaluations
    final questionEvaluations = <DetailedQuestionEvaluation>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final ans = i < answers.length ? answers[i] : 'No response captured.';
      final isLong = ans.split(' ').length > 40;
      final qScore = isLong ? 8.5 + (i % 3) * 0.4 : 7.2 + (i % 2) * 0.5;

      questionEvaluations.add(
        DetailedQuestionEvaluation(
          questionIndex: i + 1,
          primaryQuestion: q,
          category: i == 0 ? 'Project Architecture' : 'Core Engineering',
          candidateAnswer: ans,
          score: qScore.clamp(6.5, 9.8),
          strengths: [
            'Clear articulation of architectural separation and state predictability.',
            'Effective explanation of data layer abstractions and repository contracts.',
          ],
          missingPoints: [
            'Could have mentioned specific performance telemetry tools (e.g. Firebase Performance / Sentry).',
            'Did not discuss handling edge cases during intermittent network packet loss.',
          ],
          idealModelAnswer:
              'In my production applications, I isolate domain business rules completely from UI widgets. Using Clean Architecture, the Presentation layer interacts exclusively with UseCases, which retrieve state via Repository contracts. For offline resilience, I combine SQLite caching with a background sync queue that retries failed mutations with exponential backoff. This resulted in zero data loss and a 35% latency drop.',
          starScorecard: StarScorecard(
            situationScore: 8.8,
            situationFeedback: 'Well-framed background context and problem scope.',
            taskScore: 8.5,
            taskFeedback: 'Clearly identified the engineering responsibility.',
            actionScore: 8.9,
            actionFeedback: 'Specific patterns and frameworks named effectively.',
            resultScore: isLong ? 8.4 : 7.2,
            resultFeedback: isLong ? 'Provided measurable business and engineering impact.' : 'Recommend closing with quantifiable metrics.',
          ),
          coachTip: 'Always follow up technical decisions with the metric used to measure success.',
        ),
      );
    }

    final benchmark = RoleBenchmark(
      percentile: overall >= 85 ? 92 : overall >= 78 ? 84 : 71,
      industryAverageScore: 72,
      readinessLevel: overall >= 85
          ? 'Ready for Senior / Staff Tier'
          : overall >= 75
              ? 'Ready for Mid-to-Senior Tier'
              : 'Requires Foundational Reinforcement',
      companyCultureAlignment:
          'High alignment with ${config.company}\'s engineering criteria for system reliability and clean separation of concerns.',
    );

    final studyPlan = [
      const StudyPlanItem(
        topic: 'Offline Sync & Conflict Resolution',
        priority: 'High',
        estimatedTime: '2 hours',
        rationale: 'Crucial for high-scale mobile applications handling spotty network connections.',
        actionDrill: 'Build a sample offline-first cache using SQLite/Isar with a background mutation queue.',
      ),
      const StudyPlanItem(
        topic: 'Performance Profiling & Jank Elimination',
        priority: 'High',
        estimatedTime: '1.5 hours',
        rationale: 'Top tech interviewers look for mastery over DevTools, raster threads, and isolate computation.',
        actionDrill: 'Profile an intentionally heavy list rebuild in Flutter DevTools and apply RepaintBoundary & const optimizations.',
      ),
      const StudyPlanItem(
        topic: 'STAR Structured Delivery for Behavioral Rounds',
        priority: 'Medium',
        estimatedTime: '1 hour',
        rationale: 'Ensures every leadership story concludes with measurable business outcomes.',
        actionDrill: 'Prepare 3 STAR stories covering: deadline pressure, technical disagreement, and architectural refactor.',
      ),
    ];

    return AIEvaluationResult(
      overallScore: overall,
      performanceLabel: performanceLabel,
      hiringBand: hiringBand,
      benchmark: benchmark,
      skillScores: {
        'Technical Knowledge': (techScore * 0.9 + 10).toInt().clamp(60, 96),
        'Communication & Clarity': (depthScore * 0.85 + 10).toInt().clamp(60, 95),
        'Problem Solving & Architecture': (overall * 0.96 + 2).toInt().clamp(62, 97),
        'Confidence & Delivery': (overall * 0.89 + 5).toInt().clamp(60, 94),
        'Role Mastery': (techScore * 0.95 + 4).toInt().clamp(64, 98),
      },
      strengths: [
        'Strong grasp of Flutter core principles and clean architectural separation.',
        'Articulate explanation of real project workflows and repository layers.',
        'Structured problem decomposition and composure during technical questions.',
      ],
      areasToImprove: [
        'Go deeper into distributed system trade-offs and offline sync edge cases.',
        'Always quantify results (e.g. reduced app launch time by 40%).',
        'Reference observability, crash reporting, and real user monitoring (RUM).',
      ],
      recommendedTopics: config.focusTopics.isNotEmpty
          ? config.focusTopics.take(4).toList()
          : ['Clean Architecture in Mobile', 'State Management', 'Offline Sync', 'Telemetry'],
      studyPlan: studyPlan,
      questionEvaluations: questionEvaluations,
      summary:
          'You demonstrated strong technical mastery for the ${config.role} position with clear architectural intuition. '
          'Your communication is structured and professional. Deepening your explanations with measurable metrics and offline-edge cases will make your candidacy exceptional.',
    );
  }
}
