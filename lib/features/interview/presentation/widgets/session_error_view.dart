import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SessionErrorView extends StatelessWidget {
  final String? errorMessage;
  final AppColorScheme colors;
  final VoidCallback onExit;
  final VoidCallback onRetry;

  const SessionErrorView({
    super.key,
    required this.errorMessage,
    required this.colors,
    required this.onExit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: onExit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.x, size: 14, color: colors.mutedForeground),
                        const SizedBox(width: 5),
                        Text('Exit', style: AppTypography.semiBold(11, color: colors.text)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.destructive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.destructive.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(FeatherIcons.alertTriangle, size: 26, color: colors.destructive),
              ),
              const SizedBox(height: 16),
              Text('Connection Issue', style: AppTypography.bold(18, color: colors.text)),
              const SizedBox(height: 6),
              Text(
                'Unable to reach the AI interview engine. Please verify backend connectivity.',
                style: AppTypography.regular(12, color: colors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.destructive.withValues(alpha: 0.2)),
                ),
                child: SelectableText(
                  errorMessage ?? 'Unknown error occurred.',
                  style: AppTypography.regular(11, color: colors.text),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onExit,
                      child: Text('Exit', style: AppTypography.semiBold(13, color: colors.text)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onRetry,
                      child: Text('Retry', style: AppTypography.bold(13, color: colors.primaryForeground)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
