import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/ai_interview_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/interview_controller.dart';
import 'question_review_page.dart';
import 'quick_interview_setup_page.dart';

class InterviewResultPage extends StatefulWidget {
  const InterviewResultPage({super.key});

  @override
  State<InterviewResultPage> createState() => _InterviewResultPageState();
}

class _InterviewResultPageState extends State<InterviewResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentAnim;

  int _selectedTab = 0; // 0: Overview, 1: Q&A Breakdown, 2: Roadmap
  bool _hasStartedAnimation = false;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentAnim =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ic = context.read<InterviewController>();
      if (ic.lastEvaluation == null &&
          ic.sessionId != null &&
          ic.sessionStatus != SessionStatus.evaluating) {
        ic.fetchFinalEvaluation();
      }
    });
  }

  void _triggerScoreAnimation() {
    if (!_hasStartedAnimation && mounted) {
      _hasStartedAnimation = true;
      _ringCtrl.forward().then((_) {
        if (mounted) _contentCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _copySummaryToClipboard(
    String summary,
    int score,
    String band,
    String role,
  ) {
    final text = 'Interview Coach Assessment Report\n'
        'Role: $role\n'
        'Score: $score/100 ($band)\n\n'
        'Summary:\n$summary';

    Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: 'Assessment report copied to clipboard!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final ic = context.watch<InterviewController>();
    final eval = ic.lastEvaluation;
    final config = ic.config;

    void navigateHome() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
        (_) => false,
      );
    }

    // ── 1. Loading / Evaluating State -> Show Shimmer Skeleton ────────────────
    if (eval == null) {
      if (ic.sessionStatus == SessionStatus.error) {
        return _ResultErrorView(
          colors: colors,
          errorMessage: ic.errorMessage,
          onRetry: () => ic.fetchFinalEvaluation(),
          onClose: navigateHome,
        );
      }

      return _ResultShimmerLoadingView(
        colors: colors,
        role: config.role.isNotEmpty ? config.role : 'Interview Candidate',
        questionCount: ic.totalQuestions,
        onClose: navigateHome,
      );
    }

    // ── 2. Real Evaluation Ready -> Smoothly Animate Real Score ───────────────
    _triggerScoreAnimation();

    final score = eval.overallScore;
    final band = eval.hiringBand.isNotEmpty ? eval.hiringBand : 'Hire';
    final label = eval.performanceLabel.isNotEmpty ? eval.performanceLabel : 'Strong Candidate';
    final summary = eval.summary;
    final strengths = eval.strengths;
    final improvements = eval.areasToImprove;
    final recommendations = eval.recommendedTopics;
    final questionReviews = eval.questionReviews;

    final benchmark = eval.benchmark;

    // Score-based dynamic colors
    final scoreColor = score >= 85
        ? colors.mint
        : score >= 70
            ? colors.primary
            : score >= 55
                ? colors.yellow
                : colors.coral;

    final bandColor = band.contains('Strong Hire')
        ? colors.success
        : band.contains('Hire')
            ? colors.primary
            : band.contains('Leaning')
                ? colors.yellow
                : colors.coral;

    final bandIcon = band.contains('Strong Hire')
        ? FeatherIcons.award
        : band.contains('Hire')
            ? FeatherIcons.thumbsUp
            : band.contains('Leaning')
                ? FeatherIcons.trendingUp
                : FeatherIcons.refreshCw;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Hero Section (Airy, Compact & Clean) ───────────────────────────
          _ExecutiveHeroSection(
            score: score,
            band: band,
            bandColor: bandColor,
            bandIcon: bandIcon,
            label: label,
            role: config.role.isNotEmpty ? config.role : 'Candidate',
            company: config.company,
            scoreColor: scoreColor,
            ringAnim: _ringAnim,
            totalQuestions: questionReviews.isNotEmpty
                ? questionReviews.length
                : (ic.sessionHistory.isNotEmpty
                    ? ic.sessionHistory.length
                    : config.questions),
            benchmark: benchmark,
            isDark: isDark,
            colors: colors,
            onClose: navigateHome,
            onShare: () => _copySummaryToClipboard(
              summary,
              score,
              band,
              config.role.isNotEmpty ? config.role : 'Candidate',
            ),
          ),

          // ── Segmented Tab Selector ─────────────────────────────────────────
          _SegmentedTabBar(
            selectedIndex: _selectedTab,
            onTabSelected: (index) => setState(() => _selectedTab = index),
            colors: colors,
            questionCount: questionReviews.length,
          ),

          // ── Scrollable Tab Content ─────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _contentAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTab == 0) ...[
                      // ── Tab 0: Overview & Key Takeaways ────────────────────
                      if (summary.isNotEmpty) ...[
                        _SummaryBriefingCard(
                          summary: summary,
                          colors: colors,
                        ),
                        const SizedBox(height: 14),
                      ],

                      _KeyTakeawaysCard(
                        strengths: strengths,
                        improvements: improvements,
                        colors: colors,
                      ),
                    ] else if (_selectedTab == 1) ...[
                      // ── Tab 1: Q&A Analysis ────────────────────────────────
                      _QuestionAnalysisTab(
                        reviews: questionReviews,
                        colors: colors,
                        onOpenDeepDive: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuestionReviewPage(),
                          ),
                        ),
                      ),
                    ] else ...[
                      // ── Tab 2: Learning Roadmap ────────────────────────────
                      _RoadmapTab(
                        recommendations: recommendations,
                        role: config.role.isNotEmpty
                            ? config.role
                            : 'Candidate',
                        colors: colors,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Fixed Action Bar ────────────────────────────────────────
          _BottomActionBar(
            colors: colors,
            onReviewAnswers: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuestionReviewPage()),
            ),
            onNewSession: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const QuickInterviewSetupPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER LOADING SKELETON (SHOWN WHILE EVALUATING)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultShimmerLoadingView extends StatelessWidget {
  final AppColorScheme colors;
  final String role;
  final int questionCount;
  final VoidCallback onClose;

  const _ResultShimmerLoadingView({
    required this.colors,
    required this.role,
    required this.questionCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF091122),
              const Color(0xFF0E1A34),
              const Color(0xFF132347),
            ]
          : [
              const Color(0xFF122244),
              const Color(0xFF172C58),
              const Color(0xFF1E3668),
            ],
    );

    final heroShimmerBase = Colors.white.withValues(alpha: 0.08);
    final heroShimmerHighlight = Colors.white.withValues(alpha: 0.24);

    final bodyShimmerBase = isDark ? const Color(0xFF1F2C46) : const Color(0xFFE8EDF5);
    final bodyShimmerHighlight = isDark ? const Color(0xFF2C3E61) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Hero Section (Solid Stable Gradient) ──────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: bgGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              FeatherIcons.x,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        AppShimmer(
                          baseColor: heroShimmerBase,
                          highlightColor: heroShimmerHighlight,
                          child: Container(
                            width: 100,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            FeatherIcons.share2,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Score Dial + Verdict Meta
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated Evaluating Radial Gauge
                        _ScoreRingEvaluatingGauge(accentColor: colors.mint),

                        const SizedBox(width: 18),

                        // Role & Shimmering Band Meta (Zero text)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppShimmer(
                                baseColor: heroShimmerBase,
                                highlightColor: heroShimmerHighlight,
                                child: Container(
                                  width: 140,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Hiring Band Shimmer Placeholder
                              AppShimmer(
                                baseColor: heroShimmerBase,
                                highlightColor: heroShimmerHighlight,
                                child: Container(
                                  width: 100,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Performance Label Shimmer Placeholder
                              AppShimmer(
                                baseColor: heroShimmerBase,
                                highlightColor: heroShimmerHighlight,
                                child: Container(
                                  width: 135,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Quick Stats Strip (Shimmer Skeleton, Zero text)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: AppShimmer(
                        baseColor: heroShimmerBase,
                        highlightColor: heroShimmerHighlight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              width: 85,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Container(
                              width: 65,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Segmented Tab Bar Skeleton (Zero text) ─────────────────────
          AppShimmer(
            baseColor: bodyShimmerBase,
            highlightColor: bodyShimmerHighlight,
            child: Container(
              margin: const EdgeInsets.fromLTRB(18, 12, 18, 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: ShimmerBox(width: double.infinity, height: 32, borderRadius: 10),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ShimmerBox(width: double.infinity, height: 32, borderRadius: 10),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ShimmerBox(width: double.infinity, height: 32, borderRadius: 10),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable Body Cards (Real Surfaces + Shimmer Content, Zero text) ────
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Executive Summary Card Shell (Zero text)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Row(
                            children: const [
                              ShimmerBox(width: 26, height: 26, borderRadius: 8),
                              SizedBox(width: 10),
                              ShimmerBox(width: 135, height: 16, borderRadius: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerBox(width: double.infinity, height: 13, borderRadius: 5),
                              SizedBox(height: 8),
                              ShimmerBox(width: double.infinity, height: 13, borderRadius: 5),
                              SizedBox(height: 8),
                              ShimmerBox(width: 240, height: 13, borderRadius: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 2: Key Takeaways Card Shell (Zero text)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Row(
                            children: const [
                              ShimmerBox(width: 26, height: 26, borderRadius: 8),
                              SizedBox(width: 10),
                              ShimmerBox(width: 115, height: 16, borderRadius: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerBox(width: double.infinity, height: 13, borderRadius: 5),
                              SizedBox(height: 8),
                              ShimmerBox(width: 270, height: 13, borderRadius: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Row(
                            children: const [
                              ShimmerBox(width: 26, height: 26, borderRadius: 8),
                              SizedBox(width: 10),
                              ShimmerBox(width: 125, height: 16, borderRadius: 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppShimmer(
                          baseColor: bodyShimmerBase,
                          highlightColor: bodyShimmerHighlight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ShimmerBox(width: double.infinity, height: 13, borderRadius: 5),
                              SizedBox(height: 8),
                              ShimmerBox(width: 240, height: 13, borderRadius: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Live AI Evaluation Status Skeleton (Zero text) ───────
          AppShimmer(
            baseColor: bodyShimmerBase,
            highlightColor: bodyShimmerHighlight,
            child: Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: const [
                  ShimmerBox(width: 18, height: 18, borderRadius: 9),
                  SizedBox(width: 12),
                  Expanded(
                    child: ShimmerBox(width: double.infinity, height: 14, borderRadius: 5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVALUATING RADIAL GAUGE & LIVE BANNER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreRingEvaluatingGauge extends StatefulWidget {
  final Color accentColor;
  const _ScoreRingEvaluatingGauge({required this.accentColor});

  @override
  State<_ScoreRingEvaluatingGauge> createState() =>
      _ScoreRingEvaluatingGaugeState();
}

class _ScoreRingEvaluatingGaugeState extends State<_ScoreRingEvaluatingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: 104,
          height: 104,
          child: CustomPaint(
            painter: _EvaluatingRingPainter(
              rotation: _ctrl.value * 2 * math.pi,
              accentColor: widget.accentColor,
            ),
            child: Center(
              child: AppShimmer(
                baseColor: Colors.white.withValues(alpha: 0.12),
                highlightColor: Colors.white.withValues(alpha: 0.32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ShimmerBox(width: 38, height: 22, borderRadius: 5),
                    SizedBox(height: 5),
                    ShimmerBox(width: 48, height: 9, borderRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EvaluatingRingPainter extends CustomPainter {
  final double rotation;
  final Color accentColor;

  const _EvaluatingRingPainter({
    required this.rotation,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = cx - 6;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Active rotating arc
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor.withValues(alpha: 0.0),
          accentColor.withValues(alpha: 0.45),
          accentColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      rotation,
      math.pi * 1.25,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_EvaluatingRingPainter old) =>
      old.rotation != rotation || old.accentColor != accentColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW (WHEN EVALUATION FAILS)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultErrorView extends StatelessWidget {
  final AppColorScheme colors;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ResultErrorView({
    required this.colors,
    this.errorMessage,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.foreground),
          onPressed: onClose,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.coral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(FeatherIcons.alertCircle, size: 26, color: colors.coral),
              ),
              const SizedBox(height: 16),
              Text(
                'Evaluation Not Ready',
                style: AppTypography.bold(17, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'We could not generate the scorecard right now. Please try again.',
                textAlign: TextAlign.center,
                style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.4),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Retry Evaluation',
                icon: FeatherIcons.refreshCw,
                onPress: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXECUTIVE HERO SECTION (SPACIOUS & ELEGANT)
// ─────────────────────────────────────────────────────────────────────────────

class _ExecutiveHeroSection extends StatelessWidget {
  final int score;
  final String band;
  final Color bandColor;
  final IconData bandIcon;
  final String label;
  final String role;
  final String company;
  final Color scoreColor;
  final Animation<double> ringAnim;
  final int totalQuestions;
  final RoleBenchmark benchmark;
  final bool isDark;
  final AppColorScheme colors;
  final VoidCallback onClose;
  final VoidCallback onShare;

  const _ExecutiveHeroSection({
    required this.score,
    required this.band,
    required this.bandColor,
    required this.bandIcon,
    required this.label,
    required this.role,
    required this.company,
    required this.scoreColor,
    required this.ringAnim,
    required this.totalQuestions,
    required this.benchmark,
    required this.isDark,
    required this.colors,
    required this.onClose,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF091122),
              const Color(0xFF0E1A34),
              const Color(0xFF132347),
            ]
          : [
              const Color(0xFF122244),
              const Color(0xFF172C58),
              const Color(0xFF1E3668),
            ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.x,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'EVALUATION SCORECARD',
                    style: AppTypography.bold(
                      12,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.0,
                    ),
                  ),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.share2,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Score Dial + Verdict Meta
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Radial Gauge (Compact 104px)
                  AnimatedBuilder(
                    animation: ringAnim,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: scoreColor.withValues(
                                    alpha: 0.28 * ringAnim.value,
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          _ScoreRingGauge(
                            score: score,
                            progress: ringAnim.value,
                            ringColor: scoreColor,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 18),

                  // Role & Band Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role Title
                        Text(
                          role,
                          style: AppTypography.bold(
                            16,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (company.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            company,
                            style: AppTypography.regular(
                              12,
                              color: const Color(0xFFB1C4E8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),

                        // Hiring Band Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bandColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: bandColor.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(bandIcon, size: 12, color: bandColor),
                              const SizedBox(width: 5),
                              Text(
                                band.toUpperCase(),
                                style: AppTypography.bold(
                                  10.5,
                                  color: bandColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Performance Subtitle
                        Text(
                          label,
                          style: AppTypography.medium(
                            12,
                            color: const Color(0xFFC0D2F4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Quick Stats Strip (Spacious & Minimal)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _HeroMetric(
                      icon: FeatherIcons.helpCircle,
                      value: '$totalQuestions Qs',
                      label: 'Completed',
                    ),
                    _HeroDivider(),
                    _HeroMetric(
                      icon: FeatherIcons.cpu,
                      value: 'Adaptive',
                      label: 'AI Difficulty',
                    ),
                    _HeroDivider(),
                    _HeroMetric(
                      icon: FeatherIcons.award,
                      value: 'Top ${100 - benchmark.percentile}%',
                      label: 'Percentile',
                      valueColor: colors.mint,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 11, color: const Color(0xFF9BB2DD)),
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTypography.bold(
                  12,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.regular(
              10,
              color: const Color(0xFF869DC8),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE RING GAUGE (104x104)
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreRingGauge extends StatelessWidget {
  final int score;
  final double progress;
  final Color ringColor;

  const _ScoreRingGauge({
    required this.score,
    required this.progress,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayScore = (score * progress).round();

    return SizedBox(
      width: 104,
      height: 104,
      child: CustomPaint(
        painter: _ScorePainter(
          value: (score / 100) * progress,
          ringColor: ringColor,
          trackColor: Colors.white.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$displayScore',
                style: AppTypography.bold(
                  30,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
              Text(
                'OUT OF 100',
                style: AppTypography.bold(
                  8.5,
                  color: const Color(0xFF8FA5D1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  final double value;
  final Color ringColor;
  final Color trackColor;

  const _ScorePainter({
    required this.value,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 12) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 7.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress Arc
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = ringColor
          ..strokeWidth = 7.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) =>
      old.value != value || old.ringColor != ringColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEGMENTED TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final AppColorScheme colors;
  final int questionCount;

  const _SegmentedTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.colors,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Overview',
            icon: FeatherIcons.fileText,
            isSelected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
            colors: colors,
          ),
          _TabItem(
            label: 'Q&A ($questionCount)',
            icon: FeatherIcons.helpCircle,
            isSelected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
            colors: colors,
          ),
          _TabItem(
            label: 'Roadmap',
            icon: FeatherIcons.compass,
            isSelected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme colors;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? colors.primaryForeground
                    : colors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.semiBold(
                  12,
                  color: isSelected
                      ? colors.primaryForeground
                      : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0: EXECUTIVE SUMMARY & KEY TAKEAWAYS (CLEAN & SPACIOUS)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBriefingCard extends StatelessWidget {
  final String summary;
  final AppColorScheme colors;

  const _SummaryBriefingCard({
    required this.summary,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FeatherIcons.fileText,
                  size: 14,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Executive Summary',
                style: AppTypography.bold(
                  14,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTypography.regular(
              13,
              color: colors.foreground,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTakeawaysCard extends StatelessWidget {
  final List<String> strengths;
  final List<String> improvements;
  final AppColorScheme colors;

  const _KeyTakeawaysCard({
    required this.strengths,
    required this.improvements,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (strengths.isEmpty && improvements.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Strengths ──────────────────────────────────────────────────────
          if (strengths.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(FeatherIcons.checkCircle, size: 14, color: colors.success),
                ),
                const SizedBox(width: 10),
                Text(
                  'Key Strengths',
                  style: AppTypography.bold(14, color: colors.foreground),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...strengths.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.regular(12.5, color: colors.foreground, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (strengths.isNotEmpty && improvements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: colors.border.withValues(alpha: 0.5)),
            ),
          ],

          // ── Areas for Growth ───────────────────────────────────────────────
          if (improvements.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.coral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(FeatherIcons.target, size: 14, color: colors.coral),
                ),
                const SizedBox(width: 10),
                Text(
                  'Areas to Improve',
                  style: AppTypography.bold(14, color: colors.foreground),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...improvements.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.regular(12.5, color: colors.foreground, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: QUESTION ANALYSIS COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionAnalysisTab extends StatelessWidget {
  final List<QuestionReview> reviews;
  final AppColorScheme colors;
  final VoidCallback onOpenDeepDive;

  const _QuestionAnalysisTab({
    required this.reviews,
    required this.colors,
    required this.onOpenDeepDive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turn-by-Turn Breakdown',
                    style: AppTypography.bold(14, color: colors.foreground),
                  ),
                  Text(
                    'Review individual question scoring and feedback',
                    style: AppTypography.regular(
                      11,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onOpenDeepDive,
              icon: Icon(FeatherIcons.externalLink,
                  size: 13, color: colors.primary),
              label: Text(
                'Full Review',
                style: AppTypography.semiBold(12, color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'No question reviews available.',
              style: AppTypography.regular(12, color: colors.mutedForeground),
            ),
          )
        else
          ...reviews.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            return _QuestionReviewCard(
              index: idx + 1,
              review: r,
              colors: colors,
            );
          }),
      ],
    );
  }
}

class _QuestionReviewCard extends StatefulWidget {
  final int index;
  final QuestionReview review;
  final AppColorScheme colors;

  const _QuestionReviewCard({
    required this.index,
    required this.review,
    required this.colors,
  });

  @override
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final score = widget.review.score;
    final scoreColor = score >= 85
        ? widget.colors.mint
        : score >= 70
            ? widget.colors.primary
            : score >= 55
                ? widget.colors.yellow
                : widget.colors.coral;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.colors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Turn # & Score Badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: widget.colors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Turn ${widget.index}',
                      style: AppTypography.bold(
                        10,
                        color: widget.colors.secondaryForeground,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$score / 100',
                      style: AppTypography.bold(
                        10.5,
                        color: scoreColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    _expanded
                        ? FeatherIcons.chevronUp
                        : FeatherIcons.chevronDown,
                    size: 13,
                    color: widget.colors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 7),

              // Question Text
              Text(
                widget.review.question,
                style: AppTypography.semiBold(
                  12.5,
                  color: widget.colors.foreground,
                  height: 1.35,
                ),
              ),

              if (_expanded) ...[
                const SizedBox(height: 10),

                // Candidate Answer
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.colors.muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FeatherIcons.user,
                            size: 11,
                            color: widget.colors.mutedForeground,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Your Answer:',
                            style: AppTypography.semiBold(
                              11,
                              color: widget.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.review.answer.isNotEmpty
                            ? widget.review.answer
                            : 'No response recorded.',
                        style: AppTypography.regular(
                          12,
                          color: widget.colors.foreground,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                // Feedback
                if (widget.review.feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.colors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FeatherIcons.messageCircle,
                              size: 11,
                              color: widget.colors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AI Feedback:',
                              style: AppTypography.bold(
                                11,
                                color: widget.colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.review.feedback,
                          style: AppTypography.regular(
                            12,
                            color: widget.colors.foreground,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: ROADMAP COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _RoadmapTab extends StatelessWidget {
  final List<String> recommendations;
  final String role;
  final AppColorScheme colors;

  const _RoadmapTab({
    required this.recommendations,
    required this.role,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Targeted Learning Roadmap',
          style: AppTypography.bold(14, color: colors.foreground),
        ),
        Text(
          'Curated study topics based on your answers',
          style: AppTypography.regular(
            11,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),

        if (recommendations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'No study recommendations at this time.',
              style: AppTypography.regular(12, color: colors.mutedForeground),
            ),
          )
        else
          ...recommendations.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final topic = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '0$idx',
                        style: AppTypography.bold(
                          11,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic,
                      style: AppTypography.semiBold(
                        12.5,
                        color: colors.foreground,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM FIXED ACTION BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onReviewAnswers;
  final VoidCallback onNewSession;

  const _BottomActionBar({
    required this.colors,
    required this.onReviewAnswers,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Review Answers',
                icon: FeatherIcons.list,
                variant: ButtonVariant.secondary,
                onPress: onReviewAnswers,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'New Session',
                icon: FeatherIcons.refreshCw,
                variant: ButtonVariant.primary,
                onPress: onNewSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
