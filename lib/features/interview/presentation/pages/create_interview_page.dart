import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/choice_row.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';

import '../../../resume/presentation/pages/resume_page.dart';
import '../controllers/interview_controller.dart';
import 'interview_session_page.dart';

class CreateInterviewPage extends StatefulWidget {
  const CreateInterviewPage({super.key});

  @override
  State<CreateInterviewPage> createState() => _CreateInterviewPageState();
}

class _CreateInterviewPageState extends State<CreateInterviewPage> {
  int _step = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'key': 'role',
      'title': 'Choose your role',
      'subtitle': 'What are you preparing for?',
      'options': [
        {'label': 'Flutter Developer', 'detail': 'Mobile Development · 1–3 years', 'icon': FeatherIcons.smartphone},
        {'label': 'React Developer', 'detail': 'Web Development · 1–3 years', 'icon': FeatherIcons.code},
        {'label': 'Product Designer', 'detail': 'Design · 2–5 years', 'icon': FeatherIcons.penTool},
      ],
    },
    {
      'key': 'company',
      'title': 'Choose a company',
      'subtitle': 'Optional context helps us set the tone.',
      'options': [
        {'label': 'General interview', 'detail': 'Practice transferable skills', 'icon': FeatherIcons.globe},
        {'label': 'Google', 'detail': 'Structured product thinking', 'icon': FeatherIcons.search},
        {'label': 'Startup', 'detail': 'Ownership and ambiguity', 'icon': FeatherIcons.zap},
        {'label': 'FinTech', 'detail': 'Trust, scale, and accuracy', 'icon': FeatherIcons.briefcase},
      ],
    },
    {
      'key': 'experience',
      'title': 'Set your experience',
      'subtitle': 'We’ll match the depth to your journey.',
      'options': [
        {'label': 'Use experience from resume', 'detail': 'Detected as 1.2 years', 'icon': FeatherIcons.fileText},
        {'label': '0–1 years', 'detail': 'Early career / fresher', 'icon': FeatherIcons.sunrise},
        {'label': '1–2 years', 'detail': 'Building strong foundations', 'icon': FeatherIcons.trendingUp},
        {'label': '3–5 years', 'detail': 'Experienced practitioner', 'icon': FeatherIcons.award},
      ],
    },
    {
      'key': 'difficulty',
      'title': 'Set the difficulty',
      'subtitle': 'How much should the session stretch you?',
      'options': [
        {'label': 'Adaptive', 'detail': 'Adjusts based on your answers', 'icon': FeatherIcons.sliders},
        {'label': 'Medium', 'detail': 'A balanced interview session', 'icon': FeatherIcons.minus},
        {'label': 'Hard', 'detail': 'Push me beyond the obvious', 'icon': FeatherIcons.zap},
      ],
    },
    {
      'key': 'type',
      'title': 'Choose interview type',
      'subtitle': 'What would you like to practice?',
      'options': [
        {'label': 'Technical interview', 'detail': 'Role knowledge and problem solving', 'icon': FeatherIcons.cpu},
        {'label': 'Behavioral interview', 'detail': 'Stories, impact, and communication', 'icon': FeatherIcons.messageCircle},
        {'label': 'Full mock interview', 'detail': 'A realistic mix of everything', 'icon': FeatherIcons.layers},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final resumeCtrl = context.watch<ResumeController>();

    final isReview = _step == _steps.length;
    final current = isReview ? null : _steps[_step];
    final totalSteps = _steps.length + 1;
    final currentStepNum = _step + 1;

    String selectedValue = '';
    if (!isReview && current != null) {
      final key = current['key'] as String;
      if (key == 'role') selectedValue = interviewCtrl.config.role;
      if (key == 'company') selectedValue = interviewCtrl.config.company;
      if (key == 'experience') selectedValue = interviewCtrl.config.experience;
      if (key == 'difficulty') selectedValue = interviewCtrl.config.difficulty;
      if (key == 'type') selectedValue = interviewCtrl.config.type;
    }

    void onSelect(String value) {
      final key = current!['key'] as String;
      if (key == 'role') interviewCtrl.updateConfig(role: value);
      if (key == 'company') interviewCtrl.updateConfig(company: value);
      if (key == 'experience') interviewCtrl.updateConfig(experience: value);
      if (key == 'difficulty') interviewCtrl.updateConfig(difficulty: value);
      if (key == 'type') interviewCtrl.updateConfig(type: value);
    }

    void next() {
      if (_step < _steps.length) {
        setState(() => _step++);
      } else {
        interviewCtrl.startInterview();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InterviewSessionPage()),
        );
      }
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'New interview',
            subtitle: 'Step $currentStepNum of $totalSteps',
            onBack: () {
              if (_step > 0) {
                setState(() => _step--);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),

          // Progress Track
          ProgressBar(
            value: (currentStepNum / totalSteps) * 100,
            height: 6,
          ),

          const SizedBox(height: 24),


          // Eyebrow & Title
          Text(
            'SETUP YOUR SESSION',
            style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4),
          ),
          const SizedBox(height: 11),
          Text(
            isReview ? 'Review your session' : current!['title'] as String,
            style: AppTypography.bold(28, color: colors.foreground),
          ),
          const SizedBox(height: 7),
          Text(
            isReview
                ? 'Everything looks good? Let’s make this a useful rep.'
                : current!['subtitle'] as String,
            style: AppTypography.regular(13, color: colors.mutedForeground),
          ),

          const SizedBox(height: 20),

          // Options or Review Summary
          if (!isReview && current != null) ...[
            ...(current['options'] as List<Map<String, dynamic>>).map((opt) {
              final label = opt['label'] as String;
              final detail = opt['detail'] as String;
              final icon = opt['icon'] as IconData;
              return ChoiceRow(
                label: label,
                detail: detail,
                icon: icon,
                selected: selectedValue == label,
                onPress: () => onSelect(label),
              );
            }),
            if (_step == 0) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ResumePage()),
                  );
                },
                child: Row(
                  children: [
                    Icon(FeatherIcons.uploadCloud, size: 15, color: colors.primary),
                    const SizedBox(width: 7),
                    Text(
                      'Choose a different resume',
                      style: AppTypography.semiBold(12, color: colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Review Session Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SESSION SUMMARY',
                        style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.2),
                      ),
                      const PillBadge(label: 'Ready to start', tone: PillTone.success),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    interviewCtrl.config.role,
                    style: AppTypography.bold(18, color: colors.foreground),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${interviewCtrl.config.company} · ${interviewCtrl.config.experience} · ${interviewCtrl.config.difficulty}',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${interviewCtrl.config.type} · ${interviewCtrl.config.questions} questions · about 20 min',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 13),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ResumePage()),
                      );
                    },
                    child: Text(
                      'Using ${resumeCtrl.resume.name} · Change',
                      style: AppTypography.semiBold(11, color: colors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            Text(
              'Session length',
              style: AppTypography.bold(14, color: colors.foreground),
            ),
            const SizedBox(height: 10),

            Row(
              children: [5, 10, 15].map((len) {
                final isSelected = interviewCtrl.config.questions == len;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => interviewCtrl.updateConfig(questions: len),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.card,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isSelected ? colors.primary : colors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$len',
                              style: AppTypography.bold(
                                18,
                                color: isSelected ? colors.primaryForeground : colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'questions',
                              style: AppTypography.regular(
                                9,
                                color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 32),

          AppButton(
            label: isReview ? 'Start interview' : 'Continue',
            icon: FeatherIcons.arrowRight,
            onPress: next,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
