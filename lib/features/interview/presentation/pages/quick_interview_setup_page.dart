import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
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
  String _interviewType = 'Technical interview';

  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Adaptive'];
  static const _interviewTypes = [
    'Technical interview',
    'Behavioral interview',
    'System design & architecture',
    'Full mock interview',
  ];
  static const _questionOptions = [5, 10, 15, 20];
  static const _timeLimitOptions = [0, 1, 2, 3, 5];

  String _timeLimitLabel(int m) => m == 0 ? 'None' : '${m}m';

  void _startInterview() {
    final ic = context.read<InterviewController>();
    final rc = context.read<ResumeController>();
    ic.updateConfig(
      questions: _questionCount,
      timeLimitPerQuestion: _timeLimitMinutes * 60,
      difficulty: _difficulty,
      type: _interviewType,
    );
    ic.startInterview(resume: rc.resume);
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

  IconData _typeIcon(String t) {
    switch (t) {
      case 'Behavioral interview':           return FeatherIcons.messageCircle;
      case 'System design & architecture':   return FeatherIcons.share2;
      case 'Full mock interview':            return FeatherIcons.layers;
      default:                               return FeatherIcons.cpu;
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

                  const SizedBox(height: 22),

                  // ── Interview Type dropdown ───────────────────────
                  _Label(text: 'Interview type', colors: colors),
                  const SizedBox(height: 10),
                  _TypeDropdown(
                    selected: _interviewType,
                    options: _interviewTypes,
                    colors: colors,
                    typeIcon: _typeIcon,
                    onSelect: (t) => setState(() => _interviewType = t),
                  ),

                  const SizedBox(height: 24),

                  // ── Summary card ─────────────────────────────────
                  _SummaryCard(
                    questionCount: _questionCount,
                    timeLabel: _timeLimitLabel(_timeLimitMinutes),
                    difficulty: _difficulty,
                    type: _interviewType,
                    difficultyColor: _difficultyColor(_difficulty, colors),
                    typeIcon: _typeIcon(_interviewType),
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

// ── Interview type dropdown trigger ──────────────────────────────────────────

class _TypeDropdown extends StatelessWidget {
  final String selected;
  final List<String> options;
  final AppColorScheme colors;
  final IconData Function(String) typeIcon;
  final ValueChanged<String> onSelect;

  const _TypeDropdown({
    required this.selected,
    required this.options,
    required this.colors,
    required this.typeIcon,
    required this.onSelect,
  });

  String _subtitle(String t) {
    const map = {
      'Technical interview': 'Role mastery, APIs & problem solving',
      'Behavioral interview': 'STAR stories, teamwork & conflict',
      'System design & architecture': 'Scalability, reliability & trade-offs',
      'Full mock interview': '360° realistic mix of all categories',
    };
    return map[t] ?? '';
  }

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TypeSheet(
        selected: selected,
        options: options,
        colors: colors,
        typeIcon: typeIcon,
        subtitle: _subtitle,
        onSelect: (t) {
          Navigator.of(context).pop();
          onSelect(t);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(typeIcon(selected), size: 18, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected,
                    style: AppTypography.semiBold(13, color: colors.foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(selected),
                    style: AppTypography.regular(
                        11, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                FeatherIcons.chevronDown,
                size: 14,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Interview type bottom sheet ───────────────────────────────────────────────

class _TypeSheet extends StatelessWidget {
  final String selected;
  final List<String> options;
  final AppColorScheme colors;
  final IconData Function(String) typeIcon;
  final String Function(String) subtitle;
  final ValueChanged<String> onSelect;

  const _TypeSheet({
    required this.selected,
    required this.options,
    required this.colors,
    required this.typeIcon,
    required this.subtitle,
    required this.onSelect,
  });

  Color _iconBg(String t, AppColorScheme c) {
    switch (t) {
      case 'Behavioral interview':         return c.accent;
      case 'System design & architecture': return c.violet.withValues(alpha: 0.15);
      case 'Full mock interview':          return c.navy;
      default:                             return c.primary.withValues(alpha: 0.1);
    }
  }

  Color _iconFg(String t, AppColorScheme c) {
    switch (t) {
      case 'Behavioral interview':         return c.accentForeground;
      case 'System design & architecture': return c.violet;
      case 'Full mock interview':          return c.mint;
      default:                             return c.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Interview type',
            style: AppTypography.bold(18, color: colors.foreground),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the format that fits your goal.',
            style: AppTypography.regular(12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),

          ...options.map((type) {
            final sel = type == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelect(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel
                        ? colors.primary.withValues(alpha: 0.07)
                        : colors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? colors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _iconBg(type, colors),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          typeIcon(type),
                          size: 18,
                          color: _iconFg(type, colors),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: AppTypography.semiBold(
                                13,
                                color: sel ? colors.primary : colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle(type),
                              style: AppTypography.regular(
                                11,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color:
                              sel ? colors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? colors.primary : colors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: sel
                            ? Icon(
                                FeatherIcons.check,
                                size: 11,
                                color: colors.primaryForeground,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int questionCount;
  final String timeLabel;
  final String difficulty;
  final String type;
  final Color difficultyColor;
  final IconData typeIcon;
  final AppColorScheme colors;

  const _SummaryCard({
    required this.questionCount,
    required this.timeLabel,
    required this.difficulty,
    required this.type,
    required this.difficultyColor,
    required this.typeIcon,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 14, color: const Color(0xFFBFCBE5)),
                const SizedBox(width: 8),
                Text(
                  type,
                  style: AppTypography.semiBold(
                    12,
                    color: const Color(0xFFBFCBE5),
                  ),
                ),
              ],
            ),
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
