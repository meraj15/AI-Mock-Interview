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
import '../../domain/entities/job_role_entity.dart';
import '../controllers/interview_controller.dart';
import 'interview_config_page.dart';

class CreateInterviewPage extends StatefulWidget {
  const CreateInterviewPage({super.key});

  @override
  State<CreateInterviewPage> createState() => _CreateInterviewPageState();
}

class _CreateInterviewPageState extends State<CreateInterviewPage> {
  int _step = 0;
  String _roleSearchQuery = '';
  String _selectedCategory = 'Mobile Development';

  final List<String> _companies = [
    'General interview',
    'Google',
    'Microsoft',
    'Amazon',
    'Startup',
    'FinTech',
    'TCS / Infosys',
    'Healthcare',
  ];

  final List<Map<String, dynamic>> _experienceOptions = [
    {'label': 'Use experience from resume', 'detail': 'Auto-detected from active resume', 'icon': FeatherIcons.fileText},
    {'label': 'Fresher / Early Career', 'detail': '0–1 years · Foundations & potential', 'icon': FeatherIcons.sunrise},
    {'label': '1–2 years', 'detail': 'Hands-on problem solving & clean code', 'icon': FeatherIcons.trendingUp},
    {'label': '3–5 years', 'detail': 'Practitioner · Architecture & trade-offs', 'icon': FeatherIcons.award},
    {'label': '5–8+ years', 'detail': 'Senior / Lead · System design & leadership', 'icon': FeatherIcons.zap},
  ];

  final List<Map<String, dynamic>> _difficultyOptions = [
    {'label': 'Adaptive', 'detail': 'Dynamically adjusts based on your answer depth', 'icon': FeatherIcons.sliders},
    {'label': 'Easy', 'detail': 'Friendly pace to build confidence', 'icon': FeatherIcons.checkCircle},
    {'label': 'Medium', 'detail': 'Realistic industry interview standard', 'icon': FeatherIcons.minus},
    {'label': 'Hard', 'detail': 'Edge cases, deep architecture & stress testing', 'icon': FeatherIcons.zap},
  ];

