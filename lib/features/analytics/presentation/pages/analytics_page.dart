import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reuse the same DashboardController — no double fetch if already loaded.
      final ctrl = context.read<DashboardController>();
      if (ctrl.loadState == DashboardLoadState.idle) {
        ctrl.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors    = AppColorScheme.of(context);
    final dashboard = context.watch<DashboardController>();
    final stats     = dashboard.stats;
    final isLoading = dashboard.isLoading;
    final hasError  = dashboard.loadState == DashboardLoadState.error;

    // ── Score history for bar chart ─────────────────────────────────────────
    // Use real data when available, show placeholder bars while loading
    final scoreHistory = stats.scoreHistory.isNotEmpty
        ? stats.scoreHistory
        : <int>[];

    // ── Skill rows ──────────────────────────────────────────────────────────
    // If the backend returns skill averages, use them; otherwise show nothing
    final skillColors = [
      colors.primary,
      colors.coral,
      colors.violet,
      colors.yellow,
      colors.mint,
    ];
    final skillEntries = stats.skillAverages.entries.toList();

    // ── AI insight text ─────────────────────────────────────────────────────
    final insightText = _buildInsight(stats.overallChange, stats.totalInterviews,
        stats.averageScore, stats.currentStreak);

    // ── Completion rate label ───────────────────────────────────────────────
    final completionLabel = stats.totalInterviews == 0
        ? '—'
        : '${stats.completionRate}%';

    final overallChangeLabel = stats.totalInterviews < 2
        ? null
        : '${stats.overallChange >= 0 ? '+' : ''}${stats.overallChange}% overall';

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SectionTitle(
            title: 'Analytics',
            action: 'Last 30 days',
            onAction: () => context.read<DashboardController>().load(),
          ),
          Text(
            'A clearer view of how your interview readiness is changing.',
            style: AppTypography.regular(13, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),

          // ── Top stat cards ───────────────────────────────────────────────
          if (isLoading)
            _shimmerRow(colors)
          else
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Average score',
                    value: dashboard.avgScoreLabel,
                    change: overallChangeLabel,
                    icon: FeatherIcons.trendingUp,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Completion rate',
                    value: completionLabel,
                    change: stats.totalInterviews == 0
                        ? null
                        : '${stats.totalInterviews} sessions',
                    icon: FeatherIcons.checkCircle,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // ── Score over time ──────────────────────────────────────────────
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
                          style: AppTypography.bold(15,
                              color: colors.foreground),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoading
                              ? 'Loading…'
                              : scoreHistory.isEmpty
                                  ? 'No interviews yet'
                                  : 'Last ${scoreHistory.length} interview${scoreHistory.length == 1 ? '' : 's'}',
                          style: AppTypography.regular(10,
                              color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    if (!isLoading && !hasError && scoreHistory.isNotEmpty)
                      Text(
                        'Avg ${stats.averageScore}',
                        style: AppTypography.semiBold(11,
                            color: colors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 145,
                  child: isLoading
                      ? _shimmerBox(colors, height: 110)
                      : scoreHistory.isEmpty
                          ? _emptyChart(colors)
                          : _ScoreBarChart(
                              scores: scoreHistory,
                              colors: colors,
                            ),
                ),
              ],
            ),
          ),

          // ── Skill distribution ───────────────────────────────────────────
          const SectionTitle(title: 'Skill distribution'),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: isLoading
                ? _shimmerBox(colors, height: 120)
                : skillEntries.isEmpty
                    ? _emptySkills(colors)
                    : Column(
                        children: skillEntries
                            .asMap()
                            .entries
                            .map((entry) {
                              final i     = entry.key;
                              final label = entry.value.key;
                              final value = entry.value.value.toDouble();
                              final color =
                                  skillColors[i % skillColors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: AppTypography.medium(12,
                                                color: colors.foreground),
                                          ),
                                        ),
                                        Text(
                                          '${value.toInt()}%',
                                          style: AppTypography.bold(12,
                                              color: colors.foreground),
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
                            })
                            .toList(),
                      ),
          ),

          const SizedBox(height: 16),

          // ── AI insight ───────────────────────────────────────────────────
          if (!isLoading)
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
                    child: Icon(FeatherIcons.star,
                        size: 17, color: colors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI insight',
                          style: AppTypography.bold(13,
                              color: colors.foreground),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insightText,
                          style: AppTypography.regular(11,
                              color: colors.mutedForeground, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (hasError) ...[
            const SizedBox(height: 12),
            _ErrorBanner(
              colors: colors,
              message: dashboard.errorMessage ??
                  'Could not load analytics data.',
              onRetry: () => context.read<DashboardController>().load(),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _buildInsight(
      int overallChange, int total, int avg, int streak) {
    if (total == 0) {
      return 'Complete your first interview to unlock personalised insights.';
    }
    if (total == 1) {
      return 'Great start! Your first interview scored $avg. '
          'Keep practising to track your improvement.';
    }
    final trendWord = overallChange > 0
        ? 'improved by ${overallChange}%'
        : overallChange < 0
            ? 'declined by ${overallChange.abs()}%'
            : 'stayed consistent';
    final streakNote = streak >= 3
        ? ' You\'re on a $streak-day streak — keep it up!'
        : '';
    return 'Your performance has $trendWord across your last $total sessions.$streakNote';
  }

  Widget _shimmerRow(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(child: _shimmerBox(colors, height: 90)),
        const SizedBox(width: 10),
        Expanded(child: _shimmerBox(colors, height: 90)),
      ],
    );
  }

  Widget _shimmerBox(AppColorScheme colors, {double height = 60}) =>
      Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
      );

  Widget _emptyChart(AppColorScheme colors) => Center(
        child: Text(
          'Complete interviews to see your score trend.',
          style: AppTypography.regular(12, color: colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      );

  Widget _emptySkills(AppColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Skill averages appear after your first completed interview.',
          style:
              AppTypography.regular(12, color: colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      );
}

// ── Dynamic bar chart ─────────────────────────────────────────────────────────

class _ScoreBarChart extends StatelessWidget {
  final List<int> scores;
  final AppColorScheme colors;

  const _ScoreBarChart({required this.scores, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxScore = scores.isEmpty
        ? 100
        : scores.reduce((a, b) => a > b ? a : b);
    final clampedMax = maxScore < 10 ? 100 : maxScore;

    return Stack(
      children: [
        // Grid lines
        Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 1, color: colors.border)),
        Positioned(
            top: 55, left: 0, right: 0,
            child: Container(height: 1, color: colors.border)),
        Positioned(
            bottom: 22, left: 0, right: 0,
            child: Container(height: 1, color: colors.border)),

        // Bars
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: scores.asMap().entries.map((entry) {
              final index   = entry.key;
              final score   = entry.value;
              final isLast  = index == scores.length - 1;
              final barH    = ((score / clampedMax) * 110).clamp(4.0, 110.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Score label on top of bar
                  Text(
                    '$score',
                    style: AppTypography.bold(
                      8,
                      color: isLast ? colors.primary : colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 18,
                    height: barH,
                    decoration: BoxDecoration(
                      color: isLast ? colors.primary : colors.mint,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${index + 1}',
                    style: AppTypography.medium(9,
                        color: colors.mutedForeground),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.wifiOff, size: 15, color: colors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTypography.regular(12, color: colors.mutedForeground)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: AppTypography.semiBold(12, color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
