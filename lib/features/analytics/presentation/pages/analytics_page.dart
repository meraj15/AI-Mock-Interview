import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../interview/data/datasources/interview_remote_data_source.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<DashboardController>();
      if (ctrl.loadState == DashboardLoadState.idle) {
        ctrl.load();
      } else {
        ctrl.loadAnalytics();
      }
    });
  }

  void _onTimeframeSelected(int days) {
    setState(() => _selectedBarIndex = null);
    context.read<DashboardController>().setAnalyticsDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final dashboard = context.watch<DashboardController>();
    final stats = dashboard.analyticsStats;
    final selectedDays = dashboard.analyticsDays;
    final isLoading = dashboard.isAnalyticsLoading && stats == InterviewStatsModel.empty;
    final isSwitching = dashboard.isAnalyticsLoading && stats != InterviewStatsModel.empty;
    final hasError = dashboard.analyticsError != null;

    final scoreHistory = stats.scoreHistory;

    // Completion label
    final completionLabel = stats.totalInterviews == 0
        ? '—'
        : '${stats.completionRate}%';

    // Overall change label
    final overallChangeLabel = stats.totalInterviews < 2
        ? null
        : '${stats.overallChange >= 0 ? '+' : ''}${stats.overallChange}% vs prior';

    // AI insight text
    final insightText = _buildInsight(
      days: selectedDays,
      total: stats.totalInterviews,
      avg: stats.averageScore,
      change: stats.overallChange,
      best: stats.bestScore,
    );

    return AppScaffold(
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.card,
        onRefresh: () => dashboard.loadAnalytics(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header Title & Dropdown Filter ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Analytics',
                          style: AppTypography.bold(22, color: colors.foreground),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Track your readiness and skill progression.',
                          style: AppTypography.regular(12, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TimeframeDropdown(
                    selectedDays: selectedDays,
                    onSelected: _onTimeframeSelected,
                    colors: colors,
                    isSwitching: isSwitching,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Top KPI Stat Cards (Average Score & Completion Rate only) ──
              if (isLoading)
                _shimmerRow(colors)
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Average Score',
                          value: stats.totalInterviews == 0 ? '—' : '${stats.averageScore}%',
                          change: overallChangeLabel,
                          icon: FeatherIcons.trendingUp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Completion Rate',
                          value: completionLabel,
                          change: stats.totalInterviews > 0
                              ? '${stats.totalInterviews} sessions'
                              : null,
                          icon: FeatherIcons.checkCircle,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // ── Score Trajectory Chart Card ────────────────────────────────
              _ScoreTrajectoryCard(
                days: selectedDays,
                scores: scoreHistory,
                averageScore: stats.averageScore,
                isLoading: isLoading,
                colors: colors,
                selectedIndex: _selectedBarIndex,
                onSelectBar: (i) => setState(() => _selectedBarIndex = i),
              ),

              const SizedBox(height: 18),

              // ── Skill Breakdown Section (if available) ──────────────────────
              if (!isLoading && stats.skillAverages.isNotEmpty) ...[
                _SkillCompetencyCard(
                  skillAverages: stats.skillAverages,
                  colors: colors,
                ),
                const SizedBox(height: 18),
              ],

              // ── AI Performance Insight Card ─────────────────────────────────
              if (!isLoading)
                _AiInsightCard(
                  insightText: insightText,
                  colors: colors,
                ),

              if (hasError) ...[
                const SizedBox(height: 14),
                _ErrorBanner(
                  colors: colors,
                  message: dashboard.analyticsError ?? 'Could not load analytics data.',
                  onRetry: () => dashboard.loadAnalytics(forceRefresh: true),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Insight Builder ────────────────────────────────────────────────────────

  String _buildInsight({
    required int days,
    required int total,
    required int avg,
    required int change,
    required int best,
  }) {
    if (total == 0) {
      return 'No interviews completed in the last $days days. Practice a session to generate real-time performance analytics.';
    }
    if (total == 1) {
      return 'You completed 1 interview in the last $days days with a score of $avg%. Keep practicing to reveal readiness trends.';
    }

    final trendClause = change > 0
        ? 'improved by $change%'
        : change < 0
            ? 'shifted by ${change.abs()}%'
            : 'remained rock solid';

    final bestNote = best >= 80
        ? ' Your peak score of $best% indicates strong interview readiness.'
        : '';

    return 'Across $total sessions in the last $days days, your performance has $trendClause with an average of $avg%.$bestNote';
  }

  Widget _shimmerRow(AppColorScheme colors) {
    return AppShimmer(
      child: Row(
        children: [
          Expanded(child: _shimmerBox(colors, height: 95)),
          const SizedBox(width: 12),
          Expanded(child: _shimmerBox(colors, height: 95)),
        ],
      ),
    );
  }

  Widget _shimmerBox(AppColorScheme colors, {double height = 60}) =>
      ShimmerBox(
        height: height,
        borderRadius: 18,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Timeframe Dropdown (Smooth, Modern & Interactive)
// ─────────────────────────────────────────────────────────────────────────────

class _TimeframeDropdown extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onSelected;
  final AppColorScheme colors;
  final bool isSwitching;

  const _TimeframeDropdown({
    required this.selectedDays,
    required this.onSelected,
    required this.colors,
    required this.isSwitching,
  });

  static const _options = [
    {'days': 7, 'label': 'Last 7 Days'},
    {'days': 15, 'label': 'Last 15 Days'},
    {'days': 30, 'label': 'Last 30 Days'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentOpt = _options.firstWhere(
      (opt) => opt['days'] == selectedDays,
      orElse: () => _options.last,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border.withValues(alpha: 0.8), width: 1),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.25),
        ),
      ),
      child: PopupMenuButton<int>(
        tooltip: 'Select timeframe',
        initialValue: selectedDays,
        onSelected: onSelected,
        offset: const Offset(0, 40),
        elevation: 8,
        itemBuilder: (ctx) => _options.map((opt) {
          final days = opt['days'] as int;
          final label = opt['label'] as String;
          final isSelected = selectedDays == days;

          return PopupMenuItem<int>(
            value: days,
            height: 44,
            child: Row(
              children: [
                Icon(
                  FeatherIcons.calendar,
                  size: 14,
                  color: isSelected ? colors.primary : colors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: isSelected
                        ? AppTypography.bold(13, color: colors.foreground)
                        : AppTypography.medium(13, color: colors.mutedForeground),
                  ),
                ),
                if (isSelected)
                  Icon(
                    FeatherIcons.check,
                    size: 15,
                    color: colors.primary,
                  ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FeatherIcons.calendar,
                size: 13,
                color: colors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                currentOpt['label'] as String,
                style: AppTypography.semiBold(12, color: colors.foreground),
              ),
              const SizedBox(width: 6),
              if (isSwitching)
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                )
              else
                Icon(
                  FeatherIcons.chevronDown,
                  size: 13,
                  color: colors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Score Trajectory Chart Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreTrajectoryCard extends StatelessWidget {
  final int days;
  final List<int> scores;
  final int averageScore;
  final bool isLoading;
  final AppColorScheme colors;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectBar;

  const _ScoreTrajectoryCard({
    required this.days,
    required this.scores,
    required this.averageScore,
    required this.isLoading,
    required this.colors,
    required this.selectedIndex,
    required this.onSelectBar,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = scores.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score Trajectory',
                    style: AppTypography.bold(15, color: colors.foreground),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasData
                        ? '${scores.length} session${scores.length == 1 ? '' : 's'} in last $days days'
                        : 'No session data in this period',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                ],
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.mint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.mint.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.mint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Avg $averageScore%',
                        style: AppTypography.bold(11, color: colors.foreground),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Selected Bar Inspection Info Banner
          if (hasData && selectedIndex != null && selectedIndex! < scores.length) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session #${selectedIndex! + 1}',
                    style: AppTypography.semiBold(12, color: colors.foreground),
                  ),
                  Row(
                    children: [
                      Text(
                        'Score: ${scores[selectedIndex!]}%',
                        style: AppTypography.bold(12, color: colors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scores[selectedIndex!] >= 80
                            ? '• Strong'
                            : (scores[selectedIndex!] >= 65 ? '• Good' : '• Developing'),
                        style: AppTypography.medium(11, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Chart Canvas
          SizedBox(
            height: 165,
            child: isLoading
                ? AppShimmer(
                    child: ShimmerBox(height: 130, borderRadius: 16),
                  )
                : !hasData
                    ? _buildEmptyState()
                    : _InteractiveScoreChart(
                        scores: scores,
                        averageScore: averageScore,
                        colors: colors,
                        selectedIndex: selectedIndex,
                        onSelect: onSelectBar,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.barChart2, size: 20, color: colors.mutedForeground),
          ),
          const SizedBox(height: 10),
          Text(
            'No sessions in the last $days days',
            style: AppTypography.semiBold(12, color: colors.foreground),
          ),
          const SizedBox(height: 3),
          Text(
            'Select 15 Days or 30 Days to view previous sessions',
            style: AppTypography.regular(10, color: colors.mutedForeground),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Interactive Animated Score Chart with Benchmark Line
// ─────────────────────────────────────────────────────────────────────────────

class _InteractiveScoreChart extends StatelessWidget {
  final List<int> scores;
  final int averageScore;
  final AppColorScheme colors;
  final int? selectedIndex;
  final ValueChanged<int?> onSelect;

  const _InteractiveScoreChart({
    required this.scores,
    required this.averageScore,
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const maxScore = 100;
    const chartHeight = 120.0;

    // Benchmark line vertical offset from bottom
    final avgY = ((averageScore / maxScore) * chartHeight).clamp(0.0, chartHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Background grid lines (0%, 50%, 100%)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 1, color: colors.border.withValues(alpha: 0.6)),
            ),
            Positioned(
              top: chartHeight * 0.5,
              left: 0,
              right: 0,
              child: Container(height: 1, color: colors.border.withValues(alpha: 0.35)),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Container(height: 1, color: colors.border.withValues(alpha: 0.8)),
            ),

            // Average Benchmark Dashed Indicator
            if (averageScore > 0)
              Positioned(
                bottom: 24 + avgY,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.2,
                        color: colors.mint.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg $averageScore',
                      style: AppTypography.bold(8, color: colors.mint),
                    ),
                  ],
                ),
              ),

            // Animated Bars
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              top: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: scores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final score = entry.value;
                  final isSelected = selectedIndex == index;
                  final isLast = index == scores.length - 1;
                  final isHighest = score == scores.reduce((a, b) => a > b ? a : b);

                  final targetBarH = ((score / maxScore) * chartHeight).clamp(8.0, chartHeight);

                  return GestureDetector(
                    onTap: () {
                      if (selectedIndex == index) {
                        onSelect(null);
                      } else {
                        onSelect(index);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Score label floating above bar
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (isSelected || isLast || isHighest || scores.length <= 10) ? 1.0 : 0.0,
                          child: Text(
                            '$score',
                            style: AppTypography.bold(
                              9,
                              color: isSelected
                                  ? colors.foreground
                                  : (isHighest ? colors.mint : colors.mutedForeground),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Animated Growing Bar
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: targetBarH),
                          duration: Duration(milliseconds: 400 + (index * 40).clamp(0, 300)),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedH, _) {
                            return Container(
                              width: scores.length > 15 ? 12 : (scores.length > 8 ? 16 : 22),
                              height: animatedH,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isSelected
                                      ? [colors.mint, colors.mint.withValues(alpha: 0.85)]
                                      : isHighest
                                          ? [colors.primary, colors.mint]
                                          : isLast
                                              ? [colors.primary, colors.primary.withValues(alpha: 0.75)]
                                              : [
                                                  colors.primary.withValues(alpha: 0.45),
                                                  colors.primary.withValues(alpha: 0.70),
                                                ],
                                ),
                                border: isSelected
                                    ? Border.all(color: colors.foreground, width: 1.5)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.mint.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // X-Axis Labels (Session #)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: scores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final isSelected = selectedIndex == index;
                  // If lots of bars, skip some labels for clarity
                  final shouldShow = scores.length <= 12 ||
                      index == 0 ||
                      index == scores.length - 1 ||
                      index % 2 == 0;

                  return SizedBox(
                    width: scores.length > 15 ? 12 : 22,
                    child: Text(
                      shouldShow ? '#${index + 1}' : '',
                      style: AppTypography.medium(
                        9,
                        color: isSelected ? colors.primary : colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Skill Competencies Card
// ─────────────────────────────────────────────────────────────────────────────

class _SkillCompetencyCard extends StatelessWidget {
  final Map<String, int> skillAverages;
  final AppColorScheme colors;

  const _SkillCompetencyCard({
    required this.skillAverages,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final entries = skillAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skill Competencies',
                style: AppTypography.bold(15, color: colors.foreground),
              ),
              Icon(FeatherIcons.zap, size: 16, color: colors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aggregated average scores across evaluated competencies in this period',
            style: AppTypography.regular(11, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          ...entries.take(5).map((e) {
            final skill = e.key;
            final score = e.value.clamp(0, 100);
            final isTop = score >= 80;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          skill,
                          style: AppTypography.semiBold(12, color: colors.foreground),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$score%',
                        style: AppTypography.bold(
                          12,
                          color: isTop ? colors.mint : colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 100.0,
                      minHeight: 7,
                      backgroundColor: colors.secondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTop ? colors.mint : colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── AI Performance Insight Card
// ─────────────────────────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  final String insightText;
  final AppColorScheme colors;

  const _AiInsightCard({
    required this.insightText,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.mint,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: colors.mint.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.star, size: 18, color: colors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Trajectory Insight',
                  style: AppTypography.bold(13, color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: AppTypography.regular(12, color: colors.mutedForeground, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Error Banner
// ─────────────────────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.wifiOff, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.regular(12, color: colors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: AppTypography.semiBold(12, color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
