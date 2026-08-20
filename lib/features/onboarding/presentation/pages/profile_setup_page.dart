import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../resume/presentation/pages/resume_upload_page.dart';
import 'manual_profile_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
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
      backgroundColor: colors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(FeatherIcons.arrowLeft,
                        size: 18, color: colors.foreground),
                  ),
                ),

                const SizedBox(height: 32),

                // Step badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'STEP 1 OF 2',
                    style: AppTypography.bold(10,
                        color: colors.primary, letterSpacing: 1.4),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Let's set up your profile",
                  style: AppTypography.bold(32,
                      color: colors.foreground, height: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  'The AI needs to know your background to generate the most relevant interview questions.',
                  style: AppTypography.regular(14,
                      color: colors.mutedForeground, height: 1.5),
                ),

                const SizedBox(height: 40),

                // Upload Resume Card
                _OptionCard(
                  colors: colors,
                  icon: FeatherIcons.fileText,
                  iconBg: colors.primary.withValues(alpha: 0.12),
                  iconColor: colors.primary,
                  title: 'Upload Resume',
                  subtitle: 'PDF or DOC — AI will extract your experience, skills, and projects automatically.',
                  badgeColor: colors.mint,
                  badgeTextColor: colors.navy,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ResumeUploadPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Enter Manually Card
                _OptionCard(
                  colors: colors,
                  icon: FeatherIcons.edit3,
                  iconBg: colors.secondary,
                  iconColor: colors.mutedForeground,
                  title: 'Enter Manually',
                  subtitle:
                      'Fill in your name, target role, experience level, and skills in a quick form.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualProfilePage(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Footer note
                Center(
                  child: Text(
                    'You can update your profile anytime.',
                    style: AppTypography.regular(12,
                        color: colors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final AppColorScheme colors;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.colors,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.bold(15,
                              color: colors.foreground),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: AppTypography.bold(9,
                                  color: badgeTextColor ?? Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: AppTypography.regular(12,
                          color: colors.mutedForeground, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(FeatherIcons.chevronRight,
                  size: 18, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
