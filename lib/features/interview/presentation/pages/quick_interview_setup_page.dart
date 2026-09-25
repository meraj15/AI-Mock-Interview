import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

// ── Interview mode definition ─────────────────────────────────────────────────

class _InterviewMode {
  final String id;
  final String name;
  final String tagline;
  final String duration;
  final int questionCount;
  final IconData icon;
  final Color Function(AppColorScheme) accentColor;

  const _InterviewMode({
    required this.id,
    required this.name,
    required this.tagline,
    required this.duration,
    required this.questionCount,
    required this.icon,
    required this.accentColor,
  });
}

const _modes = [
  _InterviewMode(
    id: 'quick',
    name: 'Quick Practice',
    tagline: 'Warm up before an interview',
    duration: '~15 min',
    questionCount: 5,
    icon: FeatherIcons.zap,
    accentColor: _mintColor,
  ),
  _InterviewMode(
    id: 'mock',
    name: 'Mock Interview',
    tagline: 'Simulate a real full session',
    duration: '~30 min',
    questionCount: 8,
    icon: FeatherIcons.target,
    accentColor: _primaryColor,
  ),
  _InterviewMode(
    id: 'deep',
    name: 'Deep Dive',
    tagline: 'Serious prep, cover everything',
    duration: '~45 min',
    questionCount: 12,
    icon: FeatherIcons.layers,
    accentColor: _violetColor,
  ),
];

// Color helpers — top-level functions satisfy const requirement
Color _mintColor(AppColorScheme c) => c.mint;
Color _primaryColor(AppColorScheme c) => c.primary;
Color _violetColor(AppColorScheme c) => c.violet;

// ── Focus areas ───────────────────────────────────────────────────────────────

