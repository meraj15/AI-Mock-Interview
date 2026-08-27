import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/interview/presentation/controllers/interview_controller.dart';
import 'features/interview/data/datasources/interview_remote_data_source.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/job_prep/presentation/controllers/job_prep_controller.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/profile/presentation/controllers/theme_controller.dart';
import 'features/resume/data/datasources/resume_remote_data_source.dart';
import 'features/resume/presentation/controllers/resume_controller.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // ── Restore previously-discovered backend host ────────────────────────────
  // This prevents the 3-candidate host-discovery loop from firing on every
  // cold-start. After the first successful connection, the working host is
  // persisted and reloaded here.
  const resolvedHostKey = 'ic_resolved_backend_host';
  final savedHost = sharedPreferences.getString(resolvedHostKey);
  ApiConfig.restoreResolvedBaseUrl(savedHost);

  // Storage & Network
  final tokenStorage = TokenStorageImpl(sharedPreferences: sharedPreferences);
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  // Data sources
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences: sharedPreferences);
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final profileRemoteDataSource = ProfileRemoteDataSourceImpl(apiClient: apiClient);
  final resumeRemoteDataSource = ResumeRemoteDataSourceImpl(tokenStorage: tokenStorage);
  final interviewRemoteDataSource = InterviewRemoteDataSourceImpl(apiClient: apiClient);

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
  final forgotPasswordUseCase = ForgotPasswordUseCase(authRepository);
  final resetPasswordUseCase = ResetPasswordUseCase(authRepository);

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
            forgotPasswordUseCase: forgotPasswordUseCase,
            resetPasswordUseCase: resetPasswordUseCase,
          )..init(),
        ),
        ChangeNotifierProxyProvider<AuthController, ProfileController>(
          create: (_) => ProfileController(
            dataSource: profileRemoteDataSource,
          ),
          update: (_, authCtrl, profileCtrl) {
            // Auto-load profile whenever the user becomes authenticated.
            // This covers login, signup, and session restore on cold-start.
            if (authCtrl.isAuthenticated) {
              profileCtrl!.loadProfile();
            } else {
              profileCtrl!.clear();
            }
            return profileCtrl;
          },
        ),
        // DashboardController owns the stats and recent sessions.
        ChangeNotifierProvider<DashboardController>(
          create: (_) {
            final dashboard = DashboardController(
              dataSource: interviewRemoteDataSource,
            );
            return dashboard;
          },
        ),
        // InterviewController is wired to call dashboard.refresh() after
        // saving a session. We use a lazy closure so the DashboardController
        // instance is captured once — no ProxyProvider needed.
        ChangeNotifierProvider<InterviewController>(
          create: (context) {
            final dashboard = context.read<DashboardController>();
            final ctrl = InterviewController(
              remoteDataSource: interviewRemoteDataSource,
              apiClient: apiClient,
            );
            ctrl.setOnSessionSaved(dashboard.refresh);
            return ctrl;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ResumeController(
            remoteDataSource: resumeRemoteDataSource,
          ),
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
