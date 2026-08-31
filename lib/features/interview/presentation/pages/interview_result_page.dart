import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/interview_controller.dart';
import 'quick_interview_setup_page.dart';
import 'question_review_page.dart';

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

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentAnim =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    _ringCtrl.forward().then((_) => _contentCtrl.forward());
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
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
    final strengths = eval?.strengths ??
        [
          'Strong architectural intuition.',
          'Structured communication throughout.',
          'Good use of real-world examples.',
        ];
    final improvements = eval?.areasToImprove ??
        [
          'Quantify results with metrics.',
          'Deepen edge-case coverage.',
          'Practice concise STAR-format answers.',
        ];

    // Score colour
    final scoreColor = score >= 85
        ? colors.mint
        : score >= 70
            ? colors.primary
            : colors.coral;

    // Band colour
    final bandColor = band.contains('Strong Hire')
        ? colors.success
        : band.contains('Hire')
            ? colors.primary
            : band.contains('Leaning')
                ? colors.yellow
                : colors.coral;

    // Band icon
    final bandIcon = band.contains('Strong Hire')
        ? FeatherIcons.star
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
          // ── Hero ─────────────────────────────────────────────────────────
          _HeroSection(
            score: score,
            band: band,
            bandColor: bandColor,
            bandIcon: bandIcon,
            label: label,
            role: config.role,
            company: config.company,
            scoreColor: scoreColor,
            ringAnim: _ringAnim,
            totalQuestions: config.questions,
            difficulty: config.difficulty,
            isDark: isDark,
            colors: colors,
            onClose: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavPage()),
              (_) => false,
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _contentAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(_contentAnim),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Strengths & Improve side by side ────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FeedbackCard(
                              title: 'Strengths',
                              icon: FeatherIcons.checkCircle,
                              accent: colors.success,
                              items: strengths.take(3).toList(),
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeedbackCard(
                              title: 'Improve',
                              icon: FeatherIcons.target,
                              accent: colors.coral,
                              items: improvements.take(3).toList(),
                              colors: colors,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── CTA buttons ─────────────────────────────────
                      AppButton(
                        label: 'Review My Answers',
                        icon: FeatherIcons.list,
                        variant: ButtonVariant.secondary,
                        onPress: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const QuestionReviewPage()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Start New Session',
                        icon: FeatherIcons.refreshCw,
                        onPress: () =>
                            Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const QuickInterviewSetupPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
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
  final String difficulty;
  final bool isDark;
  final AppColorScheme colors;
  final VoidCallback onClose;

  const _HeroSection({
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
    required this.difficulty,
    required this.isDark,
    required this.colors,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A1628),
                  const Color(0xFF0F1E38),
                  const Color(0xFF122240),
                ]
              : [
                  const Color(0xFF17294E),
                  const Color(0xFF1C3060),
                  const Color(0xFF1A3A6E),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
          child: Column(
            children: [
              // Close row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(FeatherIcons.x,
                        size: 18, color: Colors.white60),
                    onPressed: onClose,
                  ),
                  const Spacer(),
                  Text(
                    'Interview Result',
                    style: AppTypography.semiBold(14,
                        color: Colors.white70),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 12),

              // Score ring + info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Glow + ring ──────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      AnimatedBuilder(
                        animation: ringAnim,
                        builder: (context, child) => Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scoreColor
                                    .withValues(alpha: 0.35 * ringAnim.value),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Ring
                      AnimatedBuilder(
                        animation: ringAnim,
                        builder: (context, child) => _ScoreRing(
                          score: score,
                          progress: ringAnim.value,
                          ringColor: scoreColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // ── Meta info ────────────────────────────────────
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Band chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: bandColor.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: bandColor.withValues(alpha: 0.50)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(bandIcon,
                                  size: 11, color: bandColor),
                              const SizedBox(width: 5),
                              Text(
                                band,
                                style: AppTypography.bold(11,
                                    color: bandColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Performance label
                        Text(
                          label,
                          style: AppTypography.bold(18,
                              color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 4),

                        // Role
                        Text(
                          role,
                          style: AppTypography.medium(12,
                              color: const Color(0xFF8A9EC0)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (company.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            company,
                            style: AppTypography.regular(11,
                                color: const Color(0xFF6A7E9E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Quick stats row ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: FeatherIcons.helpCircle,
                        value: '$totalQuestions',
                        label: 'Questions',
                      ),
                      _Divider(),
                      _StatChip(
                        icon: FeatherIcons.zap,
                        value: _capitalize(difficulty),
                        label: 'Difficulty',
                      ),
                      _Divider(),
                      _StatChip(
                        icon: FeatherIcons.award,
                        value: '${(score * totalQuestions ~/ 100)}/$totalQuestions',
                        label: 'Correct Est.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8EA6FF)),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTypography.bold(13, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.regular(10,
                color: const Color(0xFF8A9EC0)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

// ── Score Ring ────────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final int score;
  final double progress;
  final Color ringColor;

  const _ScoreRing({
    required this.score,
    required this.progress,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: CustomPaint(
        painter: _RingPainter(
          value: (score / 100) * progress,
          color: ringColor,
          trackColor: Colors.white.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: AppTypography.bold(42, color: Colors.white),
              ),
              Text(
                'out of 100',
                style: AppTypography.regular(9,
                    color: const Color(0xFF8A9BC0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 16) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
    );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

// ── Feedback Card (Strengths / Improve) ───────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<String> items;
  final AppColorScheme colors;

  const _FeedbackCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.bold(13, color: colors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.regular(11,
                          color: colors.foreground, height: 1.45),
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
