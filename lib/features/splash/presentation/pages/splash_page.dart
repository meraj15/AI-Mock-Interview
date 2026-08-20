import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/onboarding_page.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigateNext();
  }

  void _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final authCtrl = context.read<AuthController>();
    // Wait for auth initialization to resolve stored tokens
    int waited = 0;
    while (authCtrl.isLoading && waited < 15 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }

    if (!mounted) return;

    Widget target;
    if (!authCtrl.isOnboarded) {
      target = const OnboardingPage();
    } else if (!authCtrl.isAuthenticated) {
      target = const LoginPage();
    } else {
      // Load user profile in background
      context.read<ProfileController>().loadProfile();
      target = const MainNavPage();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.navy,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.mint,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.mint.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 52,
                    height: 52,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.mint,
                      child: Icon(Icons.psychology, size: 44, color: colors.navy),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Interview Coach',
                  style: AppTypography.bold(26, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Production-Grade AI Mock Interviews',
                  style: AppTypography.regular(12, color: const Color(0xFFBFCBE5), letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