  final List<Map<String, dynamic>> _typeOptions = [
    {'label': 'Technical interview', 'detail': 'Role mastery, API design & problem solving', 'icon': FeatherIcons.cpu},
    {'label': 'Behavioral interview', 'detail': 'STAR stories, conflict resolution & teamwork', 'icon': FeatherIcons.messageCircle},
    {'label': 'System design & architecture', 'detail': 'Scalability, reliability, and trade-offs', 'icon': FeatherIcons.share2},
    {'label': 'Full mock interview', 'detail': 'A complete 360° realistic mix of all categories', 'icon': FeatherIcons.layers},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final resumeCtrl = context.watch<ResumeController>();

    const totalSteps = 6;
    final currentStepNum = _step + 1;

    final categories = JobCategoryEntity.defaultCategories;

    List<JobRoleEntity> allRoles = [];
    for (var cat in categories) {
      allRoles.addAll(cat.roles);
    }

    final filteredRoles = _roleSearchQuery.isEmpty
        ? categories.firstWhere((c) => c.name == _selectedCategory, orElse: () => categories.first).roles
        : allRoles.where((r) => r.title.toLowerCase().contains(_roleSearchQuery.toLowerCase())).toList();

    void next() {
      if (_step < totalSteps - 1) {
        setState(() => _step++);
      } else {
        // Phase 5: Deep config before starting session
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InterviewConfigPage()),
        );
      }
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'New Interview',
            subtitle: 'Step $currentStepNum of $totalSteps',
            onBack: () {
              if (_step > 0) {
                setState(() => _step--);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),

          // Progress Bar
          ProgressBar(
            value: (currentStepNum / totalSteps) * 100,
            height: 6,
          ),

          const SizedBox(height: 20),

          // STEP 0: CHOOSE RESUME
          if (_step == 0) ...[
            Text('STEP 1 · RESUME CONTEXT', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Select your resume', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('The AI will ground its questions on your actual experience and projects.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 18),

            ...resumeCtrl.resumes.map((res) {
              final isSelected = res.id == resumeCtrl.resume.id;
              return ChoiceRow(
                label: res.name,
                detail: '${res.experience} · ${res.skills.take(3).join(", ")}',
                icon: FeatherIcons.fileText,
                selected: isSelected,
                onPress: () => resumeCtrl.setActiveResume(res.id),
              );
            }),

            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResumePage()),
                );
              },
              child: Row(
                children: [
                  Icon(FeatherIcons.plusCircle, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Upload or manage other resumes', style: AppTypography.semiBold(12, color: colors.primary)),
                ],
              ),
            ),
          ],

          // STEP 1: CHOOSE ROLE & CATEGORY (WITH SEARCH)
          if (_step == 1) ...[
            Text('STEP 2 · TARGET ROLE', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Choose your role', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('Search or pick from dynamic engineering categories.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colors.input),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _roleSearchQuery = val),
                style: AppTypography.regular(14, color: colors.foreground),
                decoration: InputDecoration(
                  hintText: 'Search roles (e.g. Flutter, Node, AI)...',
                  hintStyle: AppTypography.regular(13, color: colors.mutedForeground),
                  prefixIcon: Icon(FeatherIcons.search, size: 18, color: colors.mutedForeground),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (_roleSearchQuery.isEmpty) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isCatSelected = _selectedCategory == cat.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat.name),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCatSelected ? colors.primary : colors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat.name,
                            style: AppTypography.semiBold(
                              11,
                              color: isCatSelected ? colors.primaryForeground : colors.secondaryForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            ...filteredRoles.map((role) {
              final isSelected = interviewCtrl.config.role == role.title;
              return ChoiceRow(
                label: role.title,
                detail: '${role.category} · ${role.defaultExperience}',
                icon: FeatherIcons.code,
                selected: isSelected,
                onPress: () => interviewCtrl.updateConfig(role: role.title),
              );
            }),
          ],

          // STEP 2: SET EXPERIENCE
          if (_step == 2) ...[
            Text('STEP 3 · EXPERIENCE DEPTH', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Set your experience level', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('We match the scenario complexity to your career stage.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 18),

            ..._experienceOptions.map((opt) {
              final label = opt['label'] as String;
              final detail = opt['detail'] as String;
              final icon = opt['icon'] as IconData;
              final isSelected = interviewCtrl.config.experience == label ||
                  (label.startsWith('Use experience') && interviewCtrl.config.experience.contains('resume'));
              return ChoiceRow(
                label: label,
                detail: detail,
                icon: icon,
                selected: isSelected,
                onPress: () => interviewCtrl.updateConfig(experience: label),
              );
            }),
          ],

          // STEP 3: COMPANY & INDUSTRY CONTEXT
          if (_step == 3) ...[
            Text('STEP 4 · COMPANY CONTEXT', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Target company or industry', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('AI will adapt the style and problem framing to this company profile.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 18),

            ..._companies.map((comp) {
              final isSelected = interviewCtrl.config.company == comp;
              return ChoiceRow(
                label: comp,
                detail: comp == 'Google'
                    ? 'Structured product thinking & edge cases'
                    : comp == 'Startup'
                        ? 'Ambiguity, ownership, and rapid iteration'
                        : comp == 'FinTech'
                            ? 'High reliability, scale, and accuracy'
                            : 'Transferable core engineering principles',
                icon: FeatherIcons.briefcase,
                selected: isSelected,
                onPress: () => interviewCtrl.updateConfig(company: comp),
              );
            }),
          ],

          // STEP 4: DIFFICULTY & INTERVIEW TYPE
          if (_step == 4) ...[
            Text('STEP 5 · SESSION FORMAT', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Difficulty & interview type', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('Select how challenging and focused this mock interview should be.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 18),

            Text('Difficulty level', style: AppTypography.bold(14, color: colors.foreground)),
            const SizedBox(height: 10),
            ..._difficultyOptions.map((diff) {
              final label = diff['label'] as String;
              final isSelected = interviewCtrl.config.difficulty == label;
              return ChoiceRow(
                label: label,
                detail: diff['detail'] as String,
                icon: diff['icon'] as IconData,
                selected: isSelected,
                onPress: () => interviewCtrl.updateConfig(difficulty: label),
              );
            }),

            const SizedBox(height: 16),
            Text('Interview type', style: AppTypography.bold(14, color: colors.foreground)),
            const SizedBox(height: 10),
            ..._typeOptions.map((type) {
              final label = type['label'] as String;
              final isSelected = interviewCtrl.config.type == label;
              return ChoiceRow(
                label: label,
                detail: type['detail'] as String,
                icon: type['icon'] as IconData,
                selected: isSelected,
                onPress: () => interviewCtrl.updateConfig(type: label),
              );
            }),
          ],

          // STEP 5: REVIEW & SESSION LENGTH
          if (_step == 5) ...[
            Text('STEP 6 · FINAL REVIEW & CONFIG', style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text('Review your session', style: AppTypography.bold(26, color: colors.foreground)),
            const SizedBox(height: 6),
            Text('Everything looks good? Let’s make this a high-impact prep session.', style: AppTypography.regular(13, color: colors.mutedForeground)),
            const SizedBox(height: 18),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SESSION SUMMARY', style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.2)),
                      const PillBadge(label: 'Ready to launch', tone: PillTone.success),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(interviewCtrl.config.role, style: AppTypography.bold(18, color: colors.foreground)),
                  const SizedBox(height: 4),
                  Text('${interviewCtrl.config.company} · ${interviewCtrl.config.experience} · ${interviewCtrl.config.difficulty}', style: AppTypography.regular(11, color: colors.mutedForeground)),
                  const SizedBox(height: 4),
                  Text('${interviewCtrl.config.type} · ${interviewCtrl.config.questions} questions (~${interviewCtrl.config.questions * 2} min)', style: AppTypography.regular(11, color: colors.mutedForeground)),
                  const SizedBox(height: 12),
                  Text('Grounding on: ${resumeCtrl.resume.name}', style: AppTypography.semiBold(11, color: colors.primary)),
                ],
              ),
            ),

            const SizedBox(height: 22),
            Text('Session question count', style: AppTypography.bold(14, color: colors.foreground)),
            const SizedBox(height: 10),

            Row(
              children: [5, 10, 15, 20].map((len) {
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
                              style: AppTypography.bold(18, color: isSelected ? colors.primaryForeground : colors.foreground),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'questions',
                              style: AppTypography.regular(9, color: isSelected ? colors.primaryForeground : colors.mutedForeground),
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
            label: _step == totalSteps - 1 ? 'Advanced Config & Start →' : 'Continue',
            icon: _step == totalSteps - 1 ? FeatherIcons.sliders : FeatherIcons.arrowRight,
            onPress: next,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
