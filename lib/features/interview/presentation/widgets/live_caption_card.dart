import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

// ── Live Transcript Caption Card ──────────────────────────────────────────

class LiveCaptionCard extends StatelessWidget {
  final String liveTranscript;
  final ScrollController scrollController;
  final Animation<double> pulseAnim;
  final AppColorScheme colors;

  const LiveCaptionCard({
    super.key,
    required this.liveTranscript,
    required this.scrollController,
    required this.pulseAnim,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasWords = liveTranscript.trim().isNotEmpty;
    final wordCount = hasWords
        ? liveTranscript.trim().split(RegExp(r'\s+')).length
        : 0;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 76, maxHeight: 240),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.destructive.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.destructive.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Pulsing dot + LIVE TRANSCRIPT + Word counter
            Row(
              children: [
                FadeTransition(
                  opacity: pulseAnim,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.destructive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE TRANSCRIPT',
                  style: AppTypography.bold(10.5, color: colors.destructive, letterSpacing: 0.6),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasWords ? '$wordCount words' : 'Listening…',
                    style: AppTypography.medium(10, color: colors.destructive),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Scrollable text content dynamically adjusting to user speech length
            Flexible(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: hasWords,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      hasWords
                          ? liveTranscript
                          : 'Listening to your answer… speak naturally.',
                      style: AppTypography.regular(
                        13.5,
                        color: hasWords ? colors.text : colors.mutedForeground,
                        height: 1.48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Editable Answer Card ──────────────────────────────────────────────────

class AnswerEditorCard extends StatelessWidget {
  final TextEditingController answerController;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final AppColorScheme colors;

  const AnswerEditorCard({
    super.key,
    required this.answerController,
    required this.focusNode,
    required this.scrollController,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final wordCount = answerController.text.trim().isEmpty
        ? 0
        : answerController.text.trim().split(RegExp(r'\s+')).length;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 90, maxHeight: 240),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.45),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.07),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(FeatherIcons.messageCircle, size: 12, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your answer — tap to edit',
                    style: AppTypography.semiBold(11, color: colors.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$wordCount words',
                    style: AppTypography.medium(10, color: colors.primary),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(FeatherIcons.edit2, size: 12, color: colors.mutedForeground),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextField(
                      controller: answerController,
                      focusNode: focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: AppTypography.regular(13.5, color: colors.text, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Your spoken answer appears here. Tap to edit…',
                        hintStyle: AppTypography.regular(13, color: colors.mutedForeground),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
