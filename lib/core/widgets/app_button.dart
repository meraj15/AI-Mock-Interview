import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final ButtonVariant variant;
  final IconData? icon;
  final bool disabled;
  final bool isLoading;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPress,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.disabled = false,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = colors.primary;
        textColor = colors.primaryForeground;
        border = Border.all(color: colors.primary);
        break;
      case ButtonVariant.secondary:
        backgroundColor = colors.secondary;
        textColor = colors.secondaryForeground;
        border = Border.all(color: colors.border);
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = colors.primary;
        border = null;
        break;
    }

    final isClickable = !disabled && !isLoading && onPress != null;

    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClickable ? onPress : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: width ?? double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: width != null ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 9),
                ] else if (icon != null) ...[
                  Icon(icon, size: 17, color: textColor),
                  const SizedBox(width: 9),
                ],
                Text(
                  label,
                  style: AppTypography.semiBold(14, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
