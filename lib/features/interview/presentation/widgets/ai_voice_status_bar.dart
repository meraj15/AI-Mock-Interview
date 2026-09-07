import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/interview_phase.dart';
import 'session_visualizers.dart';

class AIVoiceStatusBar extends StatelessWidget {
  final AppColorScheme colors;
  final bool isLoading;
  final bool isComplete;
  final InterviewPhase phase;
  final AnimationController waveAnimCtrl;

  const AIVoiceStatusBar({
    super.key,
    required this.colors,
    required this.isLoading,
    required this.isComplete,
    required this.phase,
    required this.waveAnimCtrl,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    String statusLabel;
    IconData icon;

    if (isComplete || phase == InterviewPhase.done) {
      accentColor = colors.mint;
      statusLabel = 'Interview Concluded • Great job!';
      icon = FeatherIcons.award;
    } else if (isLoading) {
      accentColor = colors.primary;
      statusLabel = 'AI Interviewer • Preparing question…';
      icon = FeatherIcons.loader;
    } else {
      switch (phase) {
        case InterviewPhase.speaking:
          accentColor = colors.mint;
          statusLabel = 'AI Interviewer • Speaking';
          icon = FeatherIcons.volume2;
          break;
        case InterviewPhase.listening:
          accentColor = colors.primary;
          statusLabel = 'AI Interviewer • Listening to you';
          icon = FeatherIcons.radio;
          break;
        case InterviewPhase.recording:
          accentColor = colors.destructive;
          statusLabel = 'You • Recording answer…';
          icon = FeatherIcons.mic;
          break;
        case InterviewPhase.answered:
          accentColor = colors.primary;
          statusLabel = 'You • Review your answer';
          icon = FeatherIcons.edit2;
          break;
        case InterviewPhase.thinking:
          accentColor = colors.violet;
          statusLabel = 'AI Interviewer • Evaluating response…';
          icon = FeatherIcons.cpu;
          break;
        case InterviewPhase.done:
        case InterviewPhase.loading:
          accentColor = colors.mint;
          statusLabel = 'Interview Concluded • Great job!';
          icon = FeatherIcons.award;
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Waveform Bars / Glowing Dot
          if (phase == InterviewPhase.speaking || phase == InterviewPhase.recording)
            MiniVoiceWaveVisualizer(
              color: accentColor,
              anim: waveAnimCtrl,
            )
          else
            Icon(icon, size: 13, color: accentColor),

          const SizedBox(width: 8),

          Text(
            statusLabel,
            style: AppTypography.semiBold(11.5, color: accentColor),
          ),
        ],
      ),
    );
  }
}
