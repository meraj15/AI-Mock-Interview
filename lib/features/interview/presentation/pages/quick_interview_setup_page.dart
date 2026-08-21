import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

/// A simple, focused pre-interview setup screen.
/// Replaces the 6-step CreateInterviewPage with just the essentials:
/// question count, time limit, difficulty and interview type.
class QuickInterviewSetupPage extends StatefulWidget {
  const QuickInterviewSetupPage({super.key});

  @override
  State<QuickInterviewSetupPage> createState() => _QuickInterviewSetupPageState();
}

class _QuickInterviewSetupPageState extends State<QuickInterviewSetupPage> {
  int _questionCount = 10;
  int _timeLimitMinutes = 2; // minutes per question (0 = no limit)
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
  static const _timeLimitOptions = [0, 1, 2, 3, 5]; // 0 = No limit

  String _timeLimitLabel(int minutes) {
    if (minutes == 0) return 'No limit';
    return '$minutes min';
  }

  void _startInterview() {
    final interviewCtrl = context.read<InterviewController>();
    final resumeCtrl = context.read<ResumeController>();

    interviewCtrl.updateConfig(
      questions: _questionCount,
      timeLimitPerQuestion: _timeLimitMinutes * 60,
      difficulty: _difficulty,
      type: _interviewType,
    );

    // Kick off the AI question generation, then navigate
    interviewCtrl.startInterview(resume: resumeCtrl.resume);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InterviewSessionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.x, size: 18, color: colors.foreground),
                    ),
                  ),
                  Text(
                    'Quick Setup',
                    style: AppTypography.bold(16, color: colors.foreground),
                  ),
                  const SizedBox(width: 38), // balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero copy
                    const SizedBox(height: 8),
                    Text(
                      'Ready when you are.',
                      style: AppTypography.bold(26, color: colors.foreground),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick your settings and start. Keeps it simple.',
                      style: AppTypography.regular(13, color: colors.mutedForeground),
                    ),

                    const SizedBox(height: 28),

                    // ── Question Count ───────────────────────────────
                    _SectionLabel(label: 'Number of questions', colors: colors),
                    const SizedBox(height: 10),
                    Row(
                      children: _questionOptions.map((q) {
                        final isSelected = _questionCount == q;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ToggleChip(
                              label: '$q',
                              sublabel: q <= 5
                                  ? 'Quick'
                                  : q >= 20
                                      ? 'Deep'
                                      : null,
                              isSelected: isSelected,
                              colors: colors,
                              onTap: () => setState(() => _questionCount = q),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Time Per Question ───────────────────────────
                    _SectionLabel(label: 'Time per question', colors: colors),
                    const SizedBox(height: 10),
                    Row(
                      children: _timeLimitOptions.map((t) {
                        final isSelected = _timeLimitMinutes == t;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ToggleChip(
                              label: _timeLimitLabel(t),
                              isSelected: isSelected,
                              colors: colors,
                              onTap: () => setState(() => _timeLimitMinutes = t),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Difficulty ──────────────────────────────────
                    _SectionLabel(label: 'Difficulty', colors: colors),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _difficulties.map((d) {
                        final isSelected = _difficulty == d;
                        return GestureDetector(
                          onTap: () => setState(() => _difficulty = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary : colors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _difficultyIcon(d),
                                  size: 14,
                                  color: isSelected
                                      ? colors.primaryForeground
                                      : colors.mutedForeground,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  d,
                                  style: AppTypography.semiBold(
                                    13,
                                    color: isSelected
                                        ? colors.primaryForeground
                                        : colors.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Interview Type ──────────────────────────────
                    _SectionLabel(label: 'Interview type', colors: colors),
                    const SizedBox(height: 10),
                    ..._interviewTypes.map((type) {
                      final isSelected = _interviewType == type;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _interviewType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.08)
                                  : colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.15)
                                        : colors.secondary,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _typeIcon(type),
                                    size: 16,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type,
                                    style: AppTypography.semiBold(
                                      13,
                                      color: isSelected
                                          ? colors.primary
                                          : colors.foreground,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    FeatherIcons.checkCircle,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // ── Session preview pill ────────────────────────
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(FeatherIcons.info, size: 14, color: colors.mint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$_questionCount questions · '
                              '${_timeLimitLabel(_timeLimitMinutes)} each · '
                              '$_difficulty · $_interviewType',
                              style: AppTypography.semiBold(
                                11,
                                color: const Color(0xFFBFCBE5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Start button ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: AppButton(
                label: 'Start interview',
                icon: FeatherIcons.play,
                onPress: _startInterview,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _difficultyIcon(String d) {
    switch (d) {
      case 'Easy':
        return FeatherIcons.checkCircle;
      case 'Hard':
        return FeatherIcons.zap;
      case 'Adaptive':
        return FeatherIcons.sliders;
      default:
        return FeatherIcons.minus;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Behavioral interview':
        return FeatherIcons.messageCircle;
      case 'System design & architecture':
        return FeatherIcons.share2;
      case 'Full mock interview':
        return FeatherIcons.layers;
      default:
        return FeatherIcons.cpu;
    }
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColorScheme colors;

  const _SectionLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bold(14, color: colors.foreground),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.bold(
                14,
                color: isSelected ? colors.primaryForeground : colors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: AppTypography.regular(
                  9,
                  color: isSelected
                      ? colors.primaryForeground.withValues(alpha: 0.7)
                      : colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
