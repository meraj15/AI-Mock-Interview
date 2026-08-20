class ProfileModel {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? targetRole;
  final double? experienceYears;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.phone,
    this.targetRole,
    this.experienceYears,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  /// Derived display helpers
  String get fullName {
    final parts = [firstName ?? '', lastName ?? '']
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : '';
  }

  String get initials {
    final name = fullName;
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      targetRole: json['targetRole'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
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
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'targetRole': targetRole,
        'experienceYears': experienceYears,
        'bio': bio,
      };

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      targetRole: targetRole ?? this.targetRole,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
