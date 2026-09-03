import 'package:flutter/material.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/profile_model.dart';

enum ProfileStatus { initial, loading, loaded, saving, error }

/// The single source of truth for all user profile data across the app.
///
/// Loaded immediately after authentication and available to every screen
/// via Provider. Signup, manual setup, and resume upload all write here.
class ProfileController extends ChangeNotifier {
  final ProfileRemoteDataSource _dataSource;

  ProfileModel? _profile;
  ProfileStatus _status = ProfileStatus.initial;
  String? _errorMessage;

  ProfileController({required ProfileRemoteDataSource dataSource})
      : _dataSource = dataSource;

  ProfileModel? get profile => _profile;
  ProfileStatus get status => _status;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.saving;
  String? get errorMessage => _errorMessage;

  // ── Derived display values (safe, never null) ─────────────────────────────

  String get fullName => _profile?.fullName ?? '';
  String get initials => _profile?.initials ?? '';
  String get targetRole => _profile?.targetRole ?? '';
  String get bio => _profile?.bio ?? '';
  String get phone => _profile?.phone ?? '';
  double? get experienceYears => _profile?.experienceYears;
  String get experienceLabel => _profile?.experienceLabel ?? '';
  List<String> get skills => _profile?.skills ?? [];
  List<EducationItem> get education => _profile?.education ?? [];
  List<ProjectItem> get projects => _profile?.projects ?? [];
  List<CertificationItem> get certifications => _profile?.certifications ?? [];

  /// True once we have a profile with at least a role and skills set.
  bool get isProfileComplete => _profile?.isComplete ?? false;

  /// True if the user has already provided profile details (role or skills).
  bool get hasProfileData => _profile?.hasProfileData ?? false;

  // ── Load profile from backend ─────────────────────────────────────────────

  Future<void> loadProfile() async {
    if (_status == ProfileStatus.loading) return;

    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _dataSource.getProfile();
      if (fetched != null) {
        _profile = fetched;
      }
      _status = ProfileStatus.loaded;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _status = ProfileStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // ── Update profile on backend ─────────────────────────────────────────────

  Future<bool> updateProfile({
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
    _status = ProfileStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _dataSource.updateProfile(
        fullName: fullName,
        phone: phone,
        targetRole: targetRole,
        experienceYears: experienceYears,
        bio: bio,
        skills: skills,
        education: education,
        projects: projects,
        certifications: certifications,
      );
      _status = ProfileStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Merge resume data — safe, non-destructive ─────────────────────────────

  /// Merges resume-extracted data into the existing profile.
  /// User-provided values are NEVER overwritten by this call.
  Future<bool> mergeResumeProfile({
    String? fullName,
    String? targetRole,
    double? experienceYears,
    String? bio,
    List<String>? skills,
    List<EducationItem>? education,
    List<ProjectItem>? projects,
    List<CertificationItem>? certifications,
  }) async {
    _status = ProfileStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _dataSource.mergeResumeProfile(
        fullName: fullName,
        targetRole: targetRole,
        experienceYears: experienceYears,
        bio: bio,
        skills: skills,
        education: education,
        projects: projects,
        certifications: certifications,
      );
      _status = ProfileStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Apply signup/auth user data to the in-memory profile snapshot
  /// without a network round-trip. Called after login/signup when the
  /// profile endpoint has not yet been fetched.
  void applyAuthUserData({
    required String name,
    required String email,
  }) {
    final effectiveName = name.trim().isNotEmpty
        ? name.trim()
        : (email.contains('@') ? email.split('@').first : 'User');

    if (_profile == null) {
      _profile = ProfileModel(
        id: '',
        userId: '',
        fullName: effectiveName,
      );
      notifyListeners();
    } else if (_profile!.fullName == null || _profile!.fullName!.trim().isEmpty) {
      _profile = _profile!.copyWith(fullName: effectiveName);
      notifyListeners();
    }
  }

  // ── Clear (on logout) ────────────────────────────────────────────────────

  void clear() {
    _profile = null;
    _status = ProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  String _extractMessage(dynamic e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}
