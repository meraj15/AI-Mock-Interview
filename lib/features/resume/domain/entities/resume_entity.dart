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
    this.candidateName = '',
    this.email = '',
    this.phone = '',
    this.linkedinUrl,
    this.githubUrl,
    required this.source,
    required this.status,
    this.isDefault = false,
    this.uploadedDate = '',
    this.fileSize = '',
    this.summary = '',
    required this.skills,
    this.languages = const [],
    this.frameworks = const [],
    this.databases = const [],
    this.cloudTools = const [],
    this.tools = const [],
    required this.experience,
    this.education = '',
    required this.projects,
    this.confidenceScore = 90,
    this.projectItems = const [],
    this.workExperiences = const [],
    this.certifications = const [],
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
}
