import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

class InterviewConfigPage extends StatefulWidget {
  const InterviewConfigPage({super.key});

  @override
  State<InterviewConfigPage> createState() => _InterviewConfigPageState();
}

class _InterviewConfigPageState extends State<InterviewConfigPage> {
  // Local mutable state driven from controller config
  int _questionCount = 10;
  int _timeLimitPerQuestion = 120; // seconds
  bool _showHints = false;
  bool _enableFollowUps = true;
  bool _enableVoiceMode = false;
  String _selectedLanguage = 'English';
  String _selectedAiPersona = 'Professional Interviewer';
  String _selectedCodingLanguage = 'Any / No Preference';
  final Set<String> _selectedFocusTopics = {'State Management', 'Clean Architecture', 'Performance'};

  static const _languages = ['English', 'Hindi', 'Spanish', 'German', 'French', 'Portuguese'];

  static const _aiPersonas = [
    'Professional Interviewer',
    'Startup CTO',
    'FAANG Senior Engineer',
    'Friendly Mentor',
    'Strict Panel',
  ];

  static const _codingLanguages = [
    'Any / No Preference',
    'Dart / Flutter',
    'Kotlin',
    'Swift',
    'Python',
    'JavaScript / TypeScript',
    'Java',
    'Go',
  ];

  static const _allFocusTopics = [
    'State Management',
    'Clean Architecture',
    'Performance Optimization',
    'System Design',
    'API Integration & REST',
    'Database & Caching',
    'Testing & TDD',
    'CI/CD & DevOps',
    'Security & Auth',
    'Behavioral (STAR)',
    'Concurrency & Async',
    'Memory Management',
  ];

