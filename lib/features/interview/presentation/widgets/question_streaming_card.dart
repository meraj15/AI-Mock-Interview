import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'session_visualizers.dart';

class QuestionStreamingCard extends StatelessWidget {
  final String question;
  final List<String> questionWords;
  final int displayedWordCount;
  final bool isSpeaking;
  final Animation<double> pulseAnim;
  final AppColorScheme colors;

  const QuestionStreamingCard({
    super.key,
    required this.question,
    required this.questionWords,
    required this.displayedWordCount,
    required this.isSpeaking,
    required this.pulseAnim,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isStreamingActive = isSpeaking && displayedWordCount < questionWords.length;

    // Display revealed words up to displayedWordCount
    final displayedText = isStreamingActive
        ? questionWords.take(displayedWordCount).join(' ')
        : question.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpeaking
              ? colors.mint.withValues(alpha: 0.45)
              : colors.border.withValues(alpha: 0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text (Streaming word-by-word with pulsing caret)
          RichText(
            text: TextSpan(
              style: AppTypography.semiBold(
                17,
                color: colors.text,
                height: 1.48,
              ),
              children: [
                TextSpan(text: displayedText),
                if (isStreamingActive)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: FadeTransition(
                      opacity: pulseAnim,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 7,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.mint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingQuestionPlaceholder extends StatelessWidget {
  final AppColorScheme colors;
  final Animation<double> fadeAnim;
  final String statusText;

  const LoadingQuestionPlaceholder({
    super.key,
    required this.colors,
    required this.fadeAnim,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.28 + 0.12 * fadeAnim.value),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08 + 0.06 * fadeAnim.value),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated AI icon ring
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.10),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Rotating status text with fade
          FadeTransition(
            opacity: fadeAnim,
            child: Text(
              statusText,
              style: AppTypography.semiBold(
                14.5,
                color: colors.text,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'This usually takes a few seconds',
            style: AppTypography.regular(
              11.5,
              color: colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Progress dots
          AnimatedProgressDots(color: colors.primary),
        ],
      ),
    );
  }
}
