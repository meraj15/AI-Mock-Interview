import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: colors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.bold(22, color: colors.foreground),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.medium(11, color: colors.mutedForeground),
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            Text(
              change!,
              style: AppTypography.semiBold(10, color: colors.success),
            ),
          ],
        ],
      ),
    );
  }
}
