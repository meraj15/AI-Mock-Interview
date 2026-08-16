import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum PillTone { muted, success, coral, violet }

class PillBadge extends StatelessWidget {
  final String label;
  final PillTone tone;

  const PillBadge({
    super.key,
    required this.label,
    this.tone = PillTone.muted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    Color bgColor;
    Color textColor;

    switch (tone) {
      case PillTone.muted:
        bgColor = colors.secondary;
        textColor = colors.secondaryForeground;
        break;
      case PillTone.success:
        bgColor = colors.accent;
        textColor = colors.accentForeground;
        break;
      case PillTone.coral:
        bgColor = colors.coral;
        textColor = colors.ink;
        break;
      case PillTone.violet:
        bgColor = colors.violet;
        textColor = colors.ink;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTypography.semiBold(10, color: textColor),
      ),
    );
  }
}
