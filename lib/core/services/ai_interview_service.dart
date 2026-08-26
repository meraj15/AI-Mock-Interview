import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../features/interview/domain/entities/interview_config_entity.dart';
import '../../features/resume/domain/entities/resume_entity.dart';

// ── Data models ───────────────────────────────────────────────────────────────

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

  factory AIQuestionPrompt.fromJson(Map<String, dynamic> j) => AIQuestionPrompt(
        primaryQuestion: j['primaryQuestion'] as String? ?? '',
        followUpQuestion: j['followUpQuestion'] as String? ?? '',
        category: j['category'] as String? ?? 'General',
        contextHint: j['contextHint'] as String? ?? '',
      );
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

  double get averageScore =>
      (situationScore + taskScore + actionScore + resultScore) / 4;
}

class DetailedQuestionEvaluation {
  final int questionIndex;
  final String primaryQuestion;
  final String category;
  final String candidateAnswer;
  final double score;
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
  final int percentile;
  final int industryAverageScore;
  final String readinessLevel;
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
  final String priority;
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
  final String hiringBand;
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

// ── Abstract service ──────────────────────────────────────────────────────────

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

// ── Real Gemini-backed service ────────────────────────────────────────────────

class GeminiAIInterviewService implements AIInterviewService {
  final ApiClient apiClient;

  GeminiAIInterviewService({required this.apiClient});

  @override
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    final skills = config.skills.isNotEmpty
        ? config.skills
        : resume.skills.isNotEmpty
            ? resume.skills
            : [config.role];

    final requestBody = {
      'role': config.role,
      'skills': skills,
      'difficulty': config.difficulty,
      'questionCount': config.questions,
      if (config.experience.isNotEmpty) 'experience': config.experience,
    };

    debugPrint('======================================================');
    debugPrint('[GeminiAIInterviewService] Requesting AI Questions');
    debugPrint('  Endpoint: ${ApiConfig.aiQuestionsEndpoint}');
    debugPrint('  Payload:  $requestBody');
    debugPrint('======================================================');

    try {
      final response = await apiClient.post(
        ApiConfig.aiQuestionsEndpoint,
        body: requestBody,
        requiresAuth: true,
      );

      debugPrint('[GeminiAIInterviewService] Response Status: ${response.statusCode}');
      debugPrint('[GeminiAIInterviewService] Response Body: ${response.data}');

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      final rawList = inner['questions'] as List<dynamic>? ?? [];

      final questions = rawList
          .whereType<Map<String, dynamic>>()
          .map(AIQuestionPrompt.fromJson)
          .toList();

      debugPrint('[GeminiAIInterviewService] Successfully parsed ${questions.length} AI questions:');
      for (int i = 0; i < questions.length; i++) {
        debugPrint('  Q${i + 1} [${questions[i].category}]: "${questions[i].primaryQuestion}"');
        debugPrint('     Follow-up: "${questions[i].followUpQuestion}"');
        debugPrint('     Hint: "${questions[i].contextHint}"');
      }

      if (questions.isEmpty) {
        throw Exception('AI returned 0 questions from backend');
      }

      return questions;
    } catch (e, stackTrace) {
      debugPrint('======================================================');
      debugPrint('[GeminiAIInterviewService] ERROR Generating Questions:');
      debugPrint('  Error: $e');
      debugPrint('  StackTrace: $stackTrace');
      debugPrint('======================================================');
      rethrow;
    }
  }

  @override
  Future<String> generateFollowUp({
    required String question,
    required String answer,
    required String role,
  }) async {
    // Follow-up is handled locally for now
    return MockAIInterviewService().generateFollowUp(
      question: question,
      answer: answer,
      role: role,
    );
  }

  @override
  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  }) async {
    return MockAIInterviewService().evaluateInterview(
      config: config,
      questions: questions,
      answers: answers,
    );
  }
}

// ── Mock fallback (used offline / when backend unavailable) ───────────────────

