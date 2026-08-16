enum ResumeSource { upload, paste }
enum ResumeStatus { ready, analyzing }

class ResumeEntity {
  final String name;
  final ResumeSource source;
  final ResumeStatus status;
  final List<String> skills;
  final String experience;
  final int projects;

  const ResumeEntity({
    required this.name,
    required this.source,
    required this.status,
    required this.skills,
    required this.experience,
    required this.projects,
  });

  ResumeEntity copyWith({
    String? name,
    ResumeSource? source,
    ResumeStatus? status,
    List<String>? skills,
    String? experience,
    int? projects,
  }) {
    return ResumeEntity(
      name: name ?? this.name,
      source: source ?? this.source,
      status: status ?? this.status,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      projects: projects ?? this.projects,
    );
  }

  static ResumeEntity initial() => const ResumeEntity(
        name: 'Meraj_Resume.pdf',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase'],
        experience: '1.2 years',
        projects: 5,
      );
}