const _focusAreas = [
  'System Design',
  'Behavioral',
  'Data Structures',
  'Problem Solving',
  'Architecture',
  'Leadership',
  'Communication',
  'Performance',
  'Testing',
  'Security',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class QuickInterviewSetupPage extends StatefulWidget {
  const QuickInterviewSetupPage({super.key});

  @override
  State<QuickInterviewSetupPage> createState() =>
      _QuickInterviewSetupPageState();
}

class _QuickInterviewSetupPageState extends State<QuickInterviewSetupPage>
    with SingleTickerProviderStateMixin {
  _InterviewMode _selectedMode = _modes[1]; // default: Mock Interview
  int _timeLimitSeconds = 30;
  final Set<String> _selectedFocusAreas = {};

  static const _timeLimitOptions = [0, 15, 30, 45];
  String _timeLimitLabel(int s) => s == 0 ? 'None' : '${s}s';

  bool _isStartingSession = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectMode(_InterviewMode mode) {
    if (_selectedMode.id == mode.id) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _selectedMode = mode);
  }

  void _startInterview() {
    if (_isStartingSession) return;
    setState(() => _isStartingSession = true);

    final ic = context.read<InterviewController>();
    final rc = context.read<ResumeController>();
    final pc = context.read<ProfileController>();
    final auth = context.read<AuthController>();

    final userRole = pc.profile?.targetRole?.trim().isNotEmpty == true
        ? pc.profile!.targetRole!.trim()
        : (auth.user?.targetRole.trim().isNotEmpty == true
            ? auth.user!.targetRole.trim()
            : null);

    ic.resetSessionForNewInterview();
    ic.updateConfig(
      role: userRole,
      questions: _selectedMode.questionCount,
      timeLimitPerQuestion: _timeLimitSeconds,
      difficulty: 'Adaptive',
      focusTopics: _selectedFocusAreas.toList(),
    );
    ic.startInterview(
      resume: rc.resume,
      profile: pc.profile,
      targetRole: userRole,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterviewSessionPage()),
    ).then((_) {
      if (mounted) {
        setState(() => _isStartingSession = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Navy header ──────────────────────────────────────────
          _Header(colors: colors),

          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Mode cards ───────────────────────────────────
                  _Label(text: 'Interview Mode', colors: colors),
                  const SizedBox(height: 10),
                  Column(
                    children: _modes.map((mode) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ModeCard(
                          mode: mode,
                          isSelected: _selectedMode.id == mode.id,
                          colors: colors,
                          onTap: () => _selectMode(mode),
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
                      final sel = _timeLimitSeconds == t;
                      final last = t == _timeLimitOptions.last;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: last ? 0 : 8),
                          child: _SmallChip(
                            label: _timeLimitLabel(t),
                            selected: sel,
                            colors: colors,
                            onTap: () =>
                                setState(() => _timeLimitSeconds = t),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // ── Focus Areas ──────────────────────────────────
                  Row(
                    children: [
                      _Label(text: 'Focus Areas', colors: colors),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Optional',
                          style: AppTypography.regular(8.5,
                              color: colors.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AI will bias questions toward your selected topics.',
                    style: AppTypography.regular(11,
                        color: colors.mutedForeground, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _focusAreas.map((area) {
                      final sel = _selectedFocusAreas.contains(area);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            _selectedFocusAreas.remove(area);
                          } else {
                            _selectedFocusAreas.add(area);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel
                                ? colors.primary.withValues(alpha: 0.12)
                                : colors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? colors.primary
                                  : colors.border,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            area,
                            style: AppTypography.semiBold(
                              11,
                              color: sel
                                  ? colors.primary
                                  : colors.mutedForeground,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Adaptive AI Banner ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(FeatherIcons.cpu,
                              size: 18, color: colors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adaptive AI Interviewer',
                                style: AppTypography.semiBold(12.5,
                                    color: colors.foreground),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Difficulty adapts dynamically based on your answers & experience.',
                                style: AppTypography.regular(11,
                                    color: colors.mutedForeground,
                                    height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Summary card ─────────────────────────────────
                  Builder(builder: (context) {
                    final pc = context.watch<ProfileController>();
                    final auth = context.watch<AuthController>();
                    final ic = context.watch<InterviewController>();
                    final effectiveRole =
                        pc.profile?.targetRole?.trim().isNotEmpty == true
                            ? pc.profile!.targetRole!.trim()
                            : (auth.user?.targetRole.trim().isNotEmpty == true
                                ? auth.user!.targetRole.trim()
                                : ic.config.role);

                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: _SummaryCard(
                        targetRole: effectiveRole,
                        mode: _selectedMode,
                        timeLabel: _timeLimitLabel(_timeLimitSeconds),
                        focusAreas: _selectedFocusAreas.toList(),
                        colors: colors,
                      ),
                    );
                  }),

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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppColorScheme colors;
  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.navy,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                'Pick a mode that matches your time and goal.',
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
    return Text(
      text.toUpperCase(),
      style: AppTypography.bold(
        10,
        color: colors.mutedForeground,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final _InterviewMode mode;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = mode.accentColor(colors);
    final cardBg = isSelected
        ? accent.withValues(alpha: 0.09)
        : colors.card;
    final border = isSelected ? accent : colors.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            // Icon badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : colors.secondary,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                mode.icon,
                size: 20,
                color: isSelected ? accent : colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mode.name,
                          style: AppTypography.bold(
                            14,
                            color: colors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (mode.id == 'mock') ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Popular',
                            style: AppTypography.bold(8,
                                color: colors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.tagline,
                    style: AppTypography.regular(
                      11,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right meta
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${mode.questionCount} Qs',
                  style: AppTypography.bold(
                    13,
                    color: isSelected ? accent : colors.foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  mode.duration,
                  style: AppTypography.regular(
                    10,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Radio dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accent
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accent : colors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small chip (time limit) ───────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _SmallChip({
    required this.label,
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
        height: 44,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bold(
            13,
            color: selected ? colors.primaryForeground : colors.foreground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String targetRole;
  final _InterviewMode mode;
  final String timeLabel;
  final List<String> focusAreas;
  final AppColorScheme colors;

  const _SummaryCard({
    required this.targetRole,
    required this.mode,
    required this.timeLabel,
    required this.focusAreas,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final accent = mode.accentColor(colors);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const SizedBox(width: 8),
              // Role pill
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FeatherIcons.briefcase,
                          size: 10, color: colors.mint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          targetRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.semiBold(10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: mode.name,
                icon: mode.icon,
                accentColor: accent,
                colors: colors,
              ),
              _SummaryPill(
                label: '${mode.questionCount} Qs · ${mode.duration}',
                icon: FeatherIcons.clock,
                colors: colors,
              ),
              _SummaryPill(
                label: timeLabel == 'None' ? 'No time limit' : '$timeLabel / Q',
                icon: FeatherIcons.watch,
                colors: colors,
              ),
            ],
          ),
          if (focusAreas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: focusAreas.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    a,
                    style:
                        AppTypography.semiBold(9.5, color: colors.primary),
                  ),
                );
              }).toList(),
            ),
          ],
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