class MockAIInterviewService implements AIInterviewService {
  // ── Role-specific question banks ────────────────────────────────────────
  static const _roleQuestions = <String, Map<String, List<Map<String, String>>>>{
    'flutter': {
      'easy': [
        {
          'q': 'What is the difference between StatelessWidget and StatefulWidget? Give an example of when to use each.',
          'f': 'If you have a counter that updates on button press, which widget would you choose and why?',
          'category': 'Core Concepts',
          'hint': 'StatelessWidget is immutable; StatefulWidget holds mutable state.',
        },
        {
          'q': 'What is the purpose of the `pubspec.yaml` file in a Flutter project?',
          'f': 'How would you add and use an external package like `http` in your project?',
          'category': 'Project Setup',
          'hint': 'pubspec.yaml manages dependencies, assets, and app metadata.',
        },
        {
          'q': 'Explain the Flutter widget tree. How are widgets composed in Flutter?',
          'f': 'What happens when you call `setState()` and how does Flutter decide which widgets to rebuild?',
          'category': 'Widget Architecture',
          'hint': 'Everything is a widget — widgets are nested to build UI.',
        },
      ],
      'medium': [
        {
          'q': 'Compare Provider, Riverpod, and BLoC for state management. When would you choose each?',
          'f': 'You have a cart feature shared across 5 screens. Which state solution would you pick and how would you structure it?',
          'category': 'State Management',
          'hint': 'Discuss reactivity, testability, and boilerplate trade-offs.',
        },
        {
          'q': 'How do you implement Clean Architecture in a Flutter app? Describe the layers and data flow.',
          'f': 'How do you ensure domain entities stay free of Flutter/Firebase dependencies?',
          'category': 'Architecture',
          'hint': 'Presentation → Domain → Data. Dependencies point inward.',
        },
        {
          'q': 'What are isolates in Flutter and when should you use them?',
          'f': 'How would you offload a heavy JSON parsing task (10 MB file) without blocking the UI?',
          'category': 'Performance',
          'hint': 'Isolates run on separate threads; use compute() for one-off tasks.',
        },
        {
          'q': 'How do you handle API errors and show meaningful feedback to users in Flutter?',
          'f': 'Walk me through how you would retry a failed network request with exponential backoff.',
          'category': 'Networking',
          'hint': 'Use Either/Result types or exception-based handling with UI feedback.',
        },
      ],
      'hard': [
        {
          'q': 'Design an offline-first Flutter app with bidirectional sync. How do you handle conflict resolution?',
          'f': 'What happens when the same record is edited on two devices while offline and then both sync?',
          'category': 'System Design',
          'hint': 'Cover local DB (SQLite/Isar), sync queue, CRDTs, and last-write-wins.',
        },
        {
          'q': 'Your Flutter app drops below 60fps on mid-range Android devices. Walk me through your profiling and fix strategy.',
          'f': 'You find a widget rebuilding 40 times per second. How do you isolate and fix the rebuild storm?',
          'category': 'Performance Optimization',
          'hint': 'DevTools → Flutter Performance → identify jank → RepaintBoundary, const, selector.',
        },
        {
          'q': 'How would you architect a multi-module Flutter monorepo with shared design tokens, feature flags, and independent deployment?',
          'f': 'How do you handle breaking changes in shared packages without blocking feature teams?',
          'category': 'Architecture & Scalability',
          'hint': 'Melos, path dependencies, semantic versioning, feature flags via remote config.',
        },
      ],
    },
    'react': {
      'easy': [
        {
          'q': 'What is JSX and why does React use it instead of plain JavaScript?',
          'f': 'What does Babel do when it encounters JSX in your source code?',
          'category': 'Core Concepts',
          'hint': 'JSX is syntactic sugar — it compiles to React.createElement() calls.',
        },
        {
          'q': 'Explain the difference between props and state in React.',
          'f': 'Can a child component modify its parent\'s props? How do you pass data upward?',
          'category': 'Component Model',
          'hint': 'Props are immutable inputs; state is mutable and local to the component.',
        },
      ],
      'medium': [
        {
          'q': 'Explain the React component lifecycle. How do hooks replace lifecycle methods?',
          'f': 'How would you fetch data on mount and clean up on unmount using useEffect?',
          'category': 'Hooks & Lifecycle',
          'hint': 'useEffect dependencies array controls when the effect re-runs.',
        },
        {
          'q': 'When would you use useCallback and useMemo? What problem do they solve?',
          'f': 'You have a parent component re-rendering 20 times per second. How do you stop child re-renders?',
          'category': 'Performance',
          'hint': 'Memoization prevents unnecessary re-renders; use with React.memo.',
        },
        {
          'q': 'Compare Context API vs Redux vs Zustand for global state management.',
          'f': 'Your app has 50 components that need auth state. Which would you pick and why?',
          'category': 'State Management',
          'hint': 'Context is simple; Redux is predictable; Zustand is lightweight.',
        },
      ],
      'hard': [
        {
          'q': 'Design a micro-frontend architecture using React module federation. How do you share state and routing between apps?',
          'f': 'How do you handle version mismatches in shared React instances across micro-frontends?',
          'category': 'System Design',
          'hint': 'Webpack 5 Module Federation, shared singleton React, runtime composition.',
        },
        {
          'q': 'How does React\'s concurrent mode and Suspense change how you think about data fetching?',
          'f': 'How would you implement streaming SSR with React Server Components?',
          'category': 'Advanced React',
          'hint': 'Fiber scheduler, transitions, startTransition, Suspense boundaries.',
        },
      ],
    },
    'node': {
      'easy': [
        {
          'q': 'What is the event loop in Node.js and how does it handle asynchronous operations?',
          'f': 'What happens when you call setTimeout with 0ms delay — when does the callback run?',
          'category': 'Core Concepts',
          'hint': 'Event loop: call stack → microtasks → macrotasks.',
        },
        {
          'q': 'What is the difference between `require` and `import` in Node.js?',
          'f': 'How do you use ES modules in a Node.js project that uses CommonJS packages?',
          'category': 'Module System',
          'hint': 'CommonJS is synchronous; ES modules are async and statically analyzed.',
        },
      ],
      'medium': [
        {
          'q': 'How do you handle errors in an Express.js application? Describe your middleware strategy.',
          'f': 'How do you differentiate between operational errors and programmer errors in Node.js?',
          'category': 'Error Handling',
          'hint': 'Centralized error middleware, AppError class, uncaughtException handler.',
        },
        {
          'q': 'Explain JWT authentication flow in a Node.js REST API. How do you handle token refresh?',
          'f': 'How do you invalidate a JWT token before it expires?',
          'category': 'Authentication',
          'hint': 'Access token (short-lived) + refresh token (long-lived, stored in DB).',
        },
        {
          'q': 'How do you prevent N+1 queries when building a REST API with Prisma or Sequelize?',
          'f': 'Your endpoint for fetching 100 users with their orders fires 101 queries. How do you fix it?',
          'category': 'Database & ORM',
          'hint': 'Eager loading via include/join, DataLoader for GraphQL.',
        },
      ],
      'hard': [
        {
          'q': 'Design a scalable job queue system in Node.js that handles 100,000 background tasks per hour.',
          'f': 'How do you handle failed jobs, dead-letter queues, and exactly-once processing?',
          'category': 'System Design',
          'hint': 'BullMQ + Redis, worker processes, retry strategies, idempotency keys.',
        },
        {
          'q': 'How do you achieve zero-downtime deployments for a Node.js service under high traffic?',
          'f': 'How do you handle long-running WebSocket connections during a rolling restart?',
          'category': 'DevOps & Reliability',
          'hint': 'PM2 cluster, graceful shutdown, SIGTERM handler, load balancer drain.',
        },
      ],
    },
    'python': {
      'easy': [
        {
          'q': 'What is the difference between a list and a tuple in Python? When would you use each?',
          'f': 'Why are tuples used as dictionary keys but lists cannot be?',
          'category': 'Core Concepts',
          'hint': 'Tuples are immutable and hashable; lists are mutable.',
        },
        {
          'q': 'Explain Python\'s GIL. What is it and how does it affect multi-threaded programs?',
          'f': 'If the GIL limits true parallelism, how do you run CPU-bound tasks in parallel?',
          'category': 'Concurrency',
          'hint': 'GIL is per-process; use multiprocessing for CPU-bound, asyncio for I/O-bound.',
        },
      ],
      'medium': [
        {
          'q': 'What are Python decorators? Write a decorator that logs function execution time.',
          'f': 'How do you stack multiple decorators and what order do they execute?',
          'category': 'Language Features',
          'hint': 'Decorators are higher-order functions; stacked decorators apply bottom-up.',
        },
        {
          'q': 'How do you design a REST API with FastAPI? What makes it faster than Flask?',
          'f': 'How does FastAPI use Pydantic for request validation and what happens on validation failure?',
          'category': 'Web Framework',
          'hint': 'FastAPI uses async, type hints, Pydantic — auto docs via OpenAPI.',
        },
      ],
      'hard': [
        {
          'q': 'Design a distributed task queue using Python, Redis, and Celery for a data pipeline processing 1M rows/hour.',
          'f': 'How do you handle back-pressure and prevent memory exhaustion in your workers?',
          'category': 'System Design',
          'hint': 'Celery workers, Redis broker, task routing, rate limiting, autoscaling.',
        },
      ],
    },
    'android': {
      'easy': [
        {
          'q': 'What is the Activity lifecycle in Android? List the key callbacks and when they are called.',
          'f': 'What happens to your Activity when the user rotates the screen? How do you preserve state?',
          'category': 'Core Concepts',
          'hint': 'onCreate → onStart → onResume → onPause → onStop → onDestroy.',
        },
      ],
      'medium': [
        {
          'q': 'Compare ViewModel + LiveData vs StateFlow + Coroutines for UI state management.',
          'f': 'How do you handle configuration changes with ViewModel and ensure no memory leaks?',
          'category': 'Architecture',
          'hint': 'ViewModel survives rotation; StateFlow is cold, LiveData is lifecycle-aware.',
        },
        {
          'q': 'Explain Jetpack Compose\'s recomposition model. How does it differ from the View system?',
          'f': 'How do you prevent unnecessary recompositions in a large Compose screen?',
          'category': 'Jetpack Compose',
          'hint': 'Composables recompose when inputs change; use remember and derivedStateOf.',
        },
      ],
      'hard': [
        {
          'q': 'Design a background sync system in Android that works reliably across OEM battery optimizations.',
          'f': 'How do you handle Doze mode, App Standby, and manufacturer-specific restrictions?',
          'category': 'System Design',
          'hint': 'WorkManager, setExpedited, exact alarms, Foreground Service for critical work.',
        },
      ],
    },
  };

