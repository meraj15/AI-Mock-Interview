import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TabController _tabs;
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _ringCtrl.forward();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  void _share(BuildContext ctx, dynamic eval, dynamic config) {
    final colors = AppColorScheme.of(ctx);
    final score = eval?.overallScore ?? 84;
    final band  = eval?.hiringBand ?? 'Strong Hire';

    final text = '''
AI MOCK INTERVIEW REPORT
─────────────────────────
Role    : ${config.role}
Company : ${config.company}
Score   : $score / 100
Verdict : $band

${eval?.summary ?? ''}

✓ Strengths
${(eval?.strengths as List?)?.map((s) => '  • $s').join('\n') ?? ''}

→ Improve
${(eval?.areasToImprove as List?)?.map((a) => '  • $a').join('\n') ?? ''}

— Interview Coach
''';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Export debrief', style: AppTypography.bold(17, color: colors.foreground)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                text,
                style: AppTypography.regular(10, color: colors.foreground, height: 1.55),
                maxLines: 14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Copy to clipboard',
              icon: FeatherIcons.copy,
              onPress: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.of(c).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final ic     = context.watch<InterviewController>();
    final eval   = ic.lastEvaluation;
    final config = ic.config;

    final score = eval?.overallScore ?? 84;
    final band  = eval?.hiringBand  ?? 'Strong Hire';
    final label = eval?.performanceLabel ?? 'Strong Candidate';
    final summary = eval?.summary ??
        'You demonstrated solid technical fundamentals. Add measurable metrics to take your answers further.';
    final benchmark = eval?.benchmark;

    final skillRows = eval != null
        ? eval.skillScores.entries.map((e) => _SkillRow(
              label: e.key, value: e.value,
              note: e.value >= 85 ? 'Strong' : e.value >= 75 ? 'Good' : 'Growing',
              colors: colors,
            )).toList()
        : [
            _SkillRow(label: 'Technical Knowledge',     value: 88, note: 'Strong', colors: colors),
            _SkillRow(label: 'Communication & Clarity', value: 82, note: 'Good',   colors: colors),
            _SkillRow(label: 'Problem Solving',         value: 86, note: 'Strong', colors: colors),
            _SkillRow(label: 'Confidence & Delivery',   value: 79, note: 'Good',   colors: colors),
            _SkillRow(label: 'Role Mastery',            value: 90, note: 'Strong', colors: colors),
          ];

    final strengths   = eval?.strengths    ?? ['Strong architectural intuition.', 'Structured communication.'];
    final improvements = eval?.areasToImprove ?? ['Quantify results with metrics.', 'Deeper edge-case coverage.'];
    final studyPlan   = eval?.studyPlan    ?? [];

    // Band colour
    final bandColor = band.contains('Strong Hire')
        ? colors.success
        : band.contains('Hire')
            ? colors.primary
            : band.contains('Leaning')
                ? colors.yellow
                : colors.coral;

    // Score colour
    final scoreColor = score >= 85
        ? colors.mint
        : score >= 70
            ? colors.primary
            : colors.coral;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Hero block ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Nav row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(FeatherIcons.x, size: 18, color: Colors.white60),
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainNavPage()),
                            (_) => false,
                          ),
                        ),
                        const Spacer(),
                        Text('Interview Debrief',
                            style: AppTypography.bold(15, color: Colors.white)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(FeatherIcons.share2, size: 17, color: Colors.white60),
                          onPressed: () => _share(context, eval, config),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Score + info centred ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Animated score ring — centred
                        AnimatedBuilder(
                          animation: _ringAnim,
                          builder: (_, __) => _ScoreRing(
                            score: score,
                            progress: _ringAnim.value,
                            ringColor: scoreColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hiring band badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: bandColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: bandColor.withValues(alpha: 0.55)),
                          ),
                          child: Text(
                            band,
                            style: AppTypography.bold(12, color: bandColor),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Performance label
                        Text(
                          label,
                          style: AppTypography.bold(20, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        // Role
                        Text(
                          config.role,
                          style: AppTypography.regular(12, color: const Color(0xFF8A9BC0)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Benchmark strip
                  if (benchmark != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FeatherIcons.trendingUp, size: 13, color: colors.mint),
                            const SizedBox(width: 8),
                            Text(
                              'Top ${100 - benchmark.percentile}%  ·  ${benchmark.readinessLevel}',
                              style: AppTypography.semiBold(11, color: const Color(0xFFBFCBE5)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicator: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: AppTypography.semiBold(12, color: Colors.white),
                        unselectedLabelStyle: AppTypography.regular(12, color: Colors.white54),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Skills'),
                          Tab(text: 'Improve'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Tab views ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Overview ─────────────────────────────────────────
                _Tab(children: [
                  _Card(
                    icon: FeatherIcons.messageSquare,
                    title: 'AI Summary',
                    colors: colors,
                    child: Text(
                      summary,
                      style: AppTypography.regular(13, color: colors.foreground, height: 1.6),
                    ),
                  ),

                  if (benchmark != null) ...[
                    const SizedBox(height: 12),
                    _Card(
                      icon: FeatherIcons.barChart2,
                      title: 'vs. Industry Average',
                      colors: colors,
                      child: _BenchmarkBars(
                        yourScore: score,
                        avg: benchmark.industryAverageScore,
                        yourColor: scoreColor,
                        colors: colors,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: AppButton(
                        label: 'Review Qs',
                        icon: FeatherIcons.list,
                        variant: ButtonVariant.secondary,
                        onPress: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QuestionReviewPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'New session',
                        icon: FeatherIcons.refreshCw,
                        onPress: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const QuickInterviewSetupPage()),
                        ),
                      ),
                    ),
                  ]),
                ]),

                // ── Skills ───────────────────────────────────────────
                _Tab(children: [
                  _Card(
                    icon: FeatherIcons.activity,
                    title: 'Skill Breakdown',
                    colors: colors,
                    child: Column(children: skillRows),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    icon: FeatherIcons.checkCircle,
                    title: 'Key Strengths',
                    iconColor: colors.success,
                    colors: colors,
                    child: Column(
                      children: strengths.map((s) => _Bullet(
                        text: s, icon: FeatherIcons.check, color: colors.success, colors: colors,
                      )).toList(),
                    ),
                  ),
                ]),

                // ── Improve ──────────────────────────────────────────
                _Tab(children: [
                  _Card(
                    icon: FeatherIcons.target,
                    title: 'Areas to Improve',
                    iconColor: colors.coral,
                    colors: colors,
                    child: Column(
                      children: improvements.map((a) => _Bullet(
                        text: a, icon: FeatherIcons.arrowRight, color: colors.coral, colors: colors,
                      )).toList(),
                    ),
                  ),
                  if (studyPlan.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Card(
                      icon: FeatherIcons.bookOpen,
                      title: 'Study Roadmap',
                      colors: colors,
                      child: Column(
                        children: [
                          for (int i = 0; i < studyPlan.length; i++) ...[
                            _StudyItem(plan: studyPlan[i], colors: colors),
                            if (i < studyPlan.length - 1)
                              Divider(color: colors.border, height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated score ring ───────────────────────────────────────────────────────

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
      width: 120,
      height: 120,
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
                style: AppTypography.bold(38, color: Colors.white),
              ),
              Text(
                'out of 100',
                style: AppTypography.regular(9, color: const Color(0xFF8A9BC0)),
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
    final radius = (size.width - 14) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(
      rect, -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (value > 0) {
      canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * value, false,
        Paint()
          ..color = color
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

// ── Benchmark bars ─────────────────────────────────────────────────────────────

class _BenchmarkBars extends StatelessWidget {
  final int yourScore;
  final int avg;
  final Color yourColor;
  final AppColorScheme colors;

  const _BenchmarkBars({
    required this.yourScore,
    required this.avg,
    required this.yourColor,
    required this.colors,
  });

  Widget _bar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: AppTypography.semiBold(11, color: colors.foreground)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 10,
                backgroundColor: colors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: AppTypography.bold(12, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _bar('You', yourScore, yourColor),
        _bar('Avg.', avg, colors.mutedForeground),
      ],
    );
  }
}

// ── Reusable card ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final AppColorScheme colors;
  final Color? iconColor;

  const _Card({
    required this.icon,
    required this.title,
    required this.child,
    required this.colors,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Icon(icon, size: 15, color: iconColor ?? colors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.bold(14, color: colors.foreground)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Skill row ──────────────────────────────────────────────────────────────────

class _SkillRow extends StatelessWidget {
  final String label;
  final int value;
  final String note;
  final AppColorScheme colors;

  const _SkillRow({
    required this.label, required this.value,
    required this.note,  required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isGrowing = note == 'Growing';
    final barColor  = isGrowing ? colors.coral : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: AppTypography.medium(12, color: colors.foreground))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$value%  $note',
                  style: AppTypography.semiBold(10, color: barColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: colors.secondary,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bullet row ─────────────────────────────────────────────────────────────────

class _Bullet extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final AppColorScheme colors;

  const _Bullet({
    required this.text, required this.icon,
    required this.color, required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.regular(12, color: colors.foreground, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Study plan item ────────────────────────────────────────────────────────────

class _StudyItem extends StatelessWidget {
  final dynamic plan;
  final AppColorScheme colors;

  const _StudyItem({required this.plan, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                plan.topic as String,
                style: AppTypography.semiBold(13, color: colors.foreground),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plan.estimatedTime as String,
                style: AppTypography.semiBold(10, color: colors.mutedForeground),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          plan.rationale as String,
          style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.4),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(FeatherIcons.zap, size: 12, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Drill: ${plan.actionDrill}',
                  style: AppTypography.semiBold(11, color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Scroll tab container ───────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final List<Widget> children;
  const _Tab({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
