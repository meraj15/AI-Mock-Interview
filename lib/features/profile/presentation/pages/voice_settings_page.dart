import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/choice_row.dart';
import '../../../../core/widgets/section_title.dart';

class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  String _selectedVoice = 'Sarah (Principal Architect)';
  String _selectedAccent = 'English (US)';
  double _speechRate = 1.0;

  final List<Map<String, String>> _voices = [
    {
      'name': 'Sarah (Principal Architect)',
      'style': 'Professional, analytical & thorough',
    },
    {
      'name': 'Alex (Engineering Director)',
      'style': 'Practical, direct & product-oriented',
    },
    {
      'name': 'Elena (VP of Talent)',
      'style': 'Behavioral specialist, encouraging & structured',
    },
    {
      'name': 'David (System Design Lead)',
      'style': 'Deep architecture & scalability focus',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'AI Voice & Interviewer',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SectionTitle(title: 'Interviewer Persona'),
          Text(
            'Select the personality and vocal profile of your AI mock interviewer.',
            style: AppTypography.regular(12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 14),

          ..._voices.map((voice) {
            final name = voice['name']!;
            final isSelected = _selectedVoice == name;
            return ChoiceRow(
              label: name,
              detail: voice['style']!,
              icon: FeatherIcons.mic,
              selected: isSelected,
              onPress: () => setState(() => _selectedVoice = name),
            );
          }),

          const SectionTitle(title: 'Speech Rate'),
          Row(
            children: [0.8, 1.0, 1.2, 1.4].map((rate) {
              final isSelected = _speechRate == rate;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _speechRate = rate),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? colors.primary : colors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${rate}x',
                        style: AppTypography.semiBold(
                          12,
                          color: isSelected ? colors.primaryForeground : colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        
        ],
      ),
    );
  }
}