  String _formatTimeLimit(int seconds) {
    if (seconds == 0) return 'No Limit';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  @override
  void initState() {
    super.initState();
    final config = context.read<InterviewController>().config;
    _questionCount = config.questions;
    _timeLimitPerQuestion = config.timeLimitPerQuestion;
    _showHints = config.showHints;
    _enableFollowUps = config.enableFollowUps;
    _enableVoiceMode = config.enableVoiceMode;
    _selectedLanguage = config.language;
    _selectedAiPersona = config.aiPersona;
    _selectedCodingLanguage = config.codingLanguage;
    _selectedFocusTopics.clear();
    _selectedFocusTopics.addAll(config.focusTopics);
  }

  void _saveAndStart() {
    final interviewCtrl = context.read<InterviewController>();
    interviewCtrl.updateConfig(
      questions: _questionCount,
      timeLimitPerQuestion: _timeLimitPerQuestion,
      showHints: _showHints,
      enableFollowUps: _enableFollowUps,
      enableVoiceMode: _enableVoiceMode,
      language: _selectedLanguage,
      aiPersona: _selectedAiPersona,
      codingLanguage: _selectedCodingLanguage,
      focusTopics: _selectedFocusTopics.toList(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InterviewSessionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final config = context.watch<InterviewController>().config;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Interview Configuration',
            subtitle: 'Deep Customization',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Config Summary Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.sliders, size: 20, color: colors.navy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(config.role, style: AppTypography.bold(15, color: Colors.white)),
                          Text(
                            '${config.company} · ${config.difficulty} · ${config.type}',
                            style: AppTypography.regular(10, color: const Color(0xFFBFCBE5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PillBadge(label: config.experience, tone: PillTone.success),
                    PillBadge(label: '${_questionCount}Q', tone: PillTone.muted),
                    PillBadge(label: _formatTimeLimit(_timeLimitPerQuestion), tone: PillTone.muted),
                    if (_enableVoiceMode) PillBadge(label: 'Voice On', tone: PillTone.violet),
                  ],
                ),
              ],
            ),
          ),

          // ── Question Count ──────────────────────────────────────
          const SectionTitle(title: 'Number of Questions'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Questions per session', style: AppTypography.semiBold(12, color: colors.foreground)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_questionCount',
                        style: AppTypography.bold(14, color: colors.primary),
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 3,
                  max: 20,
                  divisions: 17,
                  value: _questionCount.toDouble(),
                  activeColor: colors.primary,
                  inactiveColor: colors.secondary,
                  onChanged: (v) => setState(() => _questionCount = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3 (Quick)', style: AppTypography.regular(10, color: colors.mutedForeground)),
                    Text('20 (Deep Dive)', style: AppTypography.regular(10, color: colors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),

          // ── Time Limit ──────────────────────────────────────────
          const SectionTitle(title: 'Time Limit Per Question'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Answer time limit', style: AppTypography.semiBold(12, color: colors.foreground)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatTimeLimit(_timeLimitPerQuestion),
                        style: AppTypography.bold(12, color: colors.primary),
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 0,
                  max: 300,
                  divisions: 30,
                  value: _timeLimitPerQuestion.toDouble(),
                  activeColor: colors.primary,
                  inactiveColor: colors.secondary,
                  onChanged: (v) => setState(() => _timeLimitPerQuestion = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('No Limit', style: AppTypography.regular(10, color: colors.mutedForeground)),
                    Text('5 minutes', style: AppTypography.regular(10, color: colors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),

          // ── Focus Topics ────────────────────────────────────────
          const SectionTitle(title: 'Focus Topics'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI will bias questions toward your selected focus areas.',
                  style: AppTypography.regular(11, color: colors.mutedForeground),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allFocusTopics.map((topic) {
                    final isSelected = _selectedFocusTopics.contains(topic);
                    return InkWell(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedFocusTopics.remove(topic);
                        } else {
                          _selectedFocusTopics.add(topic);
                        }
                      }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          topic,
                          style: AppTypography.semiBold(
                            10,
                            color: isSelected ? colors.primaryForeground : colors.foreground,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── AI Persona ──────────────────────────────────────────
          const SectionTitle(title: 'AI Interviewer Persona'),
          _DropdownRow(
            label: _selectedAiPersona,
            icon: FeatherIcons.user,
            options: _aiPersonas,
            colors: colors,
            onSelected: (v) => setState(() => _selectedAiPersona = v),
          ),

          // ── Coding Language ─────────────────────────────────────
          const SectionTitle(title: 'Coding Language Preference'),
          _DropdownRow(
            label: _selectedCodingLanguage,
            icon: FeatherIcons.code,
            options: _codingLanguages,
            colors: colors,
            onSelected: (v) => setState(() => _selectedCodingLanguage = v),
          ),

          // ── Interview Language ───────────────────────────────────
          const SectionTitle(title: 'Interview Language'),
          _DropdownRow(
            label: _selectedLanguage,
            icon: FeatherIcons.globe,
            options: _languages,
            colors: colors,
            onSelected: (v) => setState(() => _selectedLanguage = v),
          ),

          // ── Toggles ─────────────────────────────────────────────
          const SectionTitle(title: 'Session Behavior'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Enable Follow-up Questions',
                  description: 'AI digs deeper based on your answers.',
                  icon: FeatherIcons.gitBranch,
                  value: _enableFollowUps,
                  onChanged: (v) => setState(() => _enableFollowUps = v),
                  colors: colors,
                ),
                Divider(color: colors.border, height: 24),
                _ToggleRow(
                  label: 'Show Context Hints',
                  description: 'Subtle topic pointers before each question.',
                  icon: FeatherIcons.info,
                  value: _showHints,
                  onChanged: (v) => setState(() => _showHints = v),
                  colors: colors,
                ),
                Divider(color: colors.border, height: 24),
                _ToggleRow(
                  label: 'Voice Mode (Spoken Interview)',
                  description: 'AI reads questions aloud. Answer verbally.',
                  icon: FeatherIcons.mic,
                  value: _enableVoiceMode,
                  onChanged: (v) => setState(() => _enableVoiceMode = v),
                  colors: colors,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Save & Start Interview',
            icon: FeatherIcons.play,
            onPress: _saveAndStart,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─── Internal Helpers ────────────────────────────────────────────────────────

class _DropdownRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final AppColorScheme colors;
  final ValueChanged<String> onSelected;

  const _DropdownRow({
    required this.label,
    required this.icon,
    required this.options,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          isExpanded: true,
          icon: Icon(FeatherIcons.chevronDown, size: 16, color: colors.mutedForeground),
          dropdownColor: colors.card,
          style: AppTypography.semiBold(13, color: colors.foreground),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Row(
                children: [
                  Icon(icon, size: 14, color: colors.primary),
                  const SizedBox(width: 10),
                  Text(opt, style: AppTypography.semiBold(13, color: colors.foreground)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onSelected(v);
          },
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;

  const _ToggleRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: value ? colors.primary : colors.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.semiBold(12, color: colors.foreground)),
              Text(description, style: AppTypography.regular(10, color: colors.mutedForeground)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
          activeThumbColor: Colors.white,
        ),
      ],
    );
  }
}
