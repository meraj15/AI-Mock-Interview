import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/dashboard/presentation/pages/main_nav_page.dart';
import 'features/interview/presentation/controllers/interview_controller.dart';
import 'features/profile/presentation/controllers/theme_controller.dart';
import 'features/resume/presentation/controllers/resume_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Data sources
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences: sharedPreferences);

  // Repositories
  final authRepository = AuthRepositoryImpl(localDataSource: authLocalDataSource);

  // Use cases
  final getAuthStateUseCase = GetAuthStateUseCase(authRepository);
  final signInUseCase = SignInUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(authRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(sharedPreferences: sharedPreferences),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            getAuthStateUseCase: getAuthStateUseCase,
            signInUseCase: signInUseCase,
            signUpUseCase: signUpUseCase,
            signOutUseCase: signOutUseCase,
            completeOnboardingUseCase: completeOnboardingUseCase,
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => InterviewController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ResumeController(),
        ),
      ],
      child: const InterviewCoachApp(),
    ),
  );
}

class InterviewCoachApp extends StatelessWidget {
  const InterviewCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final authCtrl = context.watch<AuthController>();

    Widget initialScreen;
    if (authCtrl.isLoading) {
      initialScreen = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (!authCtrl.isOnboarded) {
      initialScreen = const OnboardingPage();
    } else if (!authCtrl.isAuthenticated) {
      initialScreen = const LoginPage();
    } else {
      initialScreen = const MainNavPage();
    }

    return MaterialApp(
      title: 'Interview Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeCtrl.flutterThemeMode,
      home: initialScreen,
    );
  }
}
