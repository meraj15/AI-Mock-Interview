import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../../../resume/presentation/pages/resume_page.dart';
import '../controllers/profile_controller.dart';
import 'account_security_page.dart';
import 'edit_profile_page.dart';
import 'notification_settings_page.dart';
import 'settings_page.dart';
import 'voice_settings_page.dart';

class ProfilePage extends StatelessWidget {
  final bool showHeader;
  const ProfilePage({super.key, this.showHeader = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final auth = context.watch<AuthController>();
    final profileCtrl = context.watch<ProfileController>();
    final resumeCtrl = context.watch<ResumeController>();

    // Real name comes from ProfileController; email always from AuthController
    final userEmail = auth.user?.email ?? '';
    final displayName = profileCtrl.fullName.isNotEmpty
        ? profileCtrl.fullName
        : userEmail.isNotEmpty
            ? userEmail.split('@').first
            : 'User';
    final displayInitials = profileCtrl.initials.isNotEmpty
        ? profileCtrl.initials
        : displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';
    final targetRole = profileCtrl.targetRole;

    final menuItems = [
      {
        'icon': FeatherIcons.fileText,
        'title': 'My resumes',
        'detail': '${resumeCtrl.resumes.length} resumes saved',
        'page': const ResumePage(),
      },
      {
        'icon': FeatherIcons.mic,
        'title': 'AI Interviewer Voice & Persona',
        'detail': 'Sarah (Principal Architect)',
        'page': const VoiceSettingsPage(),
      },
      {
        'icon': FeatherIcons.bell,
        'title': 'Notifications & Reminders',
        'detail': 'Daily drill notifications active',
        'page': const NotificationSettingsPage(),
      },
      {
        'icon': FeatherIcons.shield,
        'title': 'Account & Security',
        'detail': 'Password, 2FA, session control',
        'page': const AccountSecurityPage(),
      },
      {
        'icon': FeatherIcons.sliders,
        'title': 'App Preferences',
        'detail': 'Theme switcher & appearance',
        'page': const SettingsPage(),
      },
    ];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            AppHeader(
              title: 'Profile',
              onBack: () => Navigator.of(context).pop(),
            ),
          ],

          // Profile Head
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: profileCtrl.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              displayInitials,
                              style: AppTypography.bold(22, color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: AppTypography.bold(20, color: colors.foreground),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(FeatherIcons.edit2, size: 13, color: colors.mutedForeground),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: AppTypography.regular(11, color: colors.mutedForeground),
                          ),
                          const SizedBox(height: 8),
                          if (targetRole.isNotEmpty)
                            PillBadge(label: targetRole, tone: PillTone.success)
                          else
                            Text(
                              'Tap to complete profile',
                              style: AppTypography.regular(10, color: colors.mutedForeground),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(FeatherIcons.settings, size: 19, color: colors.foreground),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bio if available
          if (!profileCtrl.isLoading && profileCtrl.bio.isNotEmpty) ...[
            Text(
              profileCtrl.bio,
              style: AppTypography.regular(12, color: colors.mutedForeground),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
          ],

          // Stats Rows — real data comes from future interview tracking; shown as placeholders
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Interviews',
                  value: '—',
                  icon: FeatherIcons.layers,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Avg. score',
                  value: '—',
                  icon: FeatherIcons.trendingUp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Best score',
                  value: '—',
                  icon: FeatherIcons.award,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Experience',
                  value: profileCtrl.experienceLabel.isNotEmpty
                      ? profileCtrl.experienceLabel
                      : '—',
                  icon: FeatherIcons.briefcase,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            'Account & Settings',
            style: AppTypography.bold(17, color: colors.foreground),
          ),
          const SizedBox(height: 8),

          ...menuItems.map((item) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => item['page'] as Widget),
                  );
                },
                child: Ink(
                  height: 66,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(item['icon'] as IconData, size: 17, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTypography.semiBold(13, color: colors.foreground),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['detail'] as String,
                              style: AppTypography.regular(10, color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Icon(FeatherIcons.chevronRight, size: 17, color: colors.mutedForeground),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Logout
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final confirm = await ConfirmationDialog.show(
                  context,
                  title: 'Log Out',
                  message: 'Are you sure you want to log out of your session?',
                  confirmLabel: 'Log Out',
                );

                if (confirm == true && context.mounted) {
                  context.read<ProfileController>().clear();
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Icon(FeatherIcons.logOut, size: 17, color: colors.destructive),
                    const SizedBox(width: 8),
                    Text(
                      'Log out',
                      style: AppTypography.semiBold(13, color: colors.destructive),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