  // Generic fallback bank for unknown roles
  static const _genericQuestions = <String, List<Map<String, String>>>{
    'easy': [
      {
        'q': 'Describe the most recent project you worked on. What was your role and what technologies did you use?',
        'f': 'What was the biggest technical challenge you faced and how did you resolve it?',
        'category': 'Background',
        'hint': 'Give a concise project overview with your specific contributions.',
      },
      {
        'q': 'What is version control and why is it important in software development?',
        'f': 'Walk me through your typical Git workflow when working on a feature branch.',
        'category': 'Development Practices',
        'hint': 'Cover branching strategy, commit hygiene, and pull request workflow.',
      },
    ],
    'medium': [
      {
        'q': 'How do you approach debugging a production issue you have never seen before?',
        'f': 'Describe a time when logs were insufficient. What did you do next?',
        'category': 'Problem Solving',
        'hint': 'Systematic approach: reproduce → isolate → fix → verify → document.',
      },
      {
        'q': 'How do you ensure code quality in a team setting? What tools and practices do you rely on?',
        'f': 'How do you handle disagreements during a code review constructively?',
        'category': 'Engineering Practices',
        'hint': 'Mention linters, tests, CI gates, and review culture.',
      },
      {
        'q': 'Explain the concept of technical debt. How do you balance feature delivery with code quality?',
        'f': 'Give an example where you proactively addressed technical debt without being asked.',
        'category': 'Engineering Mindset',
        'hint': 'Quantify debt, prioritize strategically, communicate trade-offs to stakeholders.',
      },
    ],
    'hard': [
      {
        'q': 'Design a system that ingests 1 million events per minute and delivers analytics in near real-time.',
        'f': 'How do you handle backpressure when consumers are slower than producers?',
        'category': 'System Design',
        'hint': 'Kafka, stream processing, partitioning, consumer groups, windowed aggregation.',
      },
      {
        'q': 'Your service latency suddenly spikes from 50ms to 2000ms in production. Walk me through your investigation.',
        'f': 'After fixing the issue, how do you prevent it from happening again?',
        'category': 'Reliability Engineering',
        'hint': 'Metrics → traces → logs → isolate component → root cause → post-mortem.',
      },
    ],
  };

