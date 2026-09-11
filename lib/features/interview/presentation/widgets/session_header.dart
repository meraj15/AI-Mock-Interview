import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SessionHeader extends StatelessWidget {
  final String role;
  final int elapsedSeconds;
  final VoidCallback onExit;
  final AppColorScheme colors;
  final int? questionRemainingSeconds;
  final int? questionTimeLimit;
  final int? currentQuestionIndex;
  final int? totalQuestions;

  const SessionHeader({
    super.key,
    required this.role,
    required this.elapsedSeconds,
    required this.onExit,
    required this.colors,
    this.questionRemainingSeconds,
    this.questionTimeLimit,
    this.currentQuestionIndex,
    this.totalQuestions,
  });

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCountdown = questionTimeLimit != null && questionTimeLimit! > 0;
    final displaySeconds = isCountdown
        ? (questionRemainingSeconds ?? 0)
        : elapsedSeconds;

    final isUrgent = isCountdown && displaySeconds <= 10;
    final isWarning = isCountdown && displaySeconds <= 30 && !isUrgent;

    final badgeBorderColor = isUrgent
        ? colors.destructive
        : (isWarning ? colors.yellow : colors.border.withValues(alpha: 0.4));

    final badgeBgColor = isUrgent
        ? colors.destructive.withValues(alpha: 0.12)
        : (isWarning ? colors.yellow.withValues(alpha: 0.12) : colors.card);

    final textColor = isUrgent
        ? colors.destructive
        : (isWarning ? colors.yellow : colors.text);

    final iconColor = isUrgent
        ? colors.destructive
        : (isWarning ? colors.yellow : colors.mutedForeground);

    final icon = isUrgent ? FeatherIcons.alertCircle : FeatherIcons.clock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Exit Button
          GestureDetector(
            onTap: onExit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.x, size: 12, color: colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text('Exit', style: AppTypography.semiBold(11, color: colors.text)),
                ],
              ),
            ),
          ),

          // Role Title & Subtitle
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role,
                    style: AppTypography.bold(12.5, color: colors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    (currentQuestionIndex != null && totalQuestions != null && totalQuestions! > 0)
                        ? 'Question ${currentQuestionIndex! + 1} of $totalQuestions'
                        : 'Interview Coach',
                    style: AppTypography.medium(10, color: colors.mint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Timer Badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  _formatTime(displaySeconds),
                  style: AppTypography.semiBold(11, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
