import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../interview/data/datasources/interview_remote_data_source.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int? _selectedPointIndex;

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
    setState(() => _selectedPointIndex = null);
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

    final completionLabel = stats.totalInterviews == 0
        ? '—'
        : '${stats.completionRate}%';

    final overallChangeLabel = stats.totalInterviews < 2
        ? null
        : '${stats.overallChange >= 0 ? '+' : ''}${stats.overallChange}% vs prior';

    final insightText = _buildInsight(
      days: selectedDays,
      total: stats.totalInterviews,
      avg: stats.averageScore,
      change: stats.overallChange,
      best: stats.bestScore,
    );

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AppScaffold(
      scrollable: false,
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.card,
        onRefresh: () => dashboard.loadAnalytics(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: 20 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ── 1. Clean Top App Bar ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: AppTypography.bold(24, color: colors.foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Performance & readiness insights',
                    style: AppTypography.regular(12, color: colors.mutedForeground),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── 2. Unified Executive Readiness Overview Card ───────────────
              if (isLoading)
                _shimmerBox(colors, height: 160)
              else
                _ExecutiveHeroCard(
                  stats: stats,
                  completionLabel: completionLabel,
                  overallChangeLabel: overallChangeLabel,
                  colors: colors,
                ),

              const SizedBox(height: 18),

              // ── 3. Score Trajectory Chart Card with In-Card Timeframe Filter ─
              _ScoreTrajectoryCard(
                days: selectedDays,
                scores: scoreHistory,
                averageScore: stats.averageScore,
                isLoading: isLoading,
                isSwitching: isSwitching,
                onSelectDays: _onTimeframeSelected,
                selectedIndex: _selectedPointIndex,
                onSelectPoint: (i) => setState(() => _selectedPointIndex = i),
                colors: colors,
              ),

              const SizedBox(height: 18),

              // ── 4. Skill Competencies Section ──────────────────────────────
              if (!isLoading && stats.skillAverages.isNotEmpty) ...[
                _SkillCompetencyCard(
                  skillAverages: stats.skillAverages,
                  colors: colors,
                ),
                const SizedBox(height: 18),
              ],

              // ── 5. AI Trajectory Insight Card ───────────────────────────────
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
            : 'remained steady';

    final bestNote = best >= 75
        ? ' Your peak score of $best% indicates strong interview readiness.'
        : '';

    return 'Across $total sessions in the last $days days, your performance has $trendClause with an average of $avg%.$bestNote';
  }

  Widget _shimmerBox(AppColorScheme colors, {double height = 60}) =>
      ShimmerBox(
        height: height,
        borderRadius: 20,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 1. Unified Executive Readiness Overview Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExecutiveHeroCard extends StatelessWidget {
  final InterviewStatsModel stats;
  final String completionLabel;
  final String? overallChangeLabel;
  final AppColorScheme colors;

  const _ExecutiveHeroCard({
    required this.stats,
    required this.completionLabel,
    required this.overallChangeLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final avg = stats.averageScore;
    final isReady = avg >= 75;
    final isGood = avg >= 50 && avg < 75;

    final statusLabel = stats.totalInterviews == 0
        ? 'Not Started'
        : (isReady
            ? 'Interview Ready'
            : (isGood ? 'Good Progress' : 'Developing Skill'));

    final statusColor = stats.totalInterviews == 0
        ? colors.mutedForeground
        : (isReady
            ? colors.mint
            : (isGood ? colors.primary : colors.coral));

    final statusIcon = stats.totalInterviews == 0
        ? FeatherIcons.clock
        : (isReady
            ? FeatherIcons.checkCircle
            : (isGood ? FeatherIcons.trendingUp : FeatherIcons.alertCircle));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category label & Readiness Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'READINESS BENCHMARK',
                style: AppTypography.bold(10, color: colors.mutedForeground),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: AppTypography.bold(11, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Big Score + Trend
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats.totalInterviews == 0 ? '—' : '${stats.averageScore}%',
                style: AppTypography.bold(36, color: colors.foreground),
              ),
              const SizedBox(width: 10),
              if (overallChangeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (stats.overallChange >= 0 ? colors.mint : colors.destructive)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    overallChangeLabel!,
                    style: AppTypography.bold(
                      11,
                      color: stats.overallChange >= 0 ? colors.mint : colors.destructive,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 14),

          // 3 Balanced Sub-Metrics
          Row(
            children: [
              Expanded(
                child: _HeroMetricItem(
                  label: 'Completed',
                  value: '${stats.totalInterviews} sessions',
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: colors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _HeroMetricItem(
                  label: 'Completion Rate',
                  value: completionLabel,
                  colors: colors,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: colors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _HeroMetricItem(
                  label: 'Peak Score',
                  value: stats.bestScore > 0 ? '${stats.bestScore}%' : '—',
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme colors;

  const _HeroMetricItem({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.regular(10.5, color: colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.bold(13, color: colors.foreground),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 2. Score Trajectory Card with In-Card Minimalist Timeframe Chips
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreTrajectoryCard extends StatelessWidget {
  final int days;
  final List<int> scores;
  final int averageScore;
  final bool isLoading;
  final bool isSwitching;
  final ValueChanged<int> onSelectDays;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectPoint;
  final AppColorScheme colors;

  const _ScoreTrajectoryCard({
    required this.days,
    required this.scores,
    required this.averageScore,
    required this.isLoading,
    required this.isSwitching,
    required this.onSelectDays,
    required this.selectedIndex,
    required this.onSelectPoint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = scores.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Left (Title + Subtitle), Right (Sleek Timeframe Filter Chips)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score Progression',
                      style: AppTypography.bold(15, color: colors.foreground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? '${scores.length} sessions evaluated'
                          : 'No sessions in this period',
                      style: AppTypography.regular(11, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),

              // In-Card Minimalist Timeframe Filter Chips (e.g. 7D · 15D · 30D)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimeframeChip(
                      label: '7D',
                      days: 7,
                      isSelected: days == 7,
                      isLoading: days == 7 && isSwitching,
                      onTap: () => onSelectDays(7),
                      colors: colors,
                    ),
                    _TimeframeChip(
                      label: '15D',
                      days: 15,
                      isSelected: days == 15,
                      isLoading: days == 15 && isSwitching,
                      onTap: () => onSelectDays(15),
                      colors: colors,
                    ),
                    _TimeframeChip(
                      label: '30D',
                      days: 30,
                      isSelected: days == 30,
                      isLoading: days == 30 && isSwitching,
                      onTap: () => onSelectDays(30),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Responsive, Overflow-Safe Scrubber Banner
          if (hasData) ...[
            const SizedBox(height: 12),
            _buildResponsiveScrubberBanner(colors),
          ],

          const SizedBox(height: 16),

          // Chart Canvas
          SizedBox(
            height: 160,
            child: isLoading
                ? AppShimmer(
                    child: ShimmerBox(height: 160, borderRadius: 16),
                  )
                : !hasData
                    ? _buildEmptyState(context)
                    : _MinimalistSplineChart(
                        scores: scores,
                        averageScore: averageScore,
                        selectedIndex: selectedIndex,
                        onSelectIndex: onSelectPoint,
                        colors: colors,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveScrubberBanner(AppColorScheme colors) {
    if (selectedIndex != null && selectedIndex! < scores.length) {
      final score = scores[selectedIndex!];
      final delta = score - averageScore;
      final deltaStr = delta >= 0 ? '+$delta%' : '$delta%';
      final isTop = score >= 75;
      final status = score >= 75
          ? 'Strong'
          : (score >= 50 ? 'Good' : 'Developing');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isTop ? colors.mint : colors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Session #${selectedIndex! + 1}: ',
              style: AppTypography.bold(12, color: colors.foreground),
            ),
            Expanded(
              child: Text(
                status,
                style: AppTypography.medium(12, color: colors.mutedForeground),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score%',
              style: AppTypography.bold(
                12.5,
                color: isTop ? colors.mint : colors.primary,
              ),
            ),
            if (averageScore > 0) ...[
              const SizedBox(width: 6),
              Text(
                deltaStr,
                style: AppTypography.bold(
                  10.5,
                  color: delta >= 0 ? colors.mint : colors.destructive,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default hint
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.info, size: 12, color: colors.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tap or slide along the trend line to inspect individual session scores.',
              style: AppTypography.regular(10.5, color: colors.mutedForeground),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FeatherIcons.activity, size: 24, color: colors.mutedForeground),
          const SizedBox(height: 8),
          Text(
            'No sessions completed in the last $days days',
            style: AppTypography.semiBold(12, color: colors.foreground),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickInterviewSetupPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Start Practice Interview',
                style: AppTypography.bold(11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  final String label;
  final int days;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  final AppColorScheme colors;

  const _TimeframeChip({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 9,
                height: 9,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.foreground : colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 3. Ultra-Clean Minimalist Spline Chart
// ─────────────────────────────────────────────────────────────────────────────

class _MinimalistSplineChart extends StatelessWidget {
  final List<int> scores;
  final int averageScore;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectIndex;
  final AppColorScheme colors;

  const _MinimalistSplineChart({
    required this.scores,
    required this.averageScore,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        void handleTouch(Offset localPosition) {
          if (scores.isEmpty) return;
          const leftPad = 8.0;
          final usableW = w - 38;
          final step = scores.length > 1 ? usableW / (scores.length - 1) : usableW;
          final touchX = (localPosition.dx - leftPad).clamp(0.0, usableW);
          final nearestIndex = (touchX / (scores.length > 1 ? step : 1.0))
              .round()
              .clamp(0, scores.length - 1);
          onSelectIndex(nearestIndex);
        }

        return GestureDetector(
          onTapDown: (details) => handleTouch(details.localPosition),
          onPanUpdate: (details) => handleTouch(details.localPosition),
          child: CustomPaint(
            size: Size(w, h),
            painter: _ProfessionalSplinePainter(
              scores: scores,
              averageScore: averageScore,
              selectedIndex: selectedIndex,
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}

class _ProfessionalSplinePainter extends CustomPainter {
  final List<int> scores;
  final int averageScore;
  final int? selectedIndex;
  final AppColorScheme colors;

  _ProfessionalSplinePainter({
    required this.scores,
    required this.averageScore,
    required this.selectedIndex,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightAxisWidth = 28.0;
    const topPadding = 12.0;
    const bottomPadding = 20.0;
    const leftPadding = 8.0;

    final chartW = size.width - rightAxisWidth - leftPadding;
    final chartH = size.height - topPadding - bottomPadding;

    if (scores.isEmpty) return;

    final axisTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // ── 1. Subtle Horizontal Grid (100%, 50%, 0%) ──────────────────
    final gridPaint = Paint()
      ..color = colors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    for (final level in [100, 50]) {
      final y = topPadding + chartH * (1.0 - level / 100.0);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartW, y),
        gridPaint,
      );

      axisTextPainter.text = TextSpan(
        text: '$level%',
        style: TextStyle(
          color: colors.mutedForeground.withValues(alpha: 0.6),
          fontSize: 8.0,
          fontWeight: FontWeight.w500,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(leftPadding + chartW + 5, y - axisTextPainter.height / 2),
      );
    }

    final baseY = topPadding + chartH;
    final baseLinePaint = Paint()
      ..color = colors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftPadding, baseY),
      Offset(leftPadding + chartW, baseY),
      baseLinePaint,
    );

    // ── 2. Benchmark Average Line (Delicate Dashed) ───────────────
    if (averageScore > 0) {
      final avgY = topPadding + chartH * (1.0 - (averageScore / 100.0).clamp(0.0, 1.0));
      final avgDashedPaint = Paint()
        ..color = colors.mint.withValues(alpha: 0.55)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      const dashWidth = 4.0;
      const dashSpace = 3.5;
      double startX = leftPadding;
      while (startX < leftPadding + chartW) {
        canvas.drawLine(
          Offset(startX, avgY),
          Offset(math.min(startX + dashWidth, leftPadding + chartW), avgY),
          avgDashedPaint,
        );
        startX += dashWidth + dashSpace;
      }

      axisTextPainter.text = TextSpan(
        text: 'Avg',
        style: TextStyle(
          color: colors.mint,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(leftPadding + chartW + 5, avgY - axisTextPainter.height / 2),
      );
    }

    // ── 3. Calculate Coordinate Points ────────────────────────────
    final points = <Offset>[];
    final count = scores.length;
    final stepX = count > 1 ? chartW / (count - 1) : chartW / 2;

    for (int i = 0; i < count; i++) {
      final x = count > 1 ? leftPadding + i * stepX : leftPadding + chartW / 2;
      final clampedScore = scores[i].clamp(0, 100);
      final y = topPadding + chartH * (1.0 - (clampedScore / 100.0));
      points.add(Offset(x, y));
    }

    // ── 4. Build Smooth Spline Path ───────────────────────────────
    final splinePath = Path();
    if (points.length == 1) {
      splinePath.moveTo(leftPadding, points[0].dy);
      splinePath.lineTo(leftPadding + chartW, points[0].dy);
    } else {
      splinePath.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 5.5;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 5.5;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 5.5;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 5.5;

        splinePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    }

    // ── 5. Soft Vertical Gradient Fill Under the Curve ────────────
    final fillPath = Path.from(splinePath);
    if (points.length > 1) {
      fillPath.lineTo(points.last.dx, baseY);
      fillPath.lineTo(points.first.dx, baseY);
    } else {
      fillPath.lineTo(leftPadding + chartW, baseY);
      fillPath.lineTo(leftPadding, baseY);
    }
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.primary.withValues(alpha: 0.22),
        colors.primary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(leftPadding, topPadding, chartW, chartH),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // ── 6. Radiant Sleek Stroke Line ──────────────────────────────
    final lineShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        colors.primary,
        colors.tint,
        colors.mint,
      ],
    ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartW, chartH));

    final strokePaint = Paint()
      ..shader = lineShader
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(splinePath, strokePaint);

    // ── 7. Scrubber Vertical Guide ────────────────────────────────
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];
      final scrubberPaint = Paint()
        ..color = colors.primary.withValues(alpha: 0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      const dashW = 3.5;
      const dashS = 3.0;
      double sy = topPadding;
      while (sy < baseY) {
        canvas.drawLine(
          Offset(selectedPoint.dx, sy),
          Offset(selectedPoint.dx, math.min(sy + dashW, baseY)),
          scrubberPaint,
        );
        sy += dashW + dashS;
      }
    }

    // ── 8. Minimalist Data Points ─────────────────────────────────
    final maxScore = scores.reduce(math.max);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = selectedIndex == i;
      final isMax = scores[i] == maxScore && maxScore > 0;

      if (isSelected) {
        // Active point halo
        canvas.drawCircle(
          pt,
          9,
          Paint()..color = colors.primary.withValues(alpha: 0.22),
        );
        // Active point ring
        canvas.drawCircle(
          pt,
          4.5,
          Paint()..color = colors.primary,
        );
        // Active point white core
        canvas.drawCircle(
          pt,
          2.5,
          Paint()..color = Colors.white,
        );
      } else if (isMax) {
        // Peak point subtle mint dot
        canvas.drawCircle(
          pt,
          3.5,
          Paint()..color = colors.mint,
        );
      } else {
        // Minimalist neat point
        canvas.drawCircle(
          pt,
          2.2,
          Paint()..color = colors.primary.withValues(alpha: 0.75),
        );
      }

      // X-Axis clean spacing
      final showLabel = count <= 8 ||
          i == 0 ||
          i == count - 1 ||
          (count <= 14 && (i == 4 || i == 8 || i == 11));

      if (showLabel) {
        axisTextPainter.text = TextSpan(
          text: '#${i + 1}',
          style: TextStyle(
            color: isSelected ? colors.primary : colors.mutedForeground,
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        );
        axisTextPainter.layout();
        axisTextPainter.paint(
          canvas,
          Offset(pt.dx - axisTextPainter.width / 2, baseY + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProfessionalSplinePainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.averageScore != averageScore ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colors != colors;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── 4. Skill Competencies Section
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
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
              Text(
                'Top 5 Evaluated',
                style: AppTypography.medium(11, color: colors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Average proficiency scores across practiced skills',
            style: AppTypography.regular(11, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          ...entries.take(5).map((e) {
            final skill = e.key;
            final score = e.value.clamp(0, 100);
            final isMastered = score >= 75;
            final isProficient = score >= 50 && score < 75;

            final statusLabel = isMastered
                ? 'Advanced'
                : (isProficient ? 'Proficient' : 'Developing');

            final statusColor = isMastered
                ? colors.mint
                : (isProficient ? colors.primary : colors.coral);

            final gradientColors = isMastered
                ? [colors.primary, colors.mint]
                : (isProficient
                    ? [colors.primary, colors.tint]
                    : [colors.coral.withValues(alpha: 0.7), colors.coral]);

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTypography.bold(9.5, color: statusColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$score%',
                            style: AppTypography.bold(12, color: colors.foreground),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 7,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (score / 100.0).clamp(0.03, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: gradientColors,
                            ),
                          ),
                        ),
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
// ── 5. AI Trajectory Insight Card
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
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.mint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.zap, size: 16, color: colors.mint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coaching Summary',
                  style: AppTypography.bold(13, color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: AppTypography.regular(11.5, color: colors.mutedForeground, height: 1.4),
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
