import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _dailyReminders = true;
  bool _weeklySummary = true;
  bool _streakAlerts = true;
  bool _recommendedDrills = false;
  bool _hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Notifications',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          _buildToggleItem(
            icon: FeatherIcons.bell,
            title: 'Daily Practice Reminders',
            subtitle: 'Get notified to keep your daily interview drill streak active',
            value: _dailyReminders,
            onChanged: (val) => setState(() => _dailyReminders = val),
            colors: colors,
          ),

          _buildToggleItem(
            icon: FeatherIcons.trendingUp,
            title: 'Weekly Performance Digest',
            subtitle: 'Receive a weekly email breakdown of score improvements',
            value: _weeklySummary,
            onChanged: (val) => setState(() => _weeklySummary = val),
            colors: colors,
          ),

          _buildToggleItem(
            icon: FeatherIcons.zap,
            title: 'Streak & Milestone Alerts',
            subtitle: 'Celebrate when you hit 3-day, 7-day, and 30-day interview milestones',
            value: _streakAlerts,
            onChanged: (val) => setState(() => _streakAlerts = val),
            colors: colors,
          ),

          _buildToggleItem(
            icon: FeatherIcons.target,
            title: 'Recommended Drill Alerts',
            subtitle: 'Get notified when new drills are generated for your weak areas',
            value: _recommendedDrills,
            onChanged: (val) => setState(() => _recommendedDrills = val),
            colors: colors,
          ),

          _buildToggleItem(
            icon: FeatherIcons.volume2,
            title: 'Haptic & Sound Feedback',
            subtitle: 'Play subtle vibrations and sound on speech recording start/stop',
            value: _hapticFeedback,
            onChanged: (val) => setState(() => _hapticFeedback = val),
            colors: colors,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColorScheme colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.semiBold(13, color: colors.foreground),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.regular(10, color: colors.mutedForeground, height: 1.4),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: colors.primary,
            onChanged: onChanged,
          ),

        ],
      ),
    );
  }
}
