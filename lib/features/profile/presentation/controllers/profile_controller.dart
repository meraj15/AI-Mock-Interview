import 'package:flutter/material.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/profile_model.dart';

enum ProfileStatus { initial, loading, loaded, saving, error }

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

  String get fullName => _profile?.firstName ?? '';
  String get initials => _profile?.initials ?? '';
  String get targetRole => _profile?.targetRole ?? '';
  String get bio => _profile?.bio ?? '';
  String get phone => _profile?.phone ?? '';
  double? get experienceYears => _profile?.experienceYears;
  String get experienceLabel => _profile?.experienceLabel ?? '';

  // ── Load profile from backend ─────────────────────────────────────────────

  Future<void> loadProfile() async {
    if (_status == ProfileStatus.loading) return;

    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _dataSource.getProfile();
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
    String? firstName,
    String? lastName,
    String? phone,
    String? targetRole,
    double? experienceYears,
    String? bio,
  }) async {
    _status = ProfileStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _dataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        targetRole: targetRole,
        experienceYears: experienceYears,
        bio: bio,
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
