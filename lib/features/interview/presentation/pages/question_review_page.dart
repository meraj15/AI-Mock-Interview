import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/services/ai_interview_service.dart';
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
    final evaluations = eval?.questionEvaluations ?? [];

    final total = evaluations.isNotEmpty ? evaluations.length : 3;

    // Active item data
    final DetailedQuestionEvaluation item = evaluations.isNotEmpty && _index < evaluations.length
        ? evaluations[_index]
        : DetailedQuestionEvaluation(
            questionIndex: _index + 1,
            primaryQuestion: 'Can you walk me through one Flutter project you have architected?',
            category: 'Project Architecture',
            candidateAnswer:
                'I built an application where I owned the mobile architecture, state management with Provider, and integrated with backend REST endpoints.',
            score: 8.5,
            strengths: [
              'Clear explanation of architectural layers and state predictability.',
              'Good articulation of domain models vs DTO mappings.',
            ],
            missingPoints: [
              'Did not specify exact caching mechanisms for offline packet drops.',
              'Omitted measurable business metrics (e.g. latency drop or crash rate).',
            ],
            idealModelAnswer:
                'In my OTT mobile app, I architected the project using Clean Architecture with Riverpod and Dio. To survive intermittent network drops, I combined an offline SQLite cache with a mutation queue that resolved sync conflicts automatically, dropping buffer latency by 35%.',
            starScorecard: const StarScorecard(
              situationScore: 8.8,
              situationFeedback: 'Strong context on project scale and stack.',
              taskScore: 8.5,
              taskFeedback: 'Clear engineering ownership described.',
              actionScore: 9.0,
              actionFeedback: 'Explicit patterns and tooling named.',
              resultScore: 7.8,
              resultFeedback: 'Recommend concluding with concrete metrics.',
            ),
            coachTip: 'Use the STAR format: Situation, Task, Action, and measurable Result.',
          );

    final scoreStr = item.score.toStringAsFixed(1);
    final isHigh = item.score >= 8.0;

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
            padding: const EdgeInsets.only(top: 6.0, bottom: 14.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? colors.primary : colors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Q${i + 1}',
                              style: AppTypography.semiBold(
                                12,
                                color: isSelected ? colors.primaryForeground : colors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

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
                    PillBadge(label: item.category.toUpperCase(), tone: PillTone.muted),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isHigh ? colors.mint : colors.coral).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$scoreStr / 10',
                        style: AppTypography.bold(12, color: isHigh ? colors.mint : colors.coral),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.primaryQuestion,
                  style: AppTypography.bold(16, color: colors.foreground, height: 1.35),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Your Transcribed Answer'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              item.candidateAnswer,
              style: AppTypography.regular(12, color: colors.foreground, height: 1.5),
            ),
          ),

          const SectionTitle(title: 'Ideal Model Exemplar Answer'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.mint.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FeatherIcons.award, size: 14, color: colors.mint),
                    const SizedBox(width: 6),
                    Text(
                      'How a Senior Engineer would structure this:',
                      style: AppTypography.bold(11, color: colors.mint),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.idealModelAnswer,
                  style: AppTypography.regular(12, color: colors.foreground, height: 1.55),
                ),
              ],
            ),
          ),

          // STAR Scorecard
          if (item.starScorecard != null) ...[
            const SectionTitle(title: 'STAR Methodology Scorecard'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _buildStarRow('Situation', item.starScorecard!.situationScore, item.starScorecard!.situationFeedback, colors),
                  Divider(color: colors.border, height: 20),
                  _buildStarRow('Task', item.starScorecard!.taskScore, item.starScorecard!.taskFeedback, colors),
                  Divider(color: colors.border, height: 20),
                  _buildStarRow('Action', item.starScorecard!.actionScore, item.starScorecard!.actionFeedback, colors),
                  Divider(color: colors.border, height: 20),
                  _buildStarRow('Result', item.starScorecard!.resultScore, item.starScorecard!.resultFeedback, colors),
                ],
              ),
            ),
          ],

          const SectionTitle(title: 'Missing Trade-offs & Keywords'),
          ...item.missingPoints.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FeatherIcons.alertCircle, size: 14, color: colors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pt,
                      style: AppTypography.regular(11, color: colors.foreground, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SectionTitle(title: 'AI Coach Tip'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FeatherIcons.zap, size: 16, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.coachTip,
                    style: AppTypography.semiBold(11, color: colors.foreground, height: 1.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStarRow(String pillar, double score, String feedback, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(pillar, style: AppTypography.bold(12, color: colors.foreground)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${score.toStringAsFixed(1)} / 10',
                style: AppTypography.bold(10, color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          feedback,
          style: AppTypography.regular(10, color: colors.mutedForeground, height: 1.4),
        ),
      ],
    );
  }
}
