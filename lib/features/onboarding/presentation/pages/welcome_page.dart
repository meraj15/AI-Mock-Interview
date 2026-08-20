import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'profile_setup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSetup() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileSetupPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.navy,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Brand mark
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.psychology,
                            color: colors.navy,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Interview Coach',
                        style: AppTypography.bold(16, color: Colors.white),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Hero visual
                  Center(
                    child: SizedBox(
                      height: size.height * 0.32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.mint.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                          ),
                          // Middle ring
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.mint.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          // Core circle
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.mint.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Icon(
                                FeatherIcons.mic,
                                size: 44,
                                color: colors.mint,
                              ),
                            ),
                          ),

                          // Floating cards
                          Positioned(
                            top: 10,
                            right: 20,
                            child: _FloatingCard(
                              colors: colors,
                              icon: FeatherIcons.checkCircle,
                              label: 'AI Feedback',
                              color: colors.mint,
                            ),
                          ),
                       
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Copy
                  Text(
                    'AI INTERVIEW COACH',
                    style: AppTypography.bold(11,
                        color: colors.mint, letterSpacing: 1.8),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Practice like it's real.Perform like a pro.",
                    style: AppTypography.bold(30,
                        color: Colors.white, height: 1.18),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Get AI-powered mock interviews tailored to your resume, role, and target company — with detailed feedback after every session.',
                    style: AppTypography.regular(12,
                        color: const Color(0xFFBFCBE5), height: 1.5),
                  ),

                  const SizedBox(height: 36),

                  // CTA
                  AppButton(
                    label: 'Get started',
                    icon: FeatherIcons.arrowRight,
                    onPress: _goToSetup,
                  ),

                  const SizedBox(height: 18),

                  // Already have account
                  Center(
                    child: GestureDetector(
                      onTap: _goToLogin,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: AppTypography.regular(13,
                                  color: const Color(0xFF8EA4C8)),
                            ),
                            TextSpan(
                              text: 'Sign in',
                              style: AppTypography.semiBold(13,
                                  color: colors.mint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final AppColorScheme colors;
  final IconData icon;
  final String label;
  final Color color;

  const _FloatingCard({
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.semiBold(11, color: colors.foreground)),
        ],
      ),
    );
  }
}
