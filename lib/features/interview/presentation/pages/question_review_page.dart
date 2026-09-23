import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/ai_interview_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../controllers/interview_controller.dart';

class QuestionReviewPage extends StatefulWidget {
  final List<QuestionReview>? questions;
  final String? role;

  const QuestionReviewPage({
    super.key,
    this.questions,
    this.role,
  });

  @override
  State<QuestionReviewPage> createState() => _QuestionReviewPageState();
}

class _QuestionReviewPageState extends State<QuestionReviewPage> {
  int _index = 0;
  late final PageController _pageController;
  final ScrollController _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _scrollToChip(int index) {
    if (!_chipScrollController.hasClients) return;
    final targetOffset = (index * 58.0) - 100.0;
    _chipScrollController.animateTo(
      targetOffset.clamp(0.0, _chipScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToPage(int page) {
    setState(() => _index = page);
    if (_pageController.hasClients && _pageController.page?.round() != page) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _scrollToChip(page);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final eval = interviewCtrl.lastEvaluation;
    final reviews = widget.questions ?? eval?.questionReviews ?? [];
    final history = interviewCtrl.sessionHistory;

    final total = reviews.isNotEmpty
        ? reviews.length
        : history.isNotEmpty
            ? history.length
            : 1;

    if (_index >= total) {
      _index = (total - 1).clamp(0, total);
      if (_pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_index);
          }
        });
      }
    }

    return AppScaffold(
      scrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppHeader(
              title: 'Question Review',
              subtitle: 'Question ${_index + 1} of $total',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          // Question selector chips
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
            child: SingleChildScrollView(
              controller: _chipScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(total, (i) {
                  final isSelected = _index == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: () => _goToPage(i),
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

          // Swipable / Slideable Question Review Content with spacing between questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              onPageChanged: (i) {
                setState(() => _index = i);
                _scrollToChip(i);
              },
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: _buildQuestionContent(
                    context: context,
                    index: i,
                    colors: colors,
                    reviews: reviews,
                    history: history,
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Buttons (Prev / Next & Dots)
          if (total > 1) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _index > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.foreground,
                      disabledForegroundColor:
                          colors.mutedForeground.withValues(alpha: 0.35),
                      textStyle: AppTypography.semiBold(13),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.chevronLeft, size: 18),
                        SizedBox(width: 4),
                        Text('Previous'),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(total, (dotIndex) {
                      final isActive = dotIndex == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? colors.primary : colors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _index < total - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      disabledForegroundColor:
                          colors.mutedForeground.withValues(alpha: 0.35),
                      textStyle: AppTypography.semiBold(13),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next'),
                        SizedBox(width: 4),
                        Icon(FeatherIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionContent({
    required BuildContext context,
    required int index,
    required AppColorScheme colors,
    required List<QuestionReview> reviews,
    required List<Map<String, dynamic>> history,
  }) {
    final String questionText;
    final String answerText;
    final String expectedAnswerText;
    final String feedbackText;
    final int scoreVal;
    final String topicName;

    if (reviews.isNotEmpty && index < reviews.length) {
      final r = reviews[index];
      questionText = r.question;
      answerText = r.answer.isNotEmpty ? r.answer : 'No answer provided.';
      expectedAnswerText = r.expectedAnswer;
      feedbackText = r.feedback;
      scoreVal = r.score;
      topicName = history.isNotEmpty && index < history.length
          ? (history[index]['topic'] ?? 'Question ${index + 1}')
          : 'Question ${index + 1}';
    } else if (history.isNotEmpty && index < history.length) {
      final h = history[index];
      questionText = h['question'] ?? 'Question';
      answerText = (h['answer']?.isNotEmpty ?? false)
          ? h['answer']!
          : 'No answer provided.';
      expectedAnswerText = '';
      feedbackText = '';
      scoreVal = 0;
      topicName = h['topic'] ?? 'Question ${index + 1}';
    } else {
      questionText = 'No recorded questions found for this session.';
      answerText = 'No response captured.';
      expectedAnswerText = '';
      feedbackText = '';
      scoreVal = 0;
      topicName = 'Review';
    }

    final isHigh = scoreVal >= 75;

    return SingleChildScrollView(
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
                    Flexible(
                      child: PillBadge(
                        label: topicName.toUpperCase(),
                        tone: PillTone.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      Expanded(
                        child: Text(
                          'How a strong candidate answers:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bold(12, color: colors.mint),
                        ),
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
    );
  }
}
