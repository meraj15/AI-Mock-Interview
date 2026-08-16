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
  bool _isLoading = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user?.isAuthenticated ?? false;
  bool get isOnboarded => _user?.isOnboarded ?? false;

  AuthController({
    required this.getAuthStateUseCase,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.completeOnboardingUseCase,
  });

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await getAuthStateUseCase(const NoParams());
    } catch (e) {
      _errorMessage = e.toString();
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

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await signOutUseCase(const NoParams());
    _user = _user?.copyWith(isAuthenticated: false);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await completeOnboardingUseCase(const NoParams());
    _user = _user?.copyWith(isOnboarded: true);
    notifyListeners();
  }
}
