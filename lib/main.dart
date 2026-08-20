import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/interview/presentation/controllers/interview_controller.dart';
import 'features/job_prep/presentation/controllers/job_prep_controller.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/profile/presentation/controllers/theme_controller.dart';
import 'features/resume/presentation/controllers/resume_controller.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Storage & Network
  final tokenStorage = TokenStorageImpl(sharedPreferences: sharedPreferences);
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  // Data sources
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences: sharedPreferences);
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final profileRemoteDataSource = ProfileRemoteDataSourceImpl(apiClient: apiClient);

  // Repositories
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
    tokenStorage: tokenStorage,
  );

  // Use cases
  final getAuthStateUseCase = GetAuthStateUseCase(authRepository);
  final signInUseCase = SignInUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(authRepository);
  final checkOnboardingUseCase = CheckOnboardingUseCase(authRepository);

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
            checkOnboardingUseCase: checkOnboardingUseCase,
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(
            dataSource: profileRemoteDataSource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InterviewController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ResumeController(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobPrepController(),
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

    return MaterialApp(
      title: 'Interview Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeCtrl.flutterThemeMode,
      home: const SplashPage(),
    );
  }
}
