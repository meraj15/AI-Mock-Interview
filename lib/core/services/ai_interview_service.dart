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
  // Question banks keyed by focus topic / category
  static const _questionBank = <String, List<Map<String, String>>>{
    'State Management': [
      {
        'q': 'Walk me through how you would architect state management for a multi-module Flutter application with shared and isolated states.',
        'f': 'You mentioned your state solution. How did you prevent unnecessary widget rebuilds in high-frequency data streams?',
        'hint': 'Discuss BLoC, Riverpod, or Provider — justify the selection with real trade-offs.',
      },
      {
        'q': 'How do you handle global auth state that must propagate instantly to all routes without triggering full tree rebuilds?',
        'f': 'How would you test this behavior in isolation using mock repositories?',
        'hint': 'Think about InheritedNotifier vs Provider vs reactive streams.',
      },
    ],
    'Clean Architecture': [
      {
        'q': 'Describe how you implement the dependency rule in Clean Architecture. How do your domain entities stay free of framework dependencies?',
        'f': 'If a product manager asks you to add Firebase analytics directly in the domain layer, how do you push back with a technical argument?',
        'hint': 'Domain entities must never import Flutter or Firebase packages — explain layering.',
      },
      {
        'q': 'How does your data layer handle multiple remote sources (e.g. REST + GraphQL) for the same domain entity?',
        'f': 'What happens when the remote source returns a partial payload and the local cache has a stale record?',
        'hint': 'Repository pattern as the single source of truth.',
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
      {
        'q': 'If you were asked to design a distributed caching layer for mobile API responses, what strategy would you choose and why?',
        'f': 'How do you handle cache invalidation when the backend data changes without a push event?',
        'hint': 'TTL, ETags, stale-while-revalidate are strong patterns to mention.',
      },
    ],
    'API Integration & REST': [
      {
        'q': 'How do you handle concurrent API requests in Flutter that depend on each other, without blocking the UI thread?',
        'f': 'If one of those concurrent requests fails and others succeed, how do you roll back or compensate?',
        'hint': 'Dart Futures, isolates, and structured concurrency patterns.',
      },
    ],
    'Testing & TDD': [
      {
        'q': 'Walk me through your TDD workflow. How do you write a test for a repository layer that depends on a remote data source?',
        'f': 'How do you test the integration between your BLoC and your repository without hitting a live API?',
        'hint': 'Mockito, mocktail, and dependency injection for test doubles.',
      },
    ],
    'CI/CD & DevOps': [
      {
        'q': 'Describe your ideal CI/CD pipeline for a Flutter project that targets both App Store and Google Play. What stages and tools would you include?',
        'f': 'How do you manage secrets (e.g. keystore, provisioning profiles) securely inside your CI runner?',
        'hint': 'Fastlane, GitHub Actions, Codemagic, environment secrets.',
      },
    ],
    'Behavioral (STAR)': [
      {
        'q': 'Describe a time when you disagreed with a technical decision made by a senior colleague. How did you handle it and what was the outcome?',
        'f': 'Looking back, what would you do differently to influence the technical direction more effectively?',
        'hint': 'Structure as: Situation → Task → Action → Result.',
      },
      {
        'q': 'Tell me about a critical deadline you almost missed. What did you prioritize and how did you communicate the risk?',
        'f': 'How do you proactively prevent this from repeating on future projects?',
        'hint': 'Focus on your decision-making process and stakeholder communication.',
      },
    ],
    'Concurrency & Async': [
      {
        'q': 'Explain how Dart\'s event loop and isolate model differs from traditional multi-threading. Where have you used isolates in production?',
        'f': 'How would you design a background processing queue in Flutter that survives app backgrounding?',
        'hint': 'Dart Isolate, compute(), WorkManager, and flutter_background_service.',
      },
    ],
    'Security & Auth': [
      {
        'q': 'How do you store sensitive tokens securely on mobile devices, and what are the risks of storing them in SharedPreferences?',
        'f': 'Walk me through how you implement token refresh transparently without the user ever seeing an auth error.',
        'hint': 'FlutterSecureStorage, Keychain, Keystore, and Dio interceptors.',
      },
    ],
    'Database & Caching': [
      {
        'q': 'How do you design an offline-first data architecture where the local SQLite database is the single source of truth?',
        'f': 'How do you resolve conflicts when the backend and local store diverge during a network partition?',
        'hint': 'Discuss sync strategies: full replace, delta sync, CRDTs, or timestamps.',
      },
    ],
    'Memory Management': [
      {
        'q': 'How do you detect and eliminate memory leaks in a Flutter app, particularly those caused by uncancelled subscriptions or retained contexts?',
        'f': 'What patterns do you enforce at the code review level to prevent memory leaks from shipping to production?',
        'hint': 'StreamSubscription.cancel(), WeakReference, DevTools memory timeline.',
      },
    ],
  };

  static const _genericPool = [
    AIQuestionPrompt(
      primaryQuestion: 'Walk me through your most impactful project from architecture to delivery.',
      followUpQuestion: 'What was the most difficult technical trade-off you had to negotiate on that project?',
      category: 'Project Architecture',
      contextHint: 'A concrete example with measurable outcomes will stand out.',
    ),
    AIQuestionPrompt(
      primaryQuestion: 'How do you approach code reviews? What do you look for beyond syntactic correctness?',
      followUpQuestion: 'Give me an example where a code review caught a critical production issue before release.',
      category: 'Engineering Excellence',
      contextHint: 'Think about maintainability, testability, security, and performance.',
    ),
    AIQuestionPrompt(
      primaryQuestion: 'How do you balance technical debt repayment against shipping new features under pressure?',
      followUpQuestion: 'How do you quantify technical debt to make it visible and actionable for non-technical stakeholders?',
      category: 'Engineering Strategy',
      contextHint: 'Discuss debt budgets, refactoring sprints, and communication with product.',
    ),
  ];

  @override
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final List<AIQuestionPrompt> result = [];

    // Use focus topics from config if available
    final topics = config.focusTopics.isNotEmpty
        ? config.focusTopics
        : ['State Management', 'Clean Architecture', 'Performance Optimization'];

    final isBehavioral = config.type.toLowerCase().contains('behavioral');
    final isSystemDesign = config.type.toLowerCase().contains('system design') ||
        config.type.toLowerCase().contains('architecture');

    // Always inject behavioral for full mock
    final resolvedTopics = config.type.toLowerCase().contains('full mock')
        ? [...topics, 'Behavioral (STAR)']
        : isBehavioral
            ? ['Behavioral (STAR)', 'Behavioral (STAR)']
            : isSystemDesign
                ? ['System Design', ...topics]
                : topics;

    final skills = resume.skills.take(3).join(', ');
    final candidateName = resume.candidateName.split(' ').first;
    final codingLang = config.codingLanguage == 'Any / No Preference' ? 'Dart/Flutter' : config.codingLanguage;

    // Opening personalised question
    result.add(AIQuestionPrompt(
      primaryQuestion:
          'Welcome, $candidateName! I see $skills on your profile. Walk me through a recent high-impact project where you leveraged these skills end-to-end.',
      followUpQuestion:
          'You described a strong technical setup. What was the most difficult technical trade-off you had to make, and how did you resolve it?',
      category: 'Intro & Project Deep-Dive',
      contextHint: 'Provide a concrete example with quantified business impact.',
    ));

    // Topic-based questions
    for (final topic in resolvedTopics) {
      final bank = _questionBank[topic];
      if (bank != null && bank.isNotEmpty) {
        // Rotate through bank entries
        final entry = bank[result.length % bank.length];
        result.add(AIQuestionPrompt(
          primaryQuestion: entry['q']!.replaceAll('{lang}', codingLang),
          followUpQuestion: entry['f']!,
          category: topic,
          contextHint: entry['hint']!,
        ));
      }
      if (result.length >= config.questions) break;
    }

    // Pad with generic questions if needed
    var gi = 0;
    while (result.length < config.questions && gi < _genericPool.length) {
      result.add(_genericPool[gi]);
      gi++;
    }

    // Closing question
    if (result.length < config.questions) {
      result.add(const AIQuestionPrompt(
        primaryQuestion: 'Looking back at your career so far, what is the one technical skill you wish you had invested in earlier, and what\'s your plan to close that gap?',
        followUpQuestion: 'How do you currently stay sharp and keep up with rapidly evolving best practices in your field?',
        category: 'Growth Mindset',
        contextHint: 'Show self-awareness and a proactive learning mindset.',
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
    await Future.delayed(const Duration(milliseconds: 400));
    final lower = answer.toLowerCase();

    if (lower.contains('state') || lower.contains('provider') || lower.contains('riverpod')) {
      return 'You mentioned your state solution. How did you prevent unnecessary widget rebuilds in high-frequency data streams?';
    }
    if (lower.contains('architecture') || lower.contains('clean') || lower.contains('domain')) {
      return 'You described your architecture well. How do you enforce these boundaries in a team environment during code reviews?';
    }
    if (lower.contains('team') || lower.contains('collaboration') || lower.contains('lead')) {
      return 'That shows strong leadership instincts. Can you give me a concrete situation where resolving that conflict directly improved a product outcome?';
    }
    if (lower.contains('performance') || lower.contains('optimize') || lower.contains('fps')) {
      return 'You identified the root cause effectively. How did you validate the fix in production without relying solely on a staging environment?';
    }
    return 'That\'s a solid foundation. Can you go deeper on the specific technical decisions you made and how you validated them in production?';
  }

  @override
  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    // Dynamically score based on answer depth
    int totalWords = 0;
    int technicalTerms = 0;
    final keywords = ['architecture', 'performance', 'state', 'async', 'test', 'layer', 'api', 'cache', 'design', 'pattern', 'isolate', 'stream', 'repository', 'inject'];
    for (final a in answers) {
      totalWords += a.split(' ').length;
      for (final kw in keywords) {
        if (a.toLowerCase().contains(kw)) technicalTerms++;
      }
    }

    final avgWords = answers.isEmpty ? 0 : totalWords ~/ answers.length;
    final depthScore = (avgWords.clamp(20, 120) / 120 * 100).toInt();
    final techScore = (technicalTerms.clamp(0, 15) / 15 * 100).toInt();
    final overall = ((depthScore * 0.5 + techScore * 0.5).clamp(62, 95)).toInt();

    final performanceLabel = overall >= 88
        ? 'Outstanding Performance'
        : overall >= 78
            ? 'Strong Performance'
            : overall >= 68
                ? 'Good Foundation'
                : 'Keep Practising';

    return AIEvaluationResult(
      overallScore: overall,
      performanceLabel: performanceLabel,
      skillScores: {
        'Technical Knowledge': (techScore * 0.9 + 10).toInt().clamp(55, 95),
        'Communication & Clarity': (depthScore * 0.85 + 10).toInt().clamp(55, 95),
        'Problem Solving': (overall * 0.95 + 3).toInt().clamp(55, 95),
        'Confidence & Delivery': (overall * 0.88 + 5).toInt().clamp(55, 95),
        'Role Knowledge': (techScore * 0.95 + 5).toInt().clamp(55, 95),
      },
      strengths: [
        avgWords > 60
            ? 'Your answers demonstrated strong narrative depth — you gave structured, well-reasoned explanations.'
            : 'You showed clear technical familiarity with your domain tools and frameworks.',
        technicalTerms > 8
            ? 'You used precise technical vocabulary, signaling deep hands-on expertise to the interviewer.'
            : 'Your answers were focused and directly addressed the question\'s core.',
        'You maintained a professional and composed tone throughout the session.',
      ],
      areasToImprove: [
        avgWords < 50
            ? 'Expand your answers — the interviewer expects 60–120 words with concrete examples, not just definitions.'
            : 'Go deeper on production-grade trade-offs; mention failure modes and how you mitigated them.',
        technicalTerms < 6
            ? 'Incorporate more precise technical terms (e.g. idempotency, observability, backpressure) to signal seniority.'
            : 'Tie your technical choices to measurable business outcomes (e.g. reduced crash rate by 40%).',
        'Practise the STAR format for behavioral questions — always close with a quantified result.',
      ],
      recommendedTopics: config.focusTopics.isNotEmpty
          ? config.focusTopics.take(4).toList()
          : ['Clean Architecture', 'State Management', 'Offline Sync', 'Production Observability'],
      summary:
          'You demonstrated $performanceLabel across the ${config.type} session for the ${config.role} role. '
          '${overall >= 80 ? 'Your technical depth and structured delivery stand out.' : 'Focus on providing deeper, example-driven answers with quantified outcomes.'} '
          'Target: ${config.company}.',
    );
  }
}
