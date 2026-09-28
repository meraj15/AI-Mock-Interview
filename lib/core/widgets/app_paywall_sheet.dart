import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../../features/subscription/presentation/pages/premium_page.dart';

class AppPaywallSheet extends StatelessWidget {
  final String title;
  final String description;
  final String? feature;
  final IconData icon;
  final String ctaLabel;

  const AppPaywallSheet({
    super.key,
    required this.title,
    required this.description,
    this.feature,
    this.icon = FeatherIcons.lock,
    this.ctaLabel = 'Unlock Pro — ₹299/month',
  });

  /// Convenient static helper to show the compact paywall modal anywhere in the app.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    String? feature,
    IconData icon = FeatherIcons.lock,
    String ctaLabel = 'Unlock Pro — ₹299/month',
  }) {
    final colors = AppColorScheme.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AppPaywallSheet(
        title: title,
        description: description,
        feature: feature,
        icon: icon,
        ctaLabel: ctaLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Lock Icon Badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: AppTypography.bold(18, color: colors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: AppTypography.regular(
              13.5,
              color: colors.mutedForeground,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Primary CTA Button
          AppButton(
            label: ctaLabel,
            icon: FeatherIcons.zap,
            onPress: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PremiumPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Maybe Later
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe Later',
              style: AppTypography.medium(
                13,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
