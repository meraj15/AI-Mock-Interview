import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_config.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getProfile();

  Future<ProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
  });

  /// Merges resume-extracted data into the user's existing profile.
  /// Existing user-provided values are NOT overwritten — only empty fields
  /// are filled from the resume data.
  Future<ProfileModel> mergeResumeProfile({
    String? fullName,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ProfileModel?> getProfile() async {
    final response = await _apiClient.get(ApiConfig.profileEndpoint);
    final data = response.data as Map<String, dynamic>?;
    final profileJson = data?['data'] is Map<String, dynamic>
        ? (data!['data'] as Map<String, dynamic>)['profile']
        : data?['profile'];
    if (profileJson == null) return null;
    return ProfileModel.fromJson(profileJson as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (targetRole != null) 'targetRole': targetRole,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (skills != null) 'skills': skills,
      if (education != null) 'education': education.map((e) => e.toJson()).toList(),
      if (projects != null) 'projects': projects.map((p) => p.toJson()).toList(),
      if (certifications != null) 'certifications': certifications.map((c) => c.toJson()).toList(),
    };

    final response = await _apiClient.put(ApiConfig.profileEndpoint, body: body);
    final data = response.data as Map<String, dynamic>;
    final profileJson = data['data'] is Map<String, dynamic>
        ? (data['data'] as Map<String, dynamic>)['profile']
        : data['profile'];
    return ProfileModel.fromJson(profileJson as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> mergeResumeProfile({
    String? fullName,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (targetRole != null) 'targetRole': targetRole,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
      if (skills != null) 'skills': skills,
      if (education != null) 'education': education.map((e) => e.toJson()).toList(),
      if (projects != null) 'projects': projects.map((p) => p.toJson()).toList(),
      if (certifications != null) 'certifications': certifications.map((c) => c.toJson()).toList(),
    };

    final response = await _apiClient.post(ApiConfig.profileMergeResumeEndpoint, body: body);
    final data = response.data as Map<String, dynamic>;
    final profileJson = data['data'] is Map<String, dynamic>
        ? (data['data'] as Map<String, dynamic>)['profile']
        : data['profile'];
    return ProfileModel.fromJson(profileJson as Map<String, dynamic>);
  }
}
