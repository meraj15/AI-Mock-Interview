import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/pages/create_interview_page.dart';
import '../../../job_prep/presentation/pages/job_prep_page.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    final topics = [
      {
        'title': 'System design',
        'body': 'Architecture, trade-offs, scale',
        'icon': FeatherIcons.share2,
        'color': colors.coral,
        'progress': 42,
      },
      {
        'title': 'Behavioral stories',
        'body': 'Make your impact memorable',
        'icon': FeatherIcons.messageSquare,
        'color': colors.mint,
        'progress': 68,
      },
      {
        'title': 'Technical depth',
        'body': 'Explain the why, not just the how',
        'icon': FeatherIcons.cpu,
        'color': colors.violet,
        'progress': 78,
      },
    ];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SectionTitle(title: 'Practice', action: 'See all topics'),
          Text(
            'Short, focused sessions to sharpen the areas that matter most.',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Focus Mode Hero
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateInterviewPage()),
                );
              },
              borderRadius: BorderRadius.circular(23),
              child: Ink(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FOCUS MODE',
                            style: AppTypography.bold(10, color: colors.mint, letterSpacing: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'One question. Better answers.',
                            style: AppTypography.bold(23, color: Colors.white, height: 1.18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a 5-minute drill tailored to your goals.',
                            style: AppTypography.regular(11, color: const Color(0xFFBFCBE5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.target, size: 23, color: colors.navy),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 11),

          // Prepare for a Job Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobPrepPage()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.coral,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.briefcase, size: 18, color: colors.ink),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prepare for a job',
                            style: AppTypography.semiBold(13, color: colors.foreground),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Compare a job description to your resume.',
                            style: AppTypography.regular(10, color: colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Icon(FeatherIcons.arrowUpRight, size: 17, color: colors.primary),
                  ],
                ),
              ),
            ),
          ),

          const SectionTitle(title: 'Your focus areas'),

          // Focus Topics
          ...topics.map((topic) {
            final progress = (topic['progress'] as int).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateInterviewPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: topic['color'] as Color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(topic['icon'] as IconData, size: 19, color: colors.ink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic['title'] as String,
                                style: AppTypography.semiBold(14, color: colors.foreground),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                topic['body'] as String,
                                style: AppTypography.regular(10, color: colors.mutedForeground),
                              ),
                              const SizedBox(height: 8),
                              ProgressBar(
                                value: progress,
                                height: 5,
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${progress.toInt()}%',
                          style: AppTypography.bold(12, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
