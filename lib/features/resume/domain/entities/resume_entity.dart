enum ResumeSource { upload, paste }
enum ResumeStatus { ready, analyzing }

class ResumeWorkExperience {
  final String company;
  final String role;
  final String duration;
  final String location;
  final List<String> responsibilities;
  final List<String> technologiesUsed;

  const ResumeWorkExperience({
    required this.company,
    required this.role,
    required this.duration,
    this.location = 'Remote / Hybrid',
    required this.responsibilities,
    required this.technologiesUsed,
  });

  ResumeWorkExperience copyWith({
    String? company,
    String? role,
    String? duration,
    String? location,
    List<String>? responsibilities,
    List<String>? technologiesUsed,
  }) {
    return ResumeWorkExperience(
      company: company ?? this.company,
      role: role ?? this.role,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      responsibilities: responsibilities ?? this.responsibilities,
      technologiesUsed: technologiesUsed ?? this.technologiesUsed,
    );
  }
}

class ResumeCertification {
  final String name;
  final String issuer;
  final String issueYear;
  final String? credentialUrl;

  const ResumeCertification({
    required this.name,
    required this.issuer,
    required this.issueYear,
    this.credentialUrl,
  });
}

class ResumeProjectItem {
  final String title;
  final String role;
  final String description;
  final List<String> techStack;
  final String? metricAchievement;

  const ResumeProjectItem({
    required this.title,
    required this.role,
    required this.description,
    required this.techStack,
    this.metricAchievement,
  });

  ResumeProjectItem copyWith({
    String? title,
    String? role,
    String? description,
    List<String>? techStack,
    String? metricAchievement,
  }) {
    return ResumeProjectItem(
      title: title ?? this.title,
      role: role ?? this.role,
      description: description ?? this.description,
      techStack: techStack ?? this.techStack,
      metricAchievement: metricAchievement ?? this.metricAchievement,
    );
  }
}

class ResumeEntity {
  final String id;
  final String name;
  final String candidateName;
  final String email;
  final String phone;
  final String? linkedinUrl;
  final String? githubUrl;
  final ResumeSource source;
  final ResumeStatus status;
  final bool isDefault;
  final String uploadedDate;
  final String fileSize;
  final String summary;
  final List<String> skills;
  final List<String> languages;
  final List<String> frameworks;
  final List<String> databases;
  final List<String> cloudTools;
  final List<String> tools;
  final String experience;
  final String education;
  final int projects;
  final List<ResumeProjectItem> projectItems;
  final List<ResumeWorkExperience> workExperiences;
  final List<ResumeCertification> certifications;
  final int confidenceScore;

  const ResumeEntity({
    required this.id,
    required this.name,
    this.candidateName = 'Meraj Khan',
    this.email = 'meraj.khan@email.com',
    this.phone = '+1 (555) 349-2810',
    this.linkedinUrl = 'linkedin.com/in/merajkhan',
    this.githubUrl = 'github.com/meraj15',
    required this.source,
    required this.status,
    this.isDefault = false,
    this.uploadedDate = 'Aug 14, 2026',
    this.fileSize = '1.4 MB',
    this.summary =
        'Passionate Flutter & mobile engineer with hands-on experience in Clean Architecture, state management (Provider, Riverpod, BLoC), and resilient REST API integrations.',
    required this.skills,
    this.languages = const ['Dart', 'Kotlin', 'TypeScript', 'Java', 'Python'],
    this.frameworks = const ['Flutter SDK', 'Provider', 'Riverpod', 'BLoC', 'Express.js'],
    this.databases = const ['Firebase Firestore', 'PostgreSQL', 'SQLite', 'Hive'],
    this.cloudTools = const ['AWS S3', 'Docker', 'GitHub Actions', 'Fastlane', 'Supabase'],
    this.tools = const ['Git', 'Postman', 'Figma', 'VS Code', 'Android Studio'],
    required this.experience,
    this.education = 'B.Tech / B.Sc in Computer Science (2022–2026)',
    required this.projects,
    this.confidenceScore = 96,
    this.projectItems = const [
      ResumeProjectItem(
        title: 'OTT Mobile Streaming Engine',
        role: 'Lead Mobile Architect',
        description:
            'Architected offline caching, video player controls, and REST API network layer with 99.8% crash-free sessions.',
        techStack: ['Flutter', 'Dart', 'Provider', 'REST APIs', 'Hive'],
        metricAchievement: 'Reduced video buffer latency by 35% and supported 50k+ active daily users.',
      ),
      ResumeProjectItem(
        title: 'FinTech Secure Payment Wallet',
        role: 'Frontend Mobile Engineer',
        description:
            'Implemented end-to-end tokenization, biometrics authentication, and responsive state synchronization.',
        techStack: ['Flutter', 'Firebase', 'Clean Architecture', 'Supabase'],
        metricAchievement: 'Passed PCI-DSS security compliance with zero high-severity audit vulnerabilities.',
      ),
    ],
    this.workExperiences = const [
      ResumeWorkExperience(
        company: 'Nova Mobile Labs',
        role: 'Software Engineer (Flutter)',
        duration: 'Jun 2024 – Present',
        location: 'Bengaluru, India',
        responsibilities: [
          'Developed and shipped 3 production Flutter cross-platform applications for iOS and Android.',
          'Reduced API payload size and latency by 40% through local SQLite caching and repository pattern.',
          'Collaborated with design and backend teams to implement automated CI/CD deployment pipelines.',
        ],
        technologiesUsed: ['Flutter', 'Dart', 'Clean Architecture', 'Provider', 'Firebase', 'CI/CD'],
      ),
      ResumeWorkExperience(
        company: 'AppVenture Studio',
        role: 'Mobile Development Intern',
        duration: 'Jan 2024 – May 2024',
        location: 'Remote',
        responsibilities: [
          'Built responsive UI components and integrated RESTful endpoints with error handling.',
          'Wrote unit and widget tests achieving 82% code coverage across core user flows.',
        ],
        technologiesUsed: ['Flutter', 'REST APIs', 'Git', 'Dart'],
      ),
    ],
    this.certifications = const [
      ResumeCertification(
        name: 'Meta Certified Mobile Engineer',
        issuer: 'Meta / Coursera',
        issueYear: '2025',
      ),
      ResumeCertification(
        name: 'Associate Android Developer',
        issuer: 'Google Developers',
        issueYear: '2024',
      ),
    ],
  });

