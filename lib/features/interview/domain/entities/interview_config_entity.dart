class InterviewConfigEntity {
  final String role;
  final String company;
  final String experience;
  final String difficulty;
  final int questions;
  // Phase 5 deep customization fields
  final List<String> focusTopics;
  final String language;
  final bool enableVoiceMode;
  final String aiPersona;
  final int timeLimitPerQuestion; // in seconds, 0 = no limit
  final bool showHints;
  final bool enableFollowUps;
  final String codingLanguage;

  const InterviewConfigEntity({
    required this.role,
    required this.company,
    required this.experience,
    required this.difficulty,
    required this.questions,
    this.focusTopics = const [],
    this.language = 'English',
    this.enableVoiceMode = false,
    this.aiPersona = 'Professional Interviewer',
    this.timeLimitPerQuestion = 120,
    this.showHints = false,
    this.enableFollowUps = true,
    this.codingLanguage = 'Any / No Preference',
  });

  InterviewConfigEntity copyWith({
    String? role,
    String? company,
    String? experience,
    String? difficulty,
    int? questions,
    List<String>? focusTopics,
    String? language,
    bool? enableVoiceMode,
    String? aiPersona,
    int? timeLimitPerQuestion,
    bool? showHints,
    bool? enableFollowUps,
    String? codingLanguage,
  }) {
    return InterviewConfigEntity(
      role: role ?? this.role,
      company: company ?? this.company,
      experience: experience ?? this.experience,
      difficulty: difficulty ?? this.difficulty,
      questions: questions ?? this.questions,
      focusTopics: focusTopics ?? this.focusTopics,
      language: language ?? this.language,
      enableVoiceMode: enableVoiceMode ?? this.enableVoiceMode,
      aiPersona: aiPersona ?? this.aiPersona,
      timeLimitPerQuestion: timeLimitPerQuestion ?? this.timeLimitPerQuestion,
      showHints: showHints ?? this.showHints,
      enableFollowUps: enableFollowUps ?? this.enableFollowUps,
      codingLanguage: codingLanguage ?? this.codingLanguage,
    );
  }

  static InterviewConfigEntity initial() => const InterviewConfigEntity(
        role: 'Flutter Developer',
        company: 'General interview',
        experience: '1–2 years',
        difficulty: 'Adaptive',
        questions: 10,
        focusTopics: ['State Management', 'Clean Architecture', 'Performance'],
        language: 'English',
        enableVoiceMode: false,
        aiPersona: 'Professional Interviewer',
        timeLimitPerQuestion: 120,
        showHints: false,
        enableFollowUps: true,
        codingLanguage: 'Any / No Preference',
      );

  String get timeLimitDisplay {
    if (timeLimitPerQuestion == 0) return 'No Limit';
    if (timeLimitPerQuestion < 60) return '${timeLimitPerQuestion}s';
    final mins = timeLimitPerQuestion ~/ 60;
    final secs = timeLimitPerQuestion % 60;
    return secs == 0 ? '${mins}m' : '${mins}m ${secs}s';
  }
}

class InterviewPromptEntity {
  final String primary;
  final String followUp;

  const InterviewPromptEntity({
    required this.primary,
    required this.followUp,
  });
}
