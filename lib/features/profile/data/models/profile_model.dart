/// Represents the full unified user profile — single source of truth
/// for all profile data across the entire application.
///
/// Fields map 1-to-1 to the backend `user_profiles` table.
class ProfileModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;
  final String? targetRole;
  final double? experienceYears;
  final String? bio;
  // ── Extended unified profile fields ────────────────────────────────────────
  final List<String> skills;
  final List<EducationItem> education;
  final List<ProjectItem> projects;
  final List<CertificationItem> certifications;
  // ── Timestamps ─────────────────────────────────────────────────────────────
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
    this.targetRole,
    this.experienceYears,
    this.bio,
    this.skills = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ── Derived display helpers ────────────────────────────────────────────────

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty)
      ? fullName!.trim()
      : '';

  String get initials {
    final name = displayName;
    if (name.isEmpty) return '';
    return name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
  }

  String get experienceLabel {
    if (experienceYears == null) return '';
    final yrs = experienceYears!;
    if (yrs == yrs.truncateToDouble()) {
      return '${yrs.toInt()} year${yrs != 1 ? 's' : ''}';
    }
    return '$yrs years';
  }

  bool get isComplete =>
      targetRole != null && targetRole!.isNotEmpty && skills.isNotEmpty;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      targetRole: json['targetRole'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      skills: _parseStringList(json['skills']),
      education: _parseEducation(json['education']),
      projects: _parseProjects(json['projects']),
      certifications: _parseCertifications(json['certifications']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'fullName': fullName,
        'phone': phone,
        'targetRole': targetRole,
        'experienceYears': experienceYears,
        'bio': bio,
        'skills': skills,
        'education': education.map((e) => e.toJson()).toList(),
        'projects': projects.map((p) => p.toJson()).toList(),
        'certifications': certifications.map((c) => c.toJson()).toList(),
      };

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      targetRole: targetRole ?? this.targetRole,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Private parsing helpers ───────────────────────────────────────────────

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  static List<EducationItem> _parseEducation(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(EducationItem.fromJson)
          .toList();
    }
    return [];
  }

  static List<ProjectItem> _parseProjects(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ProjectItem.fromJson)
          .toList();
    }
    return [];
  }

  static List<CertificationItem> _parseCertifications(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CertificationItem.fromJson)
          .toList();
    }
    return [];
  }
}

// ── Supporting value objects ──────────────────────────────────────────────────

class EducationItem {
  final String degree;
  final String institution;
  final String year;

  const EducationItem({
    this.degree = '',
    this.institution = '',
    this.year = '',
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
        degree: json['degree'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        year: json['year'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'year': year,
      };

  EducationItem copyWith({String? degree, String? institution, String? year}) =>
      EducationItem(
        degree: degree ?? this.degree,
        institution: institution ?? this.institution,
        year: year ?? this.year,
      );
}

class ProjectItem {
  final String name;
  final String description;
  final List<String> technologies;

  const ProjectItem({
    this.name = '',
    this.description = '',
    this.technologies = const [],
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        technologies: (json['technologies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'technologies': technologies,
      };
}

class CertificationItem {
  final String name;
  final String issuer;
  final String year;

  const CertificationItem({
    this.name = '',
    this.issuer = '',
    this.year = '',
  });

  factory CertificationItem.fromJson(Map<String, dynamic> json) =>
      CertificationItem(
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        year: json['year'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'issuer': issuer,
        'year': year,
      };
}
