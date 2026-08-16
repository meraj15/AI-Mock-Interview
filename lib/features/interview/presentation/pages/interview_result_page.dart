import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/interview_controller.dart';
import 'create_interview_page.dart';
import 'question_review_page.dart';

class InterviewResultPage extends StatelessWidget {
  const InterviewResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final eval = interviewCtrl.lastEvaluation;

    final overallScore = eval?.overallScore ?? 82;
    final performanceLabel = eval?.performanceLabel ?? 'Strong performance';
    final summary = eval?.summary ??
        'You explained your project clearly and showed strong Flutter fundamentals. Go deeper on architectural trade-offs next time.';

    final scores = eval != null
        ? eval.skillScores.entries.map((e) {
            final val = e.value;
            final note = val >= 85
                ? 'Strong'
                : val >= 75
                    ? 'Good'
                    : 'Growing';
            return {'label': e.key, 'value': val, 'note': note};
          }).toList()
        : [
            {'label': 'Technical knowledge', 'value': 86, 'note': 'Strong'},
            {'label': 'Communication', 'value': 78, 'note': 'Good'},
            {'label': 'Problem solving', 'value': 84, 'note': 'Strong'},
            {'label': 'Confidence', 'value': 75, 'note': 'Growing'},
            {'label': 'Role knowledge', 'value': 88, 'note': 'Strong'},
          ];

    final strengths = eval?.strengths ?? [
      'Strong grasp of Flutter core principles and clean architectural separation.',
      'Articulate explanation of real project workflows and API integration.',
    ];

    final areasToImprove = eval?.areasToImprove ?? [
      'Go deeper on system design trade-offs and offline sync edge cases.',
      'Include measurable metrics and business impact in behavioral answers.',
    ];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(FeatherIcons.x, size: 21, color: colors.foreground),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavPage()),
                      (route) => false,
                    );
                  },
                ),
                Text(
                  'Interview Result',
                  style: AppTypography.bold(17, color: colors.foreground),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Score Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.mint, width: 5),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$overallScore',
                        style: AppTypography.bold(42, color: Colors.white),
                      ),
                      Text(
                        '/ 100',
                        style: AppTypography.medium(12, color: const Color(0xFFBFCBE5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PillBadge(label: performanceLabel, tone: PillTone.success),
                const SizedBox(height: 10),
                Text(
                  '${interviewCtrl.config.role} · ${interviewCtrl.config.type}',
                  style: AppTypography.regular(11, color: const Color(0xFFBFCBE5)),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Performance Overview'),

          // Performance Overview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: scores.map((item) {
                final label = item['label'] as String;
                final value = item['value'] as int;
                final note = item['note'] as String;
                final isGrowing = note == 'Growing';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: AppTypography.medium(12, color: colors.foreground),
                          ),
                          Text(
                            note,
                            style: AppTypography.regular(10, color: colors.mutedForeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ProgressBar(
                              value: value.toDouble(),
                              color: isGrowing ? colors.coral : colors.primary,
                              height: 7,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '$value%',
                              style: AppTypography.bold(12, color: colors.foreground),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // AI Summary
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.star, size: 17, color: colors.navy),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Summary',
                        style: AppTypography.bold(13, color: colors.foreground),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        summary,
                        style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'What You Did Well'),
          ...strengths.map((str) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FeatherIcons.checkCircle, size: 16, color: colors.success),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      str,
                      style: AppTypography.regular(12, color: colors.foreground, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SectionTitle(title: 'Areas To Improve'),
          ...areasToImprove.map((gap) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FeatherIcons.arrowUpRight, size: 16, color: colors.coral),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      gap,
                      style: AppTypography.regular(12, color: colors.foreground, height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SectionTitle(title: 'Recommended Practice Drill'),

          // Next Drill Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateInterviewPage()),
                );
              },
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.coral,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.compass, size: 17, color: colors.ink),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice System Design & Trade-offs',
                            style: AppTypography.semiBold(13, color: colors.foreground),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A focused 5-minute drill tailored to your growth areas.',
                            style: AppTypography.regular(10, color: colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Icon(FeatherIcons.chevronRight, size: 17, color: colors.mutedForeground),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          AppButton(
            label: 'Question-by-Question Review',
            variant: ButtonVariant.secondary,
            onPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuestionReviewPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Start Another Interview',
            icon: FeatherIcons.rotateCcw,
            onPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateInterviewPage()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
