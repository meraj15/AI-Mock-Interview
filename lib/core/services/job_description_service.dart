import '../../features/job_prep/domain/entities/job_description_entity.dart';
import '../../features/resume/domain/entities/resume_entity.dart';

abstract class JobDescriptionService {
  Future<JDAnalysisResult> analyzeJobDescription({
    required String rawText,
    required String companyName,
    required ResumeEntity resume,
  });
}

class MockJobDescriptionService implements JobDescriptionService {
  @override
  Future<JDAnalysisResult> analyzeJobDescription({
    required String rawText,
    required String companyName,
    required ResumeEntity resume,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final lowerText = rawText.toLowerCase();
    final candidateSkillsLower = resume.skills.map((s) => s.toLowerCase()).toSet();

    // Standard high-value engineering skills to check
    final potentialJdSkills = [
      'Flutter',
      'Dart',
      'Firebase',
      'REST APIs',
      'Provider',
      'Riverpod',
      'BLoC',
      'Clean Architecture',
      'GraphQL',
      'Offline Sync',
      'CI/CD',
      'Unit Testing',
      'TypeScript',
      'Node.js',
      'Docker',
      'PostgreSQL',
      'Microservices',
      'State Management',
      'Performance Optimization',
      'Git',
    ];

    final matched = <String>[];
    final gaps = <String>[];

    for (final skill in potentialJdSkills) {
      if (lowerText.contains(skill.toLowerCase())) {
        if (candidateSkillsLower.contains(skill.toLowerCase())) {
          matched.add(skill);
        } else {
          gaps.add(skill);
        }
      }
    }

    // Default fallbacks if text is short
    if (matched.isEmpty) {
      matched.addAll(['Flutter', 'Dart', 'REST APIs', 'Firebase']);
    }
    if (gaps.isEmpty) {
      gaps.addAll(['Clean Architecture', 'Offline Sync & SQLite', 'CI/CD Automation']);
    }

    final totalFound = matched.length + gaps.length;
    final calculatedScore = totalFound > 0 ? ((matched.length / totalFound) * 100).round() : 75;
    final matchScore = calculatedScore.clamp(65, 94);

    final title = lowerText.contains('senior')
        ? 'Senior Flutter Engineer'
        : lowerText.contains('lead')
            ? 'Lead Mobile Developer'
            : lowerText.contains('backend')
                ? 'Backend Engineer'
                : 'Mobile Software Engineer (Flutter)';

    return JDAnalysisResult(
      jobTitle: title,
      companyName: companyName,
      matchScore: matchScore,
      matchedSkills: matched,
      skillGaps: gaps,
      recommendedTopics: [
        'Clean Architecture & Dependency Inversion in Flutter',
        'Offline-First Data Synchronization & Conflict Resolution',
        'Custom CI/CD Pipelines with Fastlane & GitHub Actions',
        'Memory Leak Profiling & Widget Rebuild Optimization',
      ],
      preparationRoadmap: [
        'Review Clean Architecture layered boundaries (Domain, Data, Presentation).',
        'Prepare 2 concrete examples of handling intermittent network drops.',
        'Review $companyName interview culture values and technical question patterns.',
        'Practice 1 mock interview session focusing on your weak areas ($gaps).',
      ],
      customQuestions: [
        'The job description emphasizes scalable architecture. Walk me through how you isolate business logic from UI widgets in large apps.',
        'We noticed $companyName requires handling offline data. How do you design an offline cache with SQLite and sync state with backend APIs?',
        'Tell me about a time you optimized app startup time and frame render performance in Flutter.',
        'How do you write testable code using Dependency Injection and Mock repositories?',
      ],
      summaryAssessment:
          'Your resume strongly matches the core framework and language requirements (${matched.take(3).join(', ')}). To maximize your offer probability, focus on deep-dive questions around ${gaps.take(2).join(' and ')}.',
    );
  }
}
