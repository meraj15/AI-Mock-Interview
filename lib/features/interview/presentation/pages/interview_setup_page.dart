import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

class InterviewSetupPage extends StatefulWidget {
  const InterviewSetupPage({super.key});

  @override
  State<InterviewSetupPage> createState() => _InterviewSetupPageState();
}

class _InterviewSetupPageState extends State<InterviewSetupPage> {
  String _selectedType = 'Technical';
  String _selectedDifficulty = 'Medium';

  final List<Map<String, dynamic>> _types = [
    {
      'label': 'Technical',
      'detail': 'Code, architecture & role-specific problem solving',
      'icon': FeatherIcons.cpu,
      'emoji': '💻',
    },
    {
      'label': 'HR',
      'detail': 'Behavioral, STAR stories & culture fit questions',
      'icon': FeatherIcons.messageCircle,
      'emoji': '🤝',
    },
    {
      'label': 'Mixed',
      'detail': 'A full 360° mock combining both types',
      'icon': FeatherIcons.layers,
      'emoji': '🎯',
    },
  ];

  final List<Map<String, dynamic>> _difficulties = [
    {
      'label': 'Easy',
      'detail': 'Build confidence with a friendly pace',
      'icon': FeatherIcons.checkCircle,
      'color': 0xFF28A477,
    },
    {
      'label': 'Medium',
      'detail': 'Realistic industry interview standard',
      'icon': FeatherIcons.minus,
      'color': 0xFFF5C968,
    },
    {
      'label': 'Hard',
      'detail': 'Edge cases, deep architecture & stress testing',
      'icon': FeatherIcons.zap,
      'color': 0xFFF29B84,
    },
    {
      'label': 'Adaptive',
      'detail': 'Dynamically adjusts based on your answer depth',
      'icon': FeatherIcons.sliders,
      'color': 0xFF8E82E8,
    },
  ];

  void _startInterview() {
    final ctrl = context.read<InterviewController>();

    // Map type selection to controller format
    String typeValue;
    switch (_selectedType) {
      case 'HR':
        typeValue = 'Behavioral interview';
        break;
      case 'Mixed':
        typeValue = 'Full mock interview';
        break;
      default:
        typeValue = 'Technical interview';
    }

    ctrl.updateConfig(
      type: typeValue,
      difficulty: _selectedDifficulty,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterviewSessionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interview Setup',
                        style: AppTypography.bold(26, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your format and start practicing',
                        style: AppTypography.regular(13,
                            color: colors.mutedForeground),
                      ),
                    ],
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(FeatherIcons.mic,
                          size: 20, color: colors.mint),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Interview Type ─────────────────────────────────────
              _SectionHeader(
                colors: colors,
                number: '01',
                title: 'Select Interview Type',
              ),
              const SizedBox(height: 12),

              ..._types.map((t) {
                final label = t['label'] as String;
                final isSelected = _selectedType == label;
                return _TypeCard(
                  colors: colors,
                  label: label,
                  detail: t['detail'] as String,
                  icon: t['icon'] as IconData,
                  emoji: t['emoji'] as String,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedType = label),
                );
              }),

              const SizedBox(height: 28),

              // ── Difficulty ──────────────────────────────────────────
              _SectionHeader(
                colors: colors,
                number: '02',
                title: 'Select Difficulty',
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: _difficulties.map((d) {
                  final label = d['label'] as String;
                  final isSelected = _selectedDifficulty == label;
                  final color = Color(d['color'] as int);
                  return _DifficultyCard(
                    colors: colors,
                    label: label,
                    detail: d['detail'] as String,
                    icon: d['icon'] as IconData,
                    accentColor: color,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedDifficulty = label),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Summary pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(FeatherIcons.info,
                        size: 15, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_selectedType interview · $_selectedDifficulty difficulty',
                        style:
                            AppTypography.semiBold(13, color: colors.foreground),
                      ),
                    ),
                    Icon(FeatherIcons.chevronRight,
                        size: 15, color: colors.mutedForeground),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              AppButton(
                label: 'Start Interview',
                icon: FeatherIcons.play,
                onPress: _startInterview,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final AppColorScheme colors;
  final String number;
  final String title;

  const _SectionHeader({
    required this.colors,
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              number,
              style:
                  AppTypography.bold(10, color: colors.primaryForeground),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTypography.bold(16, color: colors.foreground)),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final AppColorScheme colors;
  final String label;
  final String detail;
  final IconData icon;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.colors,
    required this.label,
    required this.detail,
    required this.icon,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.6)
                    : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTypography.bold(15,
                              color: colors.foreground)),
                      const SizedBox(height: 3),
                      Text(detail,
                          style: AppTypography.regular(11,
                              color: colors.mutedForeground)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? colors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check,
                          size: 13, color: colors.primaryForeground)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final AppColorScheme colors;
  final String label;
  final String detail;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.colors,
    required this.label,
    required this.detail,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.5)
                  : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon,
                      size: 18,
                      color:
                          isSelected ? accentColor : colors.mutedForeground),
                  if (isSelected)
                    Icon(FeatherIcons.checkCircle,
                        size: 14, color: accentColor),
                ],
              ),
              const Spacer(),
              Text(label,
                  style: AppTypography.bold(14,
                      color: isSelected ? accentColor : colors.foreground)),
              const SizedBox(height: 2),
              Text(detail,
                  style: AppTypography.regular(9,
                      color: colors.mutedForeground, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
