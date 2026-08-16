class InterviewConfigEntity {
  final String role;
  final String company;
  final String experience;
  final String difficulty;
  final String type;
  final int questions;

  const InterviewConfigEntity({
    required this.role,
    required this.company,
    required this.experience,
    required this.difficulty,
    required this.type,
    required this.questions,
  });

  InterviewConfigEntity copyWith({
    String? role,
    String? company,
    String? experience,
    String? difficulty,
    String? type,
    int? questions,
  }) {
    return InterviewConfigEntity(
      role: role ?? this.role,
      company: company ?? this.company,
      experience: experience ?? this.experience,
      difficulty: difficulty ?? this.difficulty,
      type: type ?? this.type,
      questions: questions ?? this.questions,
    );
  }

  static InterviewConfigEntity initial() => const InterviewConfigEntity(
        role: 'Flutter Developer',
        company: 'General interview',
        experience: '1–2 years',
        difficulty: 'Adaptive',
        type: 'Technical interview',
        questions: 10,
      );
}

class InterviewPromptEntity {
  final String primary;
  final String followUp;

  const InterviewPromptEntity({
    required this.primary,
    required this.followUp,
  });
}
