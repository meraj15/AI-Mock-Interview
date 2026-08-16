import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/stat_card.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final points = [58, 66, 63, 74, 71, 82, 78, 86];

    final skills = [
      {'label': 'Technical knowledge', 'value': 86, 'color': colors.primary},
      {'label': 'Communication', 'value': 78, 'color': colors.coral},
      {'label': 'Problem solving', 'value': 84, 'color': colors.violet},
      {'label': 'Confidence', 'value': 75, 'color': colors.yellow},
    ];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SectionTitle(title: 'Analytics', action: 'Last 30 days'),
          Text(
            'A clearer view of how your interview readiness is changing.',
            style: AppTypography.regular(13, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Average score',
                  value: '78%',
                  change: '+14% overall',
                  icon: FeatherIcons.trendingUp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Completion rate',
                  value: '92%',
                  change: '+5% this month',
                  icon: FeatherIcons.checkCircle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Score over time chart card
          Container(
            padding: const EdgeInsets.all(16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score over time',
                          style: AppTypography.bold(15, color: colors.foreground),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Last 8 interviews',
                          style: AppTypography.regular(10, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    Icon(FeatherIcons.moreHorizontal, size: 19, color: colors.mutedForeground),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart Container
                SizedBox(
                  height: 145,
                  child: Stack(
                    children: [
                      // Grid Lines
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: colors.border),
                      ),
                      Positioned(
                        top: 72,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: colors.border),
                      ),
                      Positioned(
                        bottom: 22,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: colors.border),
                      ),

                      // Bars
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: points.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;
                            final isLast = index == points.length - 1;
                            final barHeight = (point / 100) * 110;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 18,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: isLast ? colors.primary : colors.mint,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${index + 1}',
                                  style: AppTypography.medium(9, color: colors.mutedForeground),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Skill distribution'),

          // Skill Distribution Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: skills.map((skill) {
                final value = (skill['value'] as int).toDouble();
                final color = skill['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            skill['label'] as String,
                            style: AppTypography.medium(12, color: colors.foreground),
                          ),
                          Text(
                            '${value.toInt()}%',
                            style: AppTypography.bold(12, color: colors.foreground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        value: value,
                        color: color,
                        height: 7,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // AI Insight Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(18),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI insight',
                        style: AppTypography.bold(13, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your technical performance improved by 14% over your last five interviews.',
                        style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                      ),
                    ],
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
}
