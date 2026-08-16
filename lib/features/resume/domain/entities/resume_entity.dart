enum ResumeSource { upload, paste }
enum ResumeStatus { ready, analyzing }

class ResumeProjectItem {
  final String title;
  final String role;
  final String description;
  final List<String> techStack;

  const ResumeProjectItem({
    required this.title,
    required this.role,
    required this.description,
    required this.techStack,
  });
}

class ResumeEntity {
  final String id;
  final String name;
  final ResumeSource source;
  final ResumeStatus status;
  final bool isDefault;
  final String uploadedDate;
  final String fileSize;
  final String summary;
  final List<String> skills;
  final List<String> frameworks;
  final List<String> databases;
  final List<String> tools;
  final String experience;
  final String education;
  final int projects;
  final List<ResumeProjectItem> projectItems;

  const ResumeEntity({
    required this.id,
    required this.name,
    required this.source,
    required this.status,
    this.isDefault = false,
    this.uploadedDate = 'Aug 12, 2026',
    this.fileSize = '1.2 MB',
    this.summary = 'Passionate Flutter & mobile engineer with hands-on experience in Clean Architecture, state management, and real-time backend integrations.',
    required this.skills,
    this.frameworks = const ['Flutter SDK', 'Provider', 'Riverpod', 'BLoC'],
    this.databases = const ['Firebase Firestore', 'PostgreSQL', 'SQLite / Hive'],
    this.tools = const ['Git', 'Postman', 'Figma', 'CI/CD Pipelines'],
    required this.experience,
    this.education = 'B.Tech / B.Sc in Computer Science',
    required this.projects,
    this.projectItems = const [
      ResumeProjectItem(
        title: 'OTT Mobile Streaming Engine',
        role: 'Lead Mobile Architect',
        description: 'Architected offline caching, video player controls, and REST API network layer with 99.8% crash-free sessions.',
        techStack: ['Flutter', 'Dart', 'Provider', 'REST APIs'],
      ),
      ResumeProjectItem(
        title: 'FinTech Secure Payment Wallet',
        role: 'Frontend Engineer',
        description: 'Implemented end-to-end tokenization, biometrics authentication, and responsive state synchronization.',
        techStack: ['Flutter', 'Firebase', 'Clean Architecture', 'Supabase'],
      ),
    ],
  });

  ResumeEntity copyWith({
    String? id,
    String? name,
    ResumeSource? source,
    ResumeStatus? status,
    bool? isDefault,
    String? uploadedDate,
    String? fileSize,
    String? summary,
    List<String>? skills,
    List<String>? frameworks,
    List<String>? databases,
    List<String>? tools,
    String? experience,
    String? education,
    int? projects,
    List<ResumeProjectItem>? projectItems,
  }) {
    return ResumeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      uploadedDate: uploadedDate ?? this.uploadedDate,
      fileSize: fileSize ?? this.fileSize,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      frameworks: frameworks ?? this.frameworks,
      databases: databases ?? this.databases,
      tools: tools ?? this.tools,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      projects: projects ?? this.projects,
      projectItems: projectItems ?? this.projectItems,
    );
  }

  static ResumeEntity defaultResume() => const ResumeEntity(
        id: 'res_default',
        name: 'Meraj_Resume_Flutter.pdf',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        isDefault: true,
        uploadedDate: 'Aug 14, 2026',
        fileSize: '1.4 MB',
        summary: 'Mobile engineer specializing in Flutter, Dart, Clean Architecture, and high-performance cross-platform apps.',
        skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase', 'Clean Architecture'],
        frameworks: ['Flutter SDK', 'Provider', 'Riverpod', 'Bloc'],
        databases: ['Firebase Firestore', 'PostgreSQL', 'Hive'],
        tools: ['Git', 'Postman', 'Docker', 'Figma'],
        experience: '1.2 years',
        education: 'B.Sc in Computer Science',
        projects: 5,
      );

  static ResumeEntity secondaryResume() => const ResumeEntity(
        id: 'res_fullstack',
        name: 'Meraj_FullStack_Profile.pdf',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        isDefault: false,
        uploadedDate: 'Aug 08, 2026',
        fileSize: '1.1 MB',
        summary: 'Full Stack engineer with experience across Node.js backend services, React frontends, and mobile integration.',
        skills: ['TypeScript', 'Node.js', 'React', 'Flutter', 'PostgreSQL', 'Docker'],
        frameworks: ['Express', 'Next.js', 'Flutter'],
        databases: ['PostgreSQL', 'Redis', 'MongoDB'],
        tools: ['Git', 'Docker', 'AWS', 'Jest'],
        experience: '2.0 years',
        education: 'B.Sc in Computer Science',
        projects: 6,
      );
}
