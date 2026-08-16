import 'package:flutter/material.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

class AuthController extends ChangeNotifier {
  final GetAuthStateUseCase getAuthStateUseCase;
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;

  UserEntity? _user;
  bool _isLoading = true;
  bool _isOnboarded = false;
  String? _errorMessage;

  AuthController({
    required this.getAuthStateUseCase,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.completeOnboardingUseCase,
  });

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await getAuthStateUseCase(const NoParams());
      _isOnboarded = true;
    } catch (_) {
      _user = null;
      _isOnboarded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await signInUseCase(SignInParams(email: email, password: password));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _user = const UserEntity(
      id: 'usr_google_1',
      name: 'Meraj Khan (Google)',
      email: 'meraj.khan@gmail.com',
      targetRole: 'Flutter Developer',
      experienceYears: '2.0 years',
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _user = const UserEntity(
      id: 'usr_apple_1',
      name: 'Meraj Khan',
      email: 'meraj.khan@icloud.com',
      targetRole: 'Flutter Developer',
      experienceYears: '2.0 years',
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await signUpUseCase(SignUpParams(name: name, email: email, password: password));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (code.length == 6) {
      if (_user != null) {
        _user = _user!.copyWith(isEmailVerified: true);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Invalid 6-digit verification code. Please check and try again.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void updateProfile({
    String? name,
    String? targetRole,
    String? experienceYears,
    String? bio,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        name: name,
        targetRole: targetRole,
        experienceYears: experienceYears,
        bio: bio,
      );
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await signOutUseCase(const NoParams());
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await completeOnboardingUseCase(const NoParams());
    _isOnboarded = true;
    notifyListeners();
  }
}
