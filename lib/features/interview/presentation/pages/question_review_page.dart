import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../controllers/interview_controller.dart';

class QuestionReviewPage extends StatefulWidget {
  const QuestionReviewPage({super.key});

  @override
  State<QuestionReviewPage> createState() => _QuestionReviewPageState();
}

class _QuestionReviewPageState extends State<QuestionReviewPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final eval = interviewCtrl.lastEvaluation;
    final reviews = eval?.questionReviews ?? [];
    final history = interviewCtrl.sessionHistory;

    final total = reviews.isNotEmpty
        ? reviews.length
        : history.isNotEmpty
            ? history.length
            : 1;

    if (_index >= total) {
      _index = total - 1;
    }

    final String questionText;
    final String answerText;
    final String expectedAnswerText;
    final String feedbackText;
    final int scoreVal;
    final String topicName;

    if (reviews.isNotEmpty && _index < reviews.length) {
      final r = reviews[_index];
      questionText = r.question;
      answerText = r.answer.isNotEmpty ? r.answer : 'No answer provided.';
      expectedAnswerText = r.expectedAnswer.isNotEmpty
          ? r.expectedAnswer
          : 'A great answer explains the core idea in plain English first, followed by a concrete real-world example from your development experience.';
      feedbackText = r.feedback;
      scoreVal = r.score;
      topicName = history.isNotEmpty && _index < history.length
          ? (history[_index]['topic'] ?? 'Topic ${_index + 1}')
          : 'Question ${_index + 1}';
    } else if (history.isNotEmpty && _index < history.length) {
      final h = history[_index];
      questionText = h['question'] ?? 'Question';
      answerText = (h['answer']?.isNotEmpty ?? false)
          ? h['answer']!
          : 'No answer provided.';
      expectedAnswerText =
          'A great answer explains the core idea in plain English first, followed by a concrete real-world example from your development experience.';
      feedbackText = 'Clear and structured response.';
      scoreVal = 75;
      topicName = h['topic'] ?? 'Topic ${_index + 1}';
    } else {
      questionText =
          'What is dependency injection, and why do we use it in Flutter?';
      answerText =
          'I think dependency injection means we don\'t create the object directly inside the class. We pass it from outside, so it is easier to manage and test.';
      expectedAnswerText =
          'Dependency injection means giving a class the things it needs instead of creating them inside the class. For example, if my service needs a database or API client, I pass it in through the constructor. This makes the code much easier to test and change later.';
      feedbackText = 'Detailed technical evaluation.';
      scoreVal = 80;
      topicName = 'Architecture';
    }

    final isHigh = scoreVal >= 75;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Question Review',
            subtitle: 'Question ${_index + 1} of $total',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Question selector chips
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(total, (i) {
                  final isSelected = _index == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _index = i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected ? colors.primary : colors.border),
                        ),
                        child: Text(
                          'Q${i + 1}',
                          style: AppTypography.semiBold(
                            12,
                            color: isSelected
                                ? colors.primaryForeground
                                : colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Scrollable Question Review Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PillBadge(
                                label: topicName.toUpperCase(),
                                tone: PillTone.muted),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isHigh ? colors.mint : colors.coral)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$scoreVal / 100',
                                style: AppTypography.bold(12,
                                    color: isHigh ? colors.mint : colors.coral),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          questionText,
                          style: AppTypography.bold(16,
                              color: colors.foreground, height: 1.35),
                        ),
                      ],
                    ),
                  ),

                  // Candidate Answer Section
                  const SectionTitle(title: 'Your Transcribed Answer'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            FeatherIcons.user,
                            size: 15,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            answerText,
                            style: AppTypography.regular(13,
                                color: colors.foreground, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expected / Ideal Human Answer Section
                  if (expectedAnswerText.isNotEmpty) ...[
                    const SectionTitle(title: 'Expected / Model Answer'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.mint.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.mint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colors.mint.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  FeatherIcons.check,
                                  size: 12,
                                  color: colors.mint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How a real engineer answers naturally:',
                                style: AppTypography.bold(12, color: colors.mint),
                              ),
                              const Spacer(),
                              Text(
                                'Simple English',
                                style: AppTypography.medium(10,
                                    color: colors.mutedForeground),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            expectedAnswerText,
                            style: AppTypography.regular(13,
                                color: colors.foreground, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // AI Evaluator Feedback Section
                  if (feedbackText.isNotEmpty) ...[
                    const SectionTitle(title: 'Interviewer Feedback & Coaching'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: (isHigh ? colors.mint : colors.coral)
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isHigh ? FeatherIcons.checkCircle : FeatherIcons.info,
                            size: 16,
                            color: isHigh ? colors.mint : colors.coral,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feedbackText,
                              style: AppTypography.regular(13,
                                  color: colors.foreground, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