  ResumeEntity copyWith({
    String? id,
    String? name,
    String? candidateName,
    String? email,
    String? phone,
    String? linkedinUrl,
    String? githubUrl,
    ResumeSource? source,
    ResumeStatus? status,
    bool? isDefault,
    String? uploadedDate,
    String? fileSize,
    String? summary,
    List<String>? skills,
    List<String>? languages,
    List<String>? frameworks,
    List<String>? databases,
    List<String>? cloudTools,
    List<String>? tools,
    String? experience,
    String? education,
    int? projects,
    List<ResumeProjectItem>? projectItems,
    List<ResumeWorkExperience>? workExperiences,
    List<ResumeCertification>? certifications,
    int? confidenceScore,
  }) {
    return ResumeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      candidateName: candidateName ?? this.candidateName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      source: source ?? this.source,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      uploadedDate: uploadedDate ?? this.uploadedDate,
      fileSize: fileSize ?? this.fileSize,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      frameworks: frameworks ?? this.frameworks,
      databases: databases ?? this.databases,
      cloudTools: cloudTools ?? this.cloudTools,
      tools: tools ?? this.tools,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      projects: projects ?? this.projects,
      projectItems: projectItems ?? this.projectItems,
      workExperiences: workExperiences ?? this.workExperiences,
      certifications: certifications ?? this.certifications,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  static ResumeEntity defaultResume() => const ResumeEntity(
        id: 'res_default',
        name: 'Meraj_Resume_Flutter.pdf',
        candidateName: 'Meraj Khan',
        email: 'meraj.khan@email.com',
        phone: '+1 (555) 349-2810',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        isDefault: true,
        uploadedDate: 'Aug 14, 2026',
        fileSize: '1.4 MB',
        summary:
            'Mobile engineer specializing in Flutter, Dart, Clean Architecture, responsive UI design, and high-performance cross-platform apps.',
        skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase', 'Clean Architecture', 'Riverpod'],
        languages: ['Dart', 'Kotlin', 'TypeScript', 'Java'],
        frameworks: ['Flutter SDK', 'Provider', 'Riverpod', 'BLoC'],
        databases: ['Firebase Firestore', 'PostgreSQL', 'Hive', 'SQLite'],
        cloudTools: ['AWS', 'Docker', 'Fastlane', 'GitHub Actions'],
        tools: ['Git', 'Postman', 'Figma', 'VS Code'],
        experience: '1.2 years',
        education: 'B.Sc in Computer Science (2022–2026)',
        projects: 5,
        confidenceScore: 96,
      );

  static ResumeEntity secondaryResume() => const ResumeEntity(
        id: 'res_fullstack',
        name: 'Meraj_FullStack_Profile.pdf',
        candidateName: 'Meraj Khan',
        email: 'meraj.khan@email.com',
        source: ResumeSource.upload,
        status: ResumeStatus.ready,
        isDefault: false,
        uploadedDate: 'Aug 08, 2026',
        fileSize: '1.1 MB',
        summary:
            'Full Stack engineer with hands-on experience across Node.js backend services, React frontends, and Flutter mobile applications.',
        skills: ['TypeScript', 'Node.js', 'React', 'Flutter', 'PostgreSQL', 'Docker', 'Express', 'Redis'],
        languages: ['TypeScript', 'JavaScript', 'Dart', 'SQL'],
        frameworks: ['Express', 'Next.js', 'Flutter', 'React'],
        databases: ['PostgreSQL', 'Redis', 'MongoDB'],
        cloudTools: ['Docker', 'AWS S3', 'Vercel'],
        tools: ['Git', 'Docker', 'Postman', 'Jest'],
        experience: '2.0 years',
        education: 'B.Sc in Computer Science (2022–2026)',
        projects: 6,
        confidenceScore: 92,
      );
}
