import '../../features/resume/domain/entities/resume_entity.dart';

enum ParsingStage {
  readingDocument,
  extractingSkills,
  analyzingExperience,
  finalizingProfile,
  completed,
}

class ParsingProgress {
  final ParsingStage stage;
  final String stageMessage;
  final double progressPercent;

  const ParsingProgress({
    required this.stage,
    required this.stageMessage,
    required this.progressPercent,
  });
}

abstract class ResumeParsingService {
  Future<ResumeEntity> parseDocument({
    required String fileName,
    required String fileSizeBytes,
    required Function(ParsingProgress progress) onProgress,
  });

  Future<ResumeEntity> parseRawText({
    required String rawText,
    required Function(ParsingProgress progress) onProgress,
  });
}

class MockResumeParsingService implements ResumeParsingService {
  @override
  Future<ResumeEntity> parseDocument({
    required String fileName,
    required String fileSizeBytes,
    required Function(ParsingProgress progress) onProgress,
  }) async {
    onProgress(const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Extracting text and structure from file…',
      progressPercent: 0.25,
    ));
    await Future.delayed(const Duration(milliseconds: 600));

    onProgress(const ParsingProgress(
      stage: ParsingStage.extractingSkills,
      stageMessage: 'Identifying programming languages, frameworks & tools…',
      progressPercent: 0.50,
    ));
    await Future.delayed(const Duration(milliseconds: 600));

    onProgress(const ParsingProgress(
      stage: ParsingStage.analyzingExperience,
      stageMessage: 'Analyzing work history, projects & metrics…',
      progressPercent: 0.75,
    ));
    await Future.delayed(const Duration(milliseconds: 600));

    onProgress(const ParsingProgress(
      stage: ParsingStage.finalizingProfile,
      stageMessage: 'Synthesizing verified candidate profile…',
      progressPercent: 0.95,
    ));
    await Future.delayed(const Duration(milliseconds: 400));

    onProgress(const ParsingProgress(
      stage: ParsingStage.completed,
      stageMessage: 'Resume analysis complete!',
      progressPercent: 1.0,
    ));

    final isFullStack = fileName.toLowerCase().contains('fullstack') || fileName.toLowerCase().contains('web');
    final newId = 'res_${DateTime.now().millisecondsSinceEpoch}';

    if (isFullStack) {
      return ResumeEntity(
        id: newId,
        name: fileName,
        candidateName: 'Meraj Khan',
        email: 'meraj.khan@email.com',
        phone: '+1 (555) 349-2810',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        isDefault: true,
        uploadedDate: 'Today',
        fileSize: fileSizeBytes,
        summary:
            'Full Stack software engineer proficient in Node.js, Express, React, TypeScript, and Flutter with strong API design foundations.',
        skills: ['TypeScript', 'Node.js', 'React', 'Flutter', 'PostgreSQL', 'Docker', 'REST APIs', 'Clean Architecture'],
        languages: ['TypeScript', 'JavaScript', 'Dart', 'SQL', 'Python'],
        frameworks: ['Express.js', 'React', 'Flutter SDK', 'Next.js'],
        databases: ['PostgreSQL', 'Redis', 'MongoDB'],
        cloudTools: ['Docker', 'AWS', 'GitHub Actions'],
        tools: ['Git', 'Postman', 'VS Code', 'Jest'],
        experience: '2.0 years',
        education: 'B.Sc in Computer Science (2022–2026)',
        projects: 6,
        confidenceScore: 95,
      );
    }

    return ResumeEntity(
      id: newId,
      name: fileName,
      candidateName: 'Meraj Khan',
      email: 'meraj.khan@email.com',
      phone: '+1 (555) 349-2810',
      source: ResumeSource.upload,
      status: ResumeStatus.ready,
      isDefault: true,
      uploadedDate: 'Today',
      fileSize: fileSizeBytes,
      summary:
          'Mobile engineer with deep specialization in Flutter, Dart, Clean Architecture, Provider/Riverpod state management, and real-time backend integrations.',
      skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Riverpod', 'Clean Architecture', 'Bloc'],
      languages: ['Dart', 'Kotlin', 'TypeScript', 'Java'],
      frameworks: ['Flutter SDK', 'Provider', 'Riverpod', 'BLoC'],
      databases: ['Firebase Firestore', 'PostgreSQL', 'SQLite', 'Hive'],
      cloudTools: ['Docker', 'AWS S3', 'Fastlane', 'GitHub Actions'],
      tools: ['Git', 'Postman', 'Figma', 'Android Studio'],
      experience: '1.5 years',
      education: 'B.Sc in Computer Science (2022–2026)',
      projects: 5,
      confidenceScore: 98,
    );
  }

  @override
  Future<ResumeEntity> parseRawText({
    required String rawText,
    required Function(ParsingProgress progress) onProgress,
  }) async {
    onProgress(const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Tokenizing and structuring pasted text…',
      progressPercent: 0.30,
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    onProgress(const ParsingProgress(
      stage: ParsingStage.extractingSkills,
      stageMessage: 'Extracting matched skills, tools and domains…',
      progressPercent: 0.65,
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    onProgress(const ParsingProgress(
      stage: ParsingStage.finalizingProfile,
      stageMessage: 'Normalizing candidate profile format…',
      progressPercent: 0.95,
    ));
    await Future.delayed(const Duration(milliseconds: 400));

    final newId = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final previewSummary = rawText.length > 130 ? '${rawText.substring(0, 130)}…' : rawText;

    return ResumeEntity(
      id: newId,
      name: 'Pasted_Text_Resume.txt',
      candidateName: 'Meraj Khan',
      email: 'meraj.khan@email.com',
      source: ResumeSource.paste,
      status: ResumeStatus.ready,
      isDefault: true,
      uploadedDate: 'Today',
      fileSize: '${(rawText.length / 1024).toStringAsFixed(1)} KB',
      summary: previewSummary,
      skills: ['Flutter', 'Dart', 'State Management', 'REST APIs', 'Firebase', 'Clean Architecture'],
      languages: ['Dart', 'Kotlin', 'TypeScript'],
      frameworks: ['Flutter SDK', 'Provider', 'Riverpod'],
      databases: ['Firebase Firestore', 'SQLite'],
      tools: ['Git', 'Postman', 'Figma'],
      experience: '1.5 years',
      education: 'B.Sc in Computer Science',
      projects: 4,
      confidenceScore: 92,
    );
  }
}
