import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_config.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getProfile();
  Future<ProfileModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ProfileModel?> getProfile() async {
    final response = await _apiClient.get(ApiConfig.profileEndpoint);
    // response.data is { profile: {...} | null }
    final data = response.data as Map<String, dynamic>?;
    final profileJson = data?['profile'];
    if (profileJson == null) return null;
    return ProfileModel.fromJson(profileJson as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (targetRole != null) 'targetRole': targetRole,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (bio != null) 'bio': bio,
    };

    final response = await _apiClient.put(ApiConfig.profileEndpoint, body: body);
    final data = response.data as Map<String, dynamic>;
    return ProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
  }
}
