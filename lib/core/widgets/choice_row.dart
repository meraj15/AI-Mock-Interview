import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ChoiceRow extends StatelessWidget {
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onPress;
  final IconData? icon;

  const ChoiceRow({
    super.key,
    required this.label,
    this.detail,
    required this.selected,
    required this.onPress,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final bgColor = selected ? colors.secondary : colors.card;
    final borderColor = selected ? colors.primary : colors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 17,
                      color: selected ? colors.primaryForeground : colors.mutedForeground,
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: AppTypography.semiBold(14, color: colors.foreground),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          detail!,
                          style: AppTypography.regular(11, color: colors.mutedForeground),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.primary : colors.input,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
