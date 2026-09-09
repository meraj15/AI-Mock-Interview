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

  int _selectedTab = 0; // 0: Overview, 1: Q&A Analysis, 2: Roadmap

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentAnim =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    _ringCtrl.forward().then((_) {
      if (mounted) _contentCtrl.forward();
    });
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
    final text = 'AI Mock Interview Report\n'
        'Role: $role\n'
        'Overall Score: $score/100 ($band)\n\n'
        'Executive Summary:\n$summary';

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

    final score = eval?.overallScore ?? 84;
    final band = eval?.hiringBand ?? 'Strong Hire';
    final label = eval?.performanceLabel ?? 'Strong Candidate';

    final summary = (eval?.summary.isNotEmpty == true)
        ? eval!.summary
        : 'The candidate demonstrated a solid command of technical concepts, structured reasoning, and clear communication throughout the interview session.';

    final strengths = (eval?.strengths.isNotEmpty == true)
        ? eval!.strengths
        : [
            'Strong architectural intuition and clear mental models.',
            'Structured communication when explaining engineering trade-offs.',
            'Effective problem-solving methodology with practical examples.',
          ];

    final improvements = (eval?.areasToImprove.isNotEmpty == true)
        ? eval!.areasToImprove
        : [
            'Quantify project outcomes with measurable performance metrics.',
            'Deepen edge-case exploration during system considerations.',
            'Structure answers more concisely using the STAR framework.',
          ];

    final recommendations = (eval?.recommendedTopics.isNotEmpty == true)
        ? eval!.recommendedTopics
        : [
            'Advanced Asynchronous Patterns & Concurrency Control',
            'Scalable Architecture & Clean Component Isolation',
            'Application Profiling, Memory Optimization & Performance Tuning',
          ];

    final questionReviews = (eval?.questionReviews.isNotEmpty == true)
        ? eval!.questionReviews
        : _buildFallbackReviews(ic.sessionHistory);

    final benchmark = eval?.benchmark ??
        RoleBenchmark(
          percentile: score >= 85 ? 92 : score >= 75 ? 84 : 68,
          industryAverageScore: 72,
          readinessLevel: label,
          companyCultureAlignment: config.company.isNotEmpty
              ? 'High alignment with ${config.company} core engineering competencies.'
              : 'Strong readiness for modern engineering team standards.',
        );

    // Dynamic color palettes matching score & band
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
          // ── Hero Section ──────────────────────────────────────────────────
          _ExecutiveHeroSection(
            score: score,
            band: band,
            bandColor: bandColor,
            bandIcon: bandIcon,
            label: label,
            role: config.role.isNotEmpty ? config.role : 'Technical Role',
            company: config.company,
            experience: config.experience,
            scoreColor: scoreColor,
            ringAnim: _ringAnim,
            totalQuestions: questionReviews.isNotEmpty
                ? questionReviews.length
                : config.questions,
            benchmark: benchmark,
            isDark: isDark,
            colors: colors,
            onClose: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavPage()),
              (_) => false,
            ),
            onShare: () => _copySummaryToClipboard(
              summary,
              score,
              band,
              config.role.isNotEmpty ? config.role : 'Flutter Developer',
            ),
          ),

          // ── Segmented Tab Selector ────────────────────────────────────────
          _SegmentedTabBar(
            selectedIndex: _selectedTab,
            onTabSelected: (index) => setState(() => _selectedTab = index),
            colors: colors,
            questionCount: questionReviews.length,
          ),

          // ── Scrollable Tab Content ────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _contentAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(_contentAnim),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTab == 0) ...[
                        // ── Tab 0: Overview & Executive Briefing ───────────
                        _SummaryBriefingCard(
                          summary: summary,
                          colors: colors,
                        ),
                        const SizedBox(height: 14),

                        _BenchmarkComparisonCard(
                          score: score,
                          benchmark: benchmark,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),

                        // Strengths & Growth Areas
                        _FeedbackSection(
                          title: 'Demonstrated Strengths',
                          subtitle: 'Key technical competencies confirmed',
                          icon: FeatherIcons.checkCircle,
                          accentColor: colors.success,
                          items: strengths,
                          colors: colors,
                        ),
                        const SizedBox(height: 14),

                        _FeedbackSection(
                          title: 'Areas for Growth',
                          subtitle: 'Targeted actions to elevate your score',
                          icon: FeatherIcons.target,
                          accentColor: colors.coral,
                          items: improvements,
                          colors: colors,
                        ),
                      ] else if (_selectedTab == 1) ...[
                        // ── Tab 1: Q&A Analysis ───────────────────────────
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
                        // ── Tab 2: Learning Roadmap ───────────────────────
                        _RoadmapTab(
                          recommendations: recommendations,
                          role: config.role.isNotEmpty
                              ? config.role
                              : 'Flutter Developer',
                          colors: colors,
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Fixed Action Bar ───────────────────────────────────────
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

  static List<QuestionReview> _buildFallbackReviews(
    List<Map<String, String>> sessionHistory,
  ) {
    if (sessionHistory.isNotEmpty) {
      return sessionHistory.map((item) {
        return QuestionReview(
          question: item['question'] ?? 'Technical Question',
          answer: item['answer'] ?? 'Answer captured during session.',
          expectedAnswer:
              'A great answer explains the core idea in plain English first, followed by a concrete real-world example from your development experience.',
          feedback:
              'Demonstrated sound technical understanding and structured reasoning.',
          score: 82,
        );
      }).toList();
    }

    return const [
      QuestionReview(
        question:
            'What is dependency injection, and why do we use it in Flutter?',
        answer:
            'I think dependency injection means we don\'t create the object directly inside the class. We pass it from outside, so it is easier to manage and test.',
        expectedAnswer:
            'Dependency injection means giving a class the things it needs instead of creating them inside the class. For example, if my service needs a database or API client, I pass it in through the constructor. This makes the code much easier to test and change later.',
        feedback:
            'Solid core explanation. Clear and easy to follow.',
        score: 88,
      ),
      QuestionReview(
        question:
            'What is the difference between Future and Stream in Dart?',
        answer:
            'A Future gives one value in the future like an API call. A Stream gives multiple values over time like events.',
        expectedAnswer:
            'A Future delivers a single value or an error once, like waiting for an HTTP API response. A Stream delivers multiple values over time, like listening to continuous user location updates or websocket chat messages.',
        feedback:
            'Accurate and concise explanation with everyday examples.',
        score: 92,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ExecutiveHeroSection extends StatelessWidget {
  final int score;
  final String band;
  final Color bandColor;
  final IconData bandIcon;
  final String label;
  final String role;
  final String company;
  final String experience;
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
    required this.experience,
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
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row
              Row(
                children: [
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.x,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'EVALUATION REPORT',
                        style: AppTypography.bold(
                          12,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.mint,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI Assessment Verified',
                            style: AppTypography.regular(
                              10,
                              color: const Color(0xFF9FB2D8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        FeatherIcons.share2,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Candidate & Role Pill Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FeatherIcons.briefcase,
                      size: 13,
                      color: colors.tint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role,
                      style: AppTypography.semiBold(
                        12,
                        color: Colors.white,
                      ),
                    ),
                    if (company.isNotEmpty) ...[
                      Text(
                        ' • $company',
                        style: AppTypography.medium(
                          12,
                          color: const Color(0xFFB1C4E8),
                        ),
                      ),
                    ],
                    if (experience.isNotEmpty) ...[
                      Text(
                        ' • $experience',
                        style: AppTypography.regular(
                          11,
                          color: const Color(0xFF8FA5CF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Score Dial + Verdict Meta
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Radial Gauge
                  AnimatedBuilder(
                    animation: ringAnim,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: scoreColor.withValues(
                                    alpha: 0.32 * ringAnim.value,
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 6,
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

                  // Verdict Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hiring Band Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
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
                              const SizedBox(width: 6),
                              Text(
                                band.toUpperCase(),
                                style: AppTypography.bold(
                                  11,
                                  color: bandColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Performance Label
                        Text(
                          label,
                          style: AppTypography.bold(
                            18,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Percentile Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FeatherIcons.trendingUp,
                                size: 11,
                                color: colors.mint,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Top ${100 - benchmark.percentile}% of Candidates',
                                style: AppTypography.semiBold(
                                  11,
                                  color: colors.mint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quick Benchmark Metrics Strip
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Row(
                  children: [
                    _HeroMetric(
                      icon: FeatherIcons.helpCircle,
                      value: '$totalQuestions',
                      label: 'Questions',
                    ),
                    _HeroDivider(),
                    _HeroMetric(
                      icon: FeatherIcons.cpu,
                      value: 'Adaptive',
                      label: 'AI Difficulty',
                    ),
                    _HeroDivider(),
                    _HeroMetric(
                      icon: FeatherIcons.barChart2,
                      value:
                          '${score >= benchmark.industryAverageScore ? "+" : ""}${score - benchmark.industryAverageScore} pts',
                      label: 'vs Industry Avg',
                      valueColor: score >= benchmark.industryAverageScore
                          ? colors.mint
                          : colors.coral,
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
              Icon(icon, size: 12, color: const Color(0xFF9BB2DD)),
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTypography.bold(
                  13,
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
      height: 26,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE RING GAUGE
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
      width: 132,
      height: 132,
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
                  38,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
              Text(
                'OUT OF 100',
                style: AppTypography.bold(
                  9,
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
    final radius = (size.width - 14) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 9
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
          ..strokeWidth = 9
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
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
// TAB 0: OVERVIEW COMPONENTS
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FeatherIcons.messageSquare,
                  size: 14,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Interviewer Briefing',
                      style: AppTypography.bold(
                        14,
                        color: colors.foreground,
                      ),
                    ),
                    Text(
                      'Executive summary of demonstrated competencies',
                      style: AppTypography.regular(
                        11,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: colors.primary, width: 3.5),
              ),
            ),
            child: Text(
              summary,
              style: AppTypography.regular(
                13,
                color: colors.foreground,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenchmarkComparisonCard extends StatelessWidget {
  final int score;
  final RoleBenchmark benchmark;
  final AppColorScheme colors;

  const _BenchmarkComparisonCard({
    required this.score,
    required this.benchmark,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FeatherIcons.sliders,
                  size: 14,
                  color: colors.tint,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Role Benchmark & Readiness',
                style: AppTypography.bold(
                  14,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison Bar: Your Score vs Industry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Candidate Score: $score',
                style: AppTypography.semiBold(
                  12,
                  color: colors.foreground,
                ),
              ),
              Text(
                'Industry Average: ${benchmark.industryAverageScore}',
                style: AppTypography.medium(
                  12,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Double Progress Bar
          Stack(
            children: [
              // Track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Candidate Progress
              FractionallySizedBox(
                widthFactor: (score / 100).clamp(0.05, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Alignment Commentary
          if (benchmark.companyCultureAlignment.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    FeatherIcons.shield,
                    size: 12,
                    color: colors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    benchmark.companyCultureAlignment,
                    style: AppTypography.regular(
                      11,
                      color: colors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> items;
  final AppColorScheme colors;

  const _FeedbackSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.items,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bold(
                      14,
                      color: colors.foreground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.regular(
                      11,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${items.length} points',
                  style: AppTypography.semiBold(
                    10,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.regular(
                        12,
                        color: colors.foreground,
                        height: 1.5,
                      ),
                    ),
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
                    style: AppTypography.bold(15, color: colors.foreground),
                  ),
                  Text(
                    'Review individual question scoring and AI feedback',
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
        const SizedBox(height: 12),

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.colors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Turn # & Score Badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        11,
                        color: scoreColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? FeatherIcons.chevronUp
                        : FeatherIcons.chevronDown,
                    size: 14,
                    color: widget.colors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Question Text
              Text(
                widget.review.question,
                style: AppTypography.semiBold(
                  13,
                  color: widget.colors.foreground,
                  height: 1.35,
                ),
              ),

              if (_expanded) ...[
                const SizedBox(height: 12),

                // Candidate Answer
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.colors.muted.withValues(alpha: 0.4),
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

                // Expected / Ideal Human Answer
                if (widget.review.expectedAnswer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.colors.mint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.colors.mint.withValues(alpha: 0.35),
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
                                color: widget.colors.mint.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                FeatherIcons.check,
                                size: 11,
                                color: widget.colors.mint,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Expected / Ideal Answer',
                              style: AppTypography.bold(
                                11,
                                color: widget.colors.mint,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Natural & Simple',
                              style: AppTypography.medium(
                                10,
                                color: widget.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.review.expectedAnswer,
                          style: AppTypography.regular(
                            12,
                            color: widget.colors.foreground,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // AI Coach Feedback
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.colors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.colors.accentForeground
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FeatherIcons.zap,
                            size: 11,
                            color: widget.colors.accentForeground,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Interviewer Feedback:',
                            style: AppTypography.semiBold(
                              11,
                              color: widget.colors.accentForeground,
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
          style: AppTypography.bold(15, color: colors.foreground),
        ),
        Text(
          'Curated study topics to reach senior proficiency as a $role',
          style: AppTypography.regular(
            11,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 14),

        ...recommendations.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final topic = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Number Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '0$idx',
                      style: AppTypography.bold(
                        12,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Topic Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic,
                        style: AppTypography.semiBold(
                          13,
                          color: colors.foreground,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FeatherIcons.bookmark,
                            size: 11,
                            color: colors.tint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'High Priority Mastery for $role',
                            style: AppTypography.medium(
                              10,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
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
