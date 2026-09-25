import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class ExitAppDialog extends StatelessWidget {
  const ExitAppDialog({super.key});

  static bool _isShowing = false;

  /// Shows the exit confirmation dialog.
  /// Returns `true` if the user confirmed exit, `false` or `null` otherwise.
  static Future<bool?> show(BuildContext context) async {
    if (_isShowing) return false;
    _isShowing = true;
    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => const ExitAppDialog(),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Dialog(
      backgroundColor: colors.card,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft tinted icon container
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colors.destructive.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.destructive.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(
                FeatherIcons.logOut,
                size: 24,
                color: colors.destructive,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Exit Interview Coach?',
              style: AppTypography.bold(18, color: colors.foreground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Are you sure you want to exit the app?',
              style: AppTypography.regular(
                13.5,
                color: colors.mutedForeground,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Actions: Cancel & Exit App
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: ButtonVariant.secondary,
                    onPress: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.destructive,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: colors.destructive.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Exit App',
                              style: AppTypography.bold(14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
