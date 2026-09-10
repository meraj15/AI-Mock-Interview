import 'package:flutter/material.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthController extends ChangeNotifier {
  final GetAuthStateUseCase getAuthStateUseCase;
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;
  final CheckOnboardingUseCase checkOnboardingUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyResetOtpUseCase verifyResetOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  UserEntity? _user;
  AuthStatus _status = AuthStatus.initial;
  bool _isOnboarded = false;
  bool _isProfileSetupComplete = false;
  String? _errorMessage;
  List<String> _validationErrors = [];

  AuthController({
    required this.getAuthStateUseCase,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.completeOnboardingUseCase,
    required this.checkOnboardingUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyResetOtpUseCase,
    required this.resetPasswordUseCase,
  });

  UserEntity? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _user != null && _status == AuthStatus.authenticated;
  bool get isProfileSetupComplete => _isProfileSetupComplete;
  String? get errorMessage => _errorMessage;
  List<String> get validationErrors => _validationErrors;

  void markProfileSetupComplete() {
    _isProfileSetupComplete = true;
    if (_user != null) {
      _user = _user!.copyWith(isProfileComplete: true);
    }
    notifyListeners();
  }

  String _cleanErrorMessage(dynamic error) {
    if (error is AuthException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is ValidationException) return error.message;
    if (error is ServerException) return error.message;

    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }

  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _isOnboarded = await checkOnboardingUseCase(const NoParams());
      _user = await getAuthStateUseCase(const NoParams());
      _status = AuthStatus.authenticated;
      _isOnboarded = true;
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _errorMessage = 'Please enter both email and password.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = [];
    notifyListeners();

    try {
      _user = await signInUseCase(SignInParams(email: cleanEmail, password: cleanPassword));
      _status = AuthStatus.authenticated;
      _isOnboarded = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _user = const UserEntity(
      id: 'usr_google_1',
      name: 'Meraj Khan (Google)',
      email: 'meraj.khan@gmail.com',
      targetRole: 'Software Developer',
      experienceYears: '2.0 years',
    );
    _status = AuthStatus.authenticated;
    _isOnboarded = true;
    notifyListeners();
    return true;
  }

  Future<bool> signInWithApple() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _user = const UserEntity(
      id: 'usr_apple_1',
      name: 'Meraj Khan',
      email: 'meraj.khan@icloud.com',
      targetRole: 'Software Developer',
      experienceYears: '2.0 years',
    );
    _status = AuthStatus.authenticated;
    _isOnboarded = true;
    notifyListeners();
    return true;
  }

  /// Returns true when registration succeeds and OTP verification is required.
  /// Returns false on error.
  Future<bool> signUp(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // ── Client-side validation ──────────────────────────────────────────────
    final clientErrors = <String>[];

    if (cleanName.isEmpty) clientErrors.add('Full name is required.');
    if (cleanEmail.isEmpty) {
      clientErrors.add('Email address is required.');
    } else if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(cleanEmail)) {
      clientErrors.add('Please enter a valid email address.');
    }
    if (cleanPassword.isEmpty) clientErrors.add('Password is required.');

    if (cleanPassword.isNotEmpty) {
      if (cleanPassword.length < 8) {
        clientErrors.add('Password must be at least 8 characters.');
      }
      if (!cleanPassword.contains(RegExp(r'[A-Z]'))) {
        clientErrors.add('Password must contain at least one uppercase letter.');
      }
      if (!cleanPassword.contains(RegExp(r'[a-z]'))) {
        clientErrors.add('Password must contain at least one lowercase letter.');
      }
      if (!cleanPassword.contains(RegExp(r'[0-9]'))) {
        clientErrors.add('Password must contain at least one number.');
      }
    }

    if (clientErrors.isNotEmpty) {
      _errorMessage = clientErrors.first;
      _validationErrors = clientErrors;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = [];
    notifyListeners();

    try {
      _user = await signUpUseCase(SignUpParams(
        name: cleanName.isNotEmpty ? cleanName : 'Candidate',
        email: cleanEmail,
        password: cleanPassword,
      ));

      // Direct registration succeeds -> user is authenticated immediately
      _status = AuthStatus.authenticated;
      _isOnboarded = true;
      _validationErrors = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      if (e is ValidationException && e.errors.isNotEmpty) {
        _validationErrors = e.errors;
      } else {
        _validationErrors = [];
      }
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
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
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  /// Step 1 — Request password reset OTP (sent via email).
  Future<bool> forgotPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await forgotPasswordUseCase(cleanEmail);
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Step 2 — Verify OTP and receive short-lived resetToken.
  Future<String?> verifyResetOtp(String email, String otp) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    if (cleanEmail.isEmpty || cleanOtp.isEmpty) {
      _errorMessage = 'Please enter the 6-digit OTP sent to your email.';
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final resetToken = await verifyResetOtpUseCase(
        email: cleanEmail,
        otp: cleanOtp,
      );
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
      return resetToken;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Step 3 — Set new password using verified resetToken.
  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final cleanPassword = newPassword.trim();
    if (cleanPassword.isEmpty) {
      _errorMessage = 'Please enter a new password.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await resetPasswordUseCase(
        resetToken: resetToken.trim(),
        newPassword: cleanPassword,
      );
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await signOutUseCase(const NoParams());
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await completeOnboardingUseCase(const NoParams());
    _isOnboarded = true;
    notifyListeners();
  }
}
