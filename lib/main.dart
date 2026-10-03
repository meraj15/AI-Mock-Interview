import 'package:flutter/material.dart';
import 'package:interview_coach/app.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/services/app_update_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/interview/presentation/controllers/interview_controller.dart';
import 'features/interview/data/datasources/interview_remote_data_source.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/profile/presentation/controllers/theme_controller.dart';
import 'features/resume/data/datasources/resume_remote_data_source.dart';
import 'features/resume/presentation/controllers/resume_controller.dart';
import 'features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'features/subscription/data/repositories/subscription_repository_impl.dart';
import 'features/subscription/presentation/controllers/subscription_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Storage & Network
  final tokenStorage = TokenStorageImpl(sharedPreferences: sharedPreferences);
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  // App Update Service
  AppUpdateService.instance.initialize(
    apiClient: apiClient,
    preferences: sharedPreferences,
  );

  // Data sources
  final authLocalDataSource = AuthLocalDataSourceImpl(sharedPreferences: sharedPreferences);
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final profileRemoteDataSource = ProfileRemoteDataSourceImpl(apiClient: apiClient);
  final resumeRemoteDataSource = ResumeRemoteDataSourceImpl(tokenStorage: tokenStorage);
  final interviewRemoteDataSource = InterviewRemoteDataSourceImpl(apiClient: apiClient);
  final subscriptionRemoteDataSource = SubscriptionRemoteDataSourceImpl(apiClient: apiClient);

  // Repositories
  final subscriptionRepository = SubscriptionRepositoryImpl(
    remoteDataSource: subscriptionRemoteDataSource,
  );
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
  final verifyResetOtpUseCase = VerifyResetOtpUseCase(authRepository);
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
            verifyResetOtpUseCase: verifyResetOtpUseCase,
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
        // Reacts to auth state changes: loads stats on login, clears all data on logout.
        ChangeNotifierProxyProvider<AuthController, DashboardController>(
          create: (_) => DashboardController(
            dataSource: interviewRemoteDataSource,
          ),
          update: (_, authCtrl, dashboardCtrl) {
            if (authCtrl.isAuthenticated) {
              dashboardCtrl!.load();
            } else {
              dashboardCtrl!.clear();
            }
            return dashboardCtrl;
          },
        ),
        // InterviewController is wired to call dashboard.refresh() after
        // saving a session, and clears all session state and transcripts on logout.
        ChangeNotifierProxyProvider2<AuthController, DashboardController, InterviewController>(
          create: (context) {
            final dashboard = context.read<DashboardController>();
            final ctrl = InterviewController(
              remoteDataSource: interviewRemoteDataSource,
              apiClient: apiClient,
            );
            ctrl.setOnSessionSaved(dashboard.refresh);
            return ctrl;
          },
          update: (_, authCtrl, dashboardCtrl, interviewCtrl) {
            interviewCtrl!.setOnSessionSaved(dashboardCtrl.refresh);
            if (!authCtrl.isAuthenticated) {
              interviewCtrl.clear();
            }
            return interviewCtrl;
          },
        ),
        // ResumeController holds candidate resumes in memory; clears them on logout.
        ChangeNotifierProxyProvider<AuthController, ResumeController>(
          create: (_) => ResumeController(
            remoteDataSource: resumeRemoteDataSource,
          ),
          update: (_, authCtrl, resumeCtrl) {
            if (!authCtrl.isAuthenticated) {
              resumeCtrl!.clear();
            }
            return resumeCtrl;
          },
        ),
        // SubscriptionController reacts to auth state changes.
        // When authenticated → load subscription status.
        // When signed out → clear all user subscription and entitlement data.
        ChangeNotifierProxyProvider<AuthController, SubscriptionController>(
          create: (_) => SubscriptionController(
            repository: subscriptionRepository,
          ),
          update: (_, authCtrl, subCtrl) {
            if (authCtrl.isAuthenticated) {
              subCtrl!.refreshSubscription();
            } else {
              subCtrl!.clear();
            }
            return subCtrl;
          },
        ),
      ],
      child: const InterviewCoachApp(),
    ),
  );
}



