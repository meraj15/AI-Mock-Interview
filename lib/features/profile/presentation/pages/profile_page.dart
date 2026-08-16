import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../resume/presentation/pages/resume_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  final bool showHeader;
  const ProfilePage({super.key, this.showHeader = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final userName = user?.name ?? 'Meraj Khan';
    final userEmail = user?.email ?? 'meraj.khan@email.com';

    final menuItems = [
      {
        'icon': FeatherIcons.fileText,
        'title': 'My resumes',
        'detail': '1 resume saved',
        'page': const ResumePage(),
      },
      {
        'icon': FeatherIcons.bell,
        'title': 'Notifications',
        'detail': 'Stay on track',
        'page': const SettingsPage(),
      },
      {
        'icon': FeatherIcons.sliders,
        'title': 'Preferences',
        'detail': 'Theme, voice, language',
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
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'MK',
                  style: AppTypography.bold(20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTypography.bold(20, color: colors.foreground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: AppTypography.regular(11, color: colors.mutedForeground),
                    ),
                    const SizedBox(height: 8),
                    const PillBadge(label: 'Flutter Developer', tone: PillTone.success),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(FeatherIcons.settings, size: 18, color: colors.foreground),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Rows
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Interviews',
                  value: '12',
                  icon: FeatherIcons.layers,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Avg. score',
                  value: '78%',
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
                  value: '91%',
                  icon: FeatherIcons.award,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Streak',
                  value: '4 days',
                  icon: FeatherIcons.zap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            'Account',
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
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
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
