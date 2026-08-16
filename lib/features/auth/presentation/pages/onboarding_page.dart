import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': FeatherIcons.messageCircle,
      'title': 'Practice interviews with AI',
      'body': 'Build the confidence to speak clearly, think deeply, and show up ready for the room.',
    },
    {
      'icon': FeatherIcons.fileText,
      'title': 'Make every question relevant',
      'body': 'Practice against your resume, target role, experience level, and the kind of interview you want.',
    },
    {
      'icon': FeatherIcons.trendingUp,
      'title': 'Know exactly what to improve',
      'body': 'Get a clear score, thoughtful feedback, and a next-step plan after every session.',
    },
  ];

  void _finish() {
    context.read<AuthController>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final currentSlide = _slides[_currentIndex];

    return Scaffold(
      backgroundColor: colors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        FeatherIcons.award,
                        color: colors.primary,
                        size: 22,
                      ),

                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: AppTypography.semiBold(13, color: const Color(0xFFC9D5F0)),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Animated Card Illustration
              Center(
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.mint.withValues(alpha: 0.18),

                        ),
                      ),
                      Transform.rotate(
                        angle: -0.05,
                        child: Container(
                          width: 270,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),

                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  currentSlide['icon'] as IconData,
                                  size: 28,
                                  color: colors.accentForeground,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 9,
                                width: 140,
                                decoration: BoxDecoration(
                                  color: colors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 9,
                                width: 90,
                                decoration: BoxDecoration(
                                  color: colors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 9,
                                width: 180,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 9,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Text Copy
              Text(
                'INTERVIEW COACH',
                style: AppTypography.bold(11, color: colors.mint, letterSpacing: 1.6),
              ),
              const SizedBox(height: 12),
              Text(
                currentSlide['title'] as String,
                style: AppTypography.bold(32, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                currentSlide['body'] as String,
                style: AppTypography.regular(14, color: const Color(0xFFC9D5F0), height: 1.5),
              ),

              const SizedBox(height: 32),

              // Dots and Button
              Row(
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 7),
                    height: 7,
                    width: i == _currentIndex ? 24 : 7,
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? colors.mint : Colors.white.withValues(alpha: 0.25),

                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              AppButton(
                label: _currentIndex == _slides.length - 1 ? 'Get started' : 'Continue',
                icon: FeatherIcons.arrowRight,
                onPress: () {
                  if (_currentIndex == _slides.length - 1) {
                    _finish();
                  } else {
                    setState(() => _currentIndex++);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
