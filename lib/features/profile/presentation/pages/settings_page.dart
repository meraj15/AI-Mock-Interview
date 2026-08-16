import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/choice_row.dart';
import '../controllers/theme_controller.dart';
import 'account_security_page.dart';
import 'edit_profile_page.dart';
import 'notification_settings_page.dart';
import 'voice_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final themeCtrl = context.watch<ThemeController>();

    final preferences = [
      {
        'icon': FeatherIcons.user,
        'title': 'Edit Profile',
        'detail': 'Name, role, experience, bio',
        'page': const EditProfilePage(),
      },
      {
        'icon': FeatherIcons.shield,
        'title': 'Account & Security',
        'detail': 'Password, 2FA, session control',
        'page': const AccountSecurityPage(),
      },
      {
        'icon': FeatherIcons.mic,
        'title': 'AI Interviewer Voice & Persona',
        'detail': 'Sarah (Principal Architect) · 1.0x',
        'page': const VoiceSettingsPage(),
      },
      {
        'icon': FeatherIcons.bell,
        'title': 'Notifications & Reminders',
        'detail': 'Daily drills and weekly digest',
        'page': const NotificationSettingsPage(),
      },
    ];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Settings',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          Text(
            'APPEARANCE',
            style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.3),
          ),
          const SizedBox(height: 10),

          ChoiceRow(
            label: 'System',
            detail: 'Follow your device setting',
            selected: themeCtrl.themeMode == AppThemeMode.system,
            onPress: () => themeCtrl.setThemeMode(AppThemeMode.system),
          ),
          ChoiceRow(
            label: 'Light',
            detail: 'Clean, high-contrast light mode',
            selected: themeCtrl.themeMode == AppThemeMode.light,
            onPress: () => themeCtrl.setThemeMode(AppThemeMode.light),
          ),
          ChoiceRow(
            label: 'Dark',
            detail: 'Sleek dark theme for night sessions',
            selected: themeCtrl.themeMode == AppThemeMode.dark,
            onPress: () => themeCtrl.setThemeMode(AppThemeMode.dark),
          ),

          const SizedBox(height: 20),

          Text(
            'PREFERENCES & SECURITY',
            style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.3),
          ),
          const SizedBox(height: 10),

          ...preferences.map((pref) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => pref['page'] as Widget),
                  );
                },
                child: Ink(
                  height: 68,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(pref['icon'] as IconData, size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pref['title'] as String,
                              style: AppTypography.semiBold(13, color: colors.foreground),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pref['detail'] as String,
                              style: AppTypography.regular(10, color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Icon(FeatherIcons.chevronRight, size: 16, color: colors.mutedForeground),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          Text(
            'ABOUT',
            style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.3),
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interview Coach',
                  style: AppTypography.bold(14, color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 · Production-Grade AI Mock Interviews',
                  style: AppTypography.regular(11, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
