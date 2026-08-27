import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

class QuickInterviewSetupPage extends StatefulWidget {
  const QuickInterviewSetupPage({super.key});

  @override
  State<QuickInterviewSetupPage> createState() =>
      _QuickInterviewSetupPageState();
}

class _QuickInterviewSetupPageState extends State<QuickInterviewSetupPage> {
  int _questionCount = 10;
  int _timeLimitMinutes = 2;
  String _difficulty = 'Medium';

  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Adaptive'];
  static const _questionOptions = [2, 10, 15, 20];
  static const _timeLimitOptions = [0, 1, 2, 3, 5];

  String _timeLimitLabel(int m) => m == 0 ? 'None' : '${m}m';

  void _startInterview() {
    final ic = context.read<InterviewController>();
    final rc = context.read<ResumeController>();
    final pc = context.read<ProfileController>();
    ic.updateConfig(
      questions: _questionCount,
      timeLimitPerQuestion: _timeLimitMinutes * 60,
      difficulty: _difficulty,
    );
    ic.startInterview(resume: rc.resume, profile: pc.profile);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterviewSessionPage()),
    );
  }

  IconData _difficultyIcon(String d) {
    switch (d) {
      case 'Easy':   return FeatherIcons.sun;
      case 'Hard':   return FeatherIcons.zap;
      case 'Adaptive': return FeatherIcons.sliders;
      default:       return FeatherIcons.minus;
    }
  }

  Color _difficultyColor(String d, AppColorScheme c) {
    switch (d) {
      case 'Easy':     return c.success;
      case 'Hard':     return c.coral;
      case 'Adaptive': return c.violet;
      default:         return c.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Navy header ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close + title on same row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              FeatherIcons.arrowLeft,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Quick Setup',
                          style: AppTypography.bold(17, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Set up your interview',
                      style: AppTypography.bold(24, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pick your format and start in seconds.',
                      style: AppTypography.regular(
                        13,
                        color: const Color(0xFFBFCBE5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Question Count ───────────────────────────────
                  _Label(text: 'Questions', colors: colors),
                  const SizedBox(height: 10),
                  Row(
                    children: _questionOptions.map((q) {
                      final sel = _questionCount == q;
                      final last = q == _questionOptions.last;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: last ? 0 : 8),
                          child: _CountChip(
                            label: '$q',
                            sublabel: q == 5
                                ? 'Quick'
                                : q == 20
                                    ? 'Deep'
                                    : null,
                            selected: sel,
                            colors: colors,
                            onTap: () => setState(() => _questionCount = q),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // ── Time Limit ───────────────────────────────────
                  _Label(text: 'Time per question', colors: colors),
                  const SizedBox(height: 10),
                  Row(
                    children: _timeLimitOptions.map((t) {
                      final sel = _timeLimitMinutes == t;
                      final last = t == _timeLimitOptions.last;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: last ? 0 : 8),
                          child: _CountChip(
                            label: _timeLimitLabel(t),
                            selected: sel,
                            colors: colors,
                            onTap: () => setState(() => _timeLimitMinutes = t),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // ── Difficulty ───────────────────────────────────
                  _Label(text: 'Difficulty', colors: colors),
                  const SizedBox(height: 10),
                  Row(
                    children: _difficulties.map((d) {
                      final sel = _difficulty == d;
                      final last = d == _difficulties.last;
                      final accent = _difficultyColor(d, colors);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: last ? 0 : 8),
                          child: _DiffChip(
                            label: d,
                            icon: _difficultyIcon(d),
                            accent: accent,
                            selected: sel,
                            colors: colors,
                            onTap: () => setState(() => _difficulty = d),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Summary card ─────────────────────────────────
                  _SummaryCard(
                    questionCount: _questionCount,
                    timeLabel: _timeLimitLabel(_timeLimitMinutes),
                    difficulty: _difficulty,
                    difficultyColor: _difficultyColor(_difficulty, colors),
                    colors: colors,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Start CTA ────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: AppButton(
                label: 'Start interview',
                icon: FeatherIcons.play,
                onPress: _startInterview,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final AppColorScheme colors;
  const _Label({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: AppTypography.bold(
            10,
            color: colors.mutedForeground,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Count chip (question count + time limit) ──────────────────────────────────

class _CountChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _CountChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 58,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.bold(
                15,
                color:
                    selected ? colors.primaryForeground : colors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: AppTypography.regular(
                  9,
                  color: selected
                      ? colors.primaryForeground.withValues(alpha: 0.65)
                      : colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Difficulty chip ────────────────────────────────────────────────────────────

class _DiffChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _DiffChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 68,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? accent : colors.mutedForeground,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.semiBold(
                11,
                color: selected ? accent : colors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int questionCount;
  final String timeLabel;
  final String difficulty;
  final Color difficultyColor;
  final AppColorScheme colors;

  const _SummaryCard({
    required this.questionCount,
    required this.timeLabel,
    required this.difficulty,
    required this.difficultyColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.layers, size: 13, color: colors.mint),
              const SizedBox(width: 7),
              Text(
                'SESSION SUMMARY',
                style: AppTypography.bold(
                  10,
                  color: colors.mint,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryPill(
                label: '$questionCount Q',
                icon: FeatherIcons.helpCircle,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                label: timeLabel,
                icon: FeatherIcons.clock,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _SummaryPill(
                label: difficulty,
                icon: FeatherIcons.activity,
                accentColor: difficultyColor,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppColorScheme colors;
  final Color? accentColor;

  const _SummaryPill({
    required this.label,
    required this.icon,
    required this.colors,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accentColor ?? const Color(0xFFBFCBE5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor != null
              ? accentColor!.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.semiBold(11, color: fg)),
        ],
      ),
    );
  }
}
