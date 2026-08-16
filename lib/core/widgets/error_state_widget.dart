import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.destructive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(FeatherIcons.alertCircle, size: 28, color: colors.destructive),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTypography.bold(18, color: colors.foreground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              AppButton(
                label: 'Try Again',
                icon: FeatherIcons.rotateCcw,
                onPress: onRetry,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
