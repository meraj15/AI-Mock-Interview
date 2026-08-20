import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../interview/presentation/pages/interview_setup_page.dart';

class ProfileReadyPage extends StatefulWidget {
  final String name;
  final String role;
  final String experience;
  final List<String> skills;
  final bool isFromResume;

  const ProfileReadyPage({
    super.key,
    required this.name,
    required this.role,
    required this.experience,
    required this.skills,
    this.isFromResume = false,
  });

  @override
  State<ProfileReadyPage> createState() => _ProfileReadyPageState();
}

class _ProfileReadyPageState extends State<ProfileReadyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleBadge;
  late Animation<double> _fadeContent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleBadge = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _fadeContent = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startInterview() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InterviewSetupPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final displaySkills = widget.skills.isNotEmpty
        ? widget.skills
        : ['Flutter', 'Dart', 'Clean Architecture'];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Success badge
              Center(
                child: ScaleTransition(
                  scale: _scaleBadge,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.success.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      FeatherIcons.checkCircle,
                      size: 40,
                      color: colors.success,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fadeContent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Profile Ready ✓',
                        style: AppTypography.bold(28, color: colors.foreground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.isFromResume
                            ? "We've extracted your info from your resume."
                            : 'Your profile has been set up successfully.',
                        style: AppTypography.regular(
                          13,
                          color: colors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Profile card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.navy,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colors.mint.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.name.isNotEmpty
                                        ? widget.name[0].toUpperCase()
                                        : 'U',
                                    style: AppTypography.bold(
                                      20,
                                      color: colors.mint,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name.isNotEmpty
                                          ? widget.name
                                          : 'Your Name',
                                      style: AppTypography.bold(
                                        16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      widget.role,
                                      style: AppTypography.regular(
                                        12,
                                        color: const Color(0xFFBFCBE5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _ProfileRow(
                            colors: colors,
                            icon: FeatherIcons.briefcase,
                            label: 'Experience',
                            value: widget.experience,
                          ),

                          if (displaySkills.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'SKILLS',
                              style: AppTypography.bold(
                                9,
                                color: const Color(0xFF8EA4C8),
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: displaySkills.take(8).map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s,
                                    style: AppTypography.semiBold(
                                      10,
                                      color: const Color(0xFFBFCBE5),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    AppButton(
                      label: 'Start Interview',
                      icon: FeatherIcons.play,
                      onPress: _startInterview,
                    ),

                    const SizedBox(height: 14),

                    AppButton(
                      label: 'Edit Profile',
                      icon: FeatherIcons.edit2,
                      variant: ButtonVariant.secondary,
                      onPress: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final AppColorScheme colors;
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8EA4C8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.regular(11, color: const Color(0xFF8EA4C8)),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.semiBold(11, color: const Color(0xFFDCE4FF)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
