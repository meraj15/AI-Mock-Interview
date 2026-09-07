import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/interview_phase.dart';
import 'session_visualizers.dart';

class VoiceControlCenter extends StatelessWidget {
  final bool isLoading;
  final bool isComplete;
  final InterviewPhase phase;
  final AppColorScheme colors;
  final VoidCallback onViewEvaluation;
  final VoidCallback onSkipTts;
  final VoidCallback onStopRecording;
  final VoidCallback onReplayQuestion;
  final VoidCallback onReRecord;
  final VoidCallback onSubmitFromEditor;
  final VoidCallback onStartRecording;

  const VoiceControlCenter({
    super.key,
    required this.isLoading,
    required this.isComplete,
    required this.phase,
    required this.colors,
    required this.onViewEvaluation,
    required this.onSkipTts,
    required this.onStopRecording,
    required this.onReplayQuestion,
    required this.onReRecord,
    required this.onSubmitFromEditor,
    required this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    // If interview is complete, show prominent View Evaluation button
    if (isComplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.mint,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: const Icon(FeatherIcons.award, size: 20, color: Colors.black),
            label: Text(
              'View Performance Evaluation',
              style: AppTypography.bold(14.5, color: Colors.black),
            ),
            onPressed: onViewEvaluation,
          ),
        ),
      );
    }

    if (isLoading) {
      return const SizedBox(height: 72);
    }

    if (phase == InterviewPhase.speaking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.volume2, size: 14, color: colors.mint),
            const SizedBox(width: 8),
            Text(
              'AI speaking…',
              style: AppTypography.medium(12, color: colors.mutedForeground),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSkipTts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Skip',
                  style: AppTypography.bold(11, color: colors.mint),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (phase == InterviewPhase.thinking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Evaluating response…',
              style: AppTypography.semiBold(12, color: colors.text),
            ),
          ],
        ),
      );
    }

    // Recording — stop button
    if (phase == InterviewPhase.recording) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onStopRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.destructive.withValues(alpha: 0.22),
                border: Border.all(color: colors.destructive, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: colors.destructive.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(FeatherIcons.square, size: 22, color: colors.destructive),
            ),
          ),
          const SizedBox(height: 8),
          Text('Tap to stop recording', style: AppTypography.semiBold(11.5, color: colors.destructive)),
        ],
      );
    }

    // Answered — replay / re-record / submit
    if (phase == InterviewPhase.answered) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: ControlPill(
                icon: FeatherIcons.volume2,
                label: 'Re-listen',
                color: colors.mint,
                onTap: onReplayQuestion,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ControlPill(
                icon: FeatherIcons.mic,
                label: 'Re-record',
                color: colors.mutedForeground,
                onTap: onReRecord,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ControlPill(
                icon: FeatherIcons.send,
                label: 'Submit',
                color: colors.primary,
                onTap: onSubmitFromEditor,
                isPrimary: true,
              ),
            ),
          ],
        ),
      );
    }

    // Listening — mic button + replay question pill
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onReplayQuestion,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FeatherIcons.volume2, size: 13, color: colors.mint),
                const SizedBox(width: 6),
                Text('Replay question', style: AppTypography.semiBold(11, color: colors.mint)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onStartRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.mint.withValues(alpha: 0.12),
              border: Border.all(color: colors.mint, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: colors.mint.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.mic, size: 22, color: colors.mint),
          ),
        ),
        const SizedBox(height: 8),
        Text('Tap to speak your answer', style: AppTypography.semiBold(11.5, color: colors.mint)),
      ],
    );
  }
}
