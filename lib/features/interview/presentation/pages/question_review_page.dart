import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';

class QuestionReviewPage extends StatefulWidget {
  const QuestionReviewPage({super.key});

  @override
  State<QuestionReviewPage> createState() => _QuestionReviewPageState();
}

class _QuestionReviewPageState extends State<QuestionReviewPage> {
  int _index = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'Can you walk me through one Flutter project you’ve worked on?',
      'score': '8.5',
      'answer': 'I built an OTT application where I owned the mobile architecture and worked closely with the API team.',
      'feedback': 'Strong project framing. Add one specific trade-off to make the story more memorable.',
    },
    {
      'q': 'How did you handle state management in your Flutter application?',
      'score': '7.0',
      'answer': 'I used Provider to keep state predictable and separate from the UI layer.',
      'feedback': 'Good fundamentals. Go deeper on dependency injection and provider lifecycle.',
    },
    {
      'q': 'How did you handle API errors?',
      'score': '8.0',
      'answer': 'I modelled failures explicitly and gave the user a recoverable state instead of a blank screen.',
      'feedback': 'Clear and practical. Mention how you observe and debug errors in production.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final total = _questions.length;
    final item = _questions[_index];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Question review',
            subtitle: '${_index + 1} of $total',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Selector chips
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(
              children: List.generate(total, (i) {
                final isSelected = _index == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 9.0),
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.bold(
                          12,
                          color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Question Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUESTION ${_index + 1}',
                  style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.3),
                ),
                const SizedBox(height: 11),
                Text(
                  item['q'] as String,
                  style: AppTypography.bold(19, color: colors.foreground, height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            'Your answer',
            style: AppTypography.bold(16, color: colors.foreground),
          ),
          const SizedBox(height: 10),

          // Answer Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              item['answer'] as String,
              style: AppTypography.regular(13, color: colors.foreground, height: 1.5),
            ),
          ),

          const SizedBox(height: 22),

          // Score Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI evaluation',
                style: AppTypography.bold(16, color: colors.foreground),
              ),
              PillBadge(label: '${item['score']} / 10', tone: PillTone.success),
            ],
          ),
          const SizedBox(height: 10),

          // Feedback Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FeatherIcons.checkCircle, size: 17, color: colors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Good answer',
                      style: AppTypography.semiBold(13, color: colors.foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['feedback'] as String,
                  style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.5),
                ),
                const SizedBox(height: 18),
                Text(
                  'What was missing',
                  style: AppTypography.bold(12, color: colors.foreground),
                ),
                const SizedBox(height: 6),
                Text(
                  'A more specific example would make the impact easier to evaluate.',
                  style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.5),
                ),
              ],
            ),
          ),

          // Navigation controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _index > 0 ? () => setState(() => _index--) : null,
                  child: Text(
                    '← Previous',
                    style: AppTypography.semiBold(
                      12,
                      color: _index == 0 ? colors.input : colors.primary,
                    ),
                  ),
                ),
                Text(
                  '${_index + 1} / $total',
                  style: AppTypography.medium(11, color: colors.mutedForeground),
                ),
                GestureDetector(
                  onTap: _index < total - 1 ? () => setState(() => _index++) : null,
                  child: Text(
                    'Next →',
                    style: AppTypography.semiBold(
                      12,
                      color: _index == total - 1 ? colors.input : colors.primary,
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