  /// Resolve which question bank to use based on role and skills
  static String _resolveRoleKey(String role, List<String> skills) {
    final combined = '${role.toLowerCase()} ${skills.join(' ').toLowerCase()}';
    if (combined.contains('flutter') || combined.contains('dart')) return 'flutter';
    if (combined.contains('react') || combined.contains('next') || combined.contains('vue')) return 'react';
    if (combined.contains('node') || combined.contains('express') || combined.contains('nestjs')) return 'node';
    if (combined.contains('python') || combined.contains('django') || combined.contains('fastapi')) return 'python';
    if (combined.contains('android') || combined.contains('kotlin')) return 'android';
    return 'generic';
  }

  static String _normalizeDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':   return 'easy';
      case 'hard':   return 'hard';
      case 'adaptive': return 'medium'; // treat adaptive as medium for bank lookup
      default:       return 'medium';
    }
  }

  @override
  Future<List<AIQuestionPrompt>> generateQuestions({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final skills = config.skills.isNotEmpty ? config.skills : resume.skills;
    final roleKey = _resolveRoleKey(config.role, skills);
    final diffKey = _normalizeDifficulty(config.difficulty);

    // Pick bank: role-specific → generic
    final Map<String, List<Map<String, String>>> bank =
        roleKey != 'generic' ? (_roleQuestions[roleKey] ?? _genericQuestions) : _genericQuestions;

    // Build a merged ordered list: matching difficulty first, then adjacent levels
    final orderedDiffs = diffKey == 'easy'
        ? ['easy', 'medium', 'hard']
        : diffKey == 'hard'
            ? ['hard', 'medium', 'easy']
            : ['medium', 'easy', 'hard'];

    final pool = <Map<String, String>>[];
    for (final d in orderedDiffs) {
      pool.addAll(bank[d] ?? []);
    }
    if (pool.isEmpty) {
      // Absolute fallback: generic medium
      pool.addAll(_genericQuestions['medium']!);
    }

    // Warm-up question using candidate name + skills
    final firstName = resume.candidateName.split(' ').first;
    final topSkills = skills.take(3).join(', ');
    final result = <AIQuestionPrompt>[
      AIQuestionPrompt(
        primaryQuestion:
            'Welcome${ firstName.isNotEmpty ? ", $firstName" : ""}! '
            'You\'re applying for a ${config.role} role. '
            'Walk me through a recent project where you used $topSkills — focusing on your specific contribution and the outcome.',
        followUpQuestion:
            'What was the hardest technical trade-off you made on that project, and would you make the same call today?',
        category: 'Introduction',
        contextHint:
            'Listen for concrete impact and self-awareness about technical decisions.',
      ),
    ];

    // Fill from pool up to requested count
    int idx = 0;
    while (result.length < config.questions && idx < pool.length) {
      final entry = pool[idx++];
      result.add(AIQuestionPrompt(
        primaryQuestion: entry['q']!,
        followUpQuestion: entry['f']!,
        category: entry['category']!,
        contextHint: entry['hint']!,
      ));
    }

    // If still short, cycle the pool
    while (result.length < config.questions) {
      final entry = pool[(idx++) % pool.length];
      result.add(AIQuestionPrompt(
        primaryQuestion: entry['q']!,
        followUpQuestion: entry['f']!,
        category: entry['category']!,
        contextHint: entry['hint']!,
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
    return 'You touched on the core concept well. Can you walk me through a specific production scenario where you applied this — and what metric confirmed it worked?';
  }

  @override
  Future<AIEvaluationResult> evaluateInterview({
    required InterviewConfigEntity config,
    required List<String> questions,
    required List<String> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    int totalWords = 0;
    int techKeywordCount = 0;
    const keywords = [
      'architecture', 'performance', 'state', 'async', 'test', 'layer', 'api',
      'cache', 'design', 'pattern', 'isolate', 'stream', 'repository', 'inject',
      'crdt', 'sqlite', 'metric', 'reduced', 'latency', 'mutex', 'lock',
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
    final overall = ((depthScore * 0.45 + techScore * 0.55).clamp(55, 96)).toInt();

    final hiringBand = overall >= 88
        ? 'Strong Hire'
        : overall >= 78
            ? 'Hire'
            : overall >= 68
                ? 'Leaning Hire'
                : 'Needs Practice';

    final performanceLabel = overall >= 88
        ? 'Outstanding Mastery'
        : overall >= 78
            ? 'Strong Candidate'
            : overall >= 68
                ? 'Solid Foundations'
                : 'Developing Practitioner';

    final questionEvaluations = <DetailedQuestionEvaluation>[];
    for (int i = 0; i < questions.length; i++) {
      final ans = i < answers.length ? answers[i] : 'No response captured.';
      final isLong = ans.split(' ').length > 40;
      final qScore = isLong ? 8.5 + (i % 3) * 0.3 : 7.0 + (i % 2) * 0.5;

      questionEvaluations.add(DetailedQuestionEvaluation(
        questionIndex: i + 1,
        primaryQuestion: questions[i],
        category: i == 0 ? 'Introduction' : 'Core Skills',
        candidateAnswer: ans,
        score: qScore.clamp(6.0, 9.8),
        strengths: [
          'Clear explanation of the technical approach.',
          'Structured response with relevant examples.',
        ],
        missingPoints: [
          'Could include specific metrics to quantify the outcome.',
          'Consider mentioning edge cases or failure modes.',
        ],
        idealModelAnswer:
            'The ideal answer references a specific project, names the technology used, describes the decision-making process, and closes with a measurable outcome.',
        starScorecard: StarScorecard(
          situationScore: 8.5,
          situationFeedback: 'Good context-setting.',
          taskScore: 8.2,
          taskFeedback: 'Responsibility was clearly stated.',
          actionScore: 8.7,
          actionFeedback: 'Specific actions and reasoning provided.',
          resultScore: isLong ? 8.3 : 7.0,
          resultFeedback: isLong ? 'Measurable result included.' : 'Add a quantified result.',
        ),
        coachTip: 'Always close your answer with a metric — numbers make your impact memorable.',
      ));
    }

    final benchmark = RoleBenchmark(
      percentile: overall >= 85 ? 90 : overall >= 75 ? 82 : 68,
      industryAverageScore: 72,
      readinessLevel: overall >= 85
          ? 'Ready for Senior / Staff Tier'
          : overall >= 75
              ? 'Ready for Mid-to-Senior Tier'
              : 'Requires Foundational Reinforcement',
      companyCultureAlignment:
          'Good alignment with ${config.company}\'s engineering criteria.',
    );

    final skillsForStudy = config.skills.isNotEmpty
        ? config.skills.take(3).toList()
        : [config.role, 'System Design', 'Communication'];

    return AIEvaluationResult(
      overallScore: overall,
      performanceLabel: performanceLabel,
      hiringBand: hiringBand,
      benchmark: benchmark,
      skillScores: {
        'Technical Knowledge': (techScore * 0.9 + 10).toInt().clamp(55, 96),
        'Communication & Clarity': (depthScore * 0.85 + 10).toInt().clamp(55, 95),
        'Problem Solving': (overall * 0.96 + 2).toInt().clamp(55, 97),
        'Confidence & Delivery': (overall * 0.89 + 5).toInt().clamp(55, 94),
        'Role Mastery': (techScore * 0.95 + 4).toInt().clamp(55, 98),
      },
      strengths: [
        'Demonstrates solid understanding of core ${config.role} concepts.',
        'Structured and professional communication throughout.',
        'Good use of real-world examples to illustrate technical points.',
      ],
      areasToImprove: [
        'Quantify results — always back up claims with metrics.',
        'Deepen coverage of edge cases and failure scenarios.',
        'Practice concise STAR-format answers for behavioral questions.',
      ],
      recommendedTopics: skillsForStudy,
      studyPlan: [
        StudyPlanItem(
          topic: 'Quantifying Impact (STAR Framework)',
          priority: 'High',
          estimatedTime: '1 hour',
          rationale: 'Interviewers remember numbers — prepare 3 stories with measurable outcomes.',
          actionDrill:
              'Rewrite your last 3 project descriptions to include before/after metrics.',
        ),
        StudyPlanItem(
          topic: 'System Design Fundamentals',
          priority: 'High',
          estimatedTime: '2 hours',
          rationale: 'Senior roles expect architectural thinking beyond feature-level coding.',
          actionDrill:
              'Design a URL shortener on paper: cover storage, caching, and scalability.',
        ),
        StudyPlanItem(
          topic: 'Edge Cases & Failure Modes',
          priority: 'Medium',
          estimatedTime: '1 hour',
          rationale: 'Strong engineers think about what can go wrong before it does.',
          actionDrill:
              'For your last feature, list 5 failure scenarios and how you would detect / recover from each.',
        ),
      ],
      questionEvaluations: questionEvaluations,
      summary:
          'You demonstrated solid foundations for the ${config.role} position. '
          'Your answers are structured and show real-world experience. '
          'To stand out further, deepen your answers with quantified outcomes and edge-case reasoning.',
    );
  }
}
