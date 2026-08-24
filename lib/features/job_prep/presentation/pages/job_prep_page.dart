import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/controllers/interview_controller.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/job_prep_controller.dart';

class JobPrepPage extends StatefulWidget {
  const JobPrepPage({super.key});

  @override
  State<JobPrepPage> createState() => _JobPrepPageState();
}

class _JobPrepPageState extends State<JobPrepPage> {
  late TextEditingController _jdController;

  @override
  void initState() {
    super.initState();
    final jobPrepCtrl = context.read<JobPrepController>();
    _jdController = TextEditingController(text: jobPrepCtrl.jdText);
  }

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  void _analyze() {
    final resumeCtrl = context.read<ResumeController>();
    final jobPrepCtrl = context.read<JobPrepController>();
    jobPrepCtrl.updateJdText(_jdController.text);
    jobPrepCtrl.analyzeJobDescription(resumeCtrl.resume);
  }

  void _startTailoredInterview() {
    final jobPrepCtrl = context.read<JobPrepController>();
    final interviewCtrl = context.read<InterviewController>();
    final result = jobPrepCtrl.analysisResult;

    if (result != null) {
      interviewCtrl.updateConfig(
        role: result.jobTitle,
        company: result.companyName,
        difficulty: 'Adaptive',
        type: 'Technical + System Design',
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickInterviewSetupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final jobPrepCtrl = context.watch<JobPrepController>();
    final resumeCtrl = context.watch<ResumeController>();
    final activeResume = resumeCtrl.resume;

    final companies = jobPrepCtrl.companies;
    final selectedCompany = jobPrepCtrl.selectedCompany;
    final isAnalyzing = jobPrepCtrl.isAnalyzing;
    final result = jobPrepCtrl.analysisResult;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Prepare for a Job',
            subtitle: 'AI Job Description Analyzer',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.briefcase, size: 22, color: colors.navy),
                    ),
                    PillBadge(
                      label: 'Active: ${activeResume.name}',
                      tone: PillTone.success,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Practice for the role, not just the question.',
                  style: AppTypography.bold(20, color: Colors.white, height: 1.25),
                ),
                const SizedBox(height: 6),
                Text(
                  'We compare the JD requirements directly against your active resume to pinpoint skill gaps and simulate real hiring rounds.',
                  style: AppTypography.regular(11, color: const Color(0xFFBFCBE5), height: 1.5),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Target Company Profile'),

          // Company selector horizontal chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: companies.map((comp) {
                final isSelected = selectedCompany.id == comp.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => jobPrepCtrl.selectCompany(comp),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? colors.primary : colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            comp.icon,
                            size: 14,
                            color: isSelected ? colors.primaryForeground : colors.foreground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            comp.name,
                            style: AppTypography.semiBold(
                              12,
                              color: isSelected ? colors.primaryForeground : colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Company Interview Focus Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FeatherIcons.compass, size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${selectedCompany.name} Interview Priorities',
                      style: AppTypography.bold(12, color: colors.foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCompany.interviewFocus,
                  style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: selectedCompany.cultureTags
                      .map((tag) => PillBadge(label: tag, tone: PillTone.muted))
                      .toList(),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Job Description (JD)'),
          AppTextField(
            controller: _jdController,
            placeholder: 'Paste the target job description here…',
            multiline: true,
            minLines: 4,
            maxLines: 7,
          ),

          const SizedBox(height: 6),

          AppButton(
            label: isAnalyzing ? 'Analyzing JD & Matching Resume...' : 'Analyze JD Match & Skill Gaps',
            icon: isAnalyzing ? FeatherIcons.loader : FeatherIcons.zap,
            disabled: isAnalyzing,
            onPress: _analyze,
          ),

          if (result != null) ...[
            const SizedBox(height: 24),

            // Analysis Result Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.jobTitle,
                            style: AppTypography.bold(16, color: colors.foreground),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.companyName,
                            style: AppTypography.regular(11, color: colors.mutedForeground),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.mint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${result.matchScore}% Match',
                          style: AppTypography.bold(13, color: colors.mint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ProgressBar(value: result.matchScore.toDouble(), height: 6),
                  const SizedBox(height: 14),
                  Text(
                    result.summaryAssessment,
                    style: AppTypography.regular(11, color: colors.foreground, height: 1.5),
                  ),
                ],
              ),
            ),

            const SectionTitle(title: 'Matched Skills (On Your Resume)'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.matchedSkills
                  .map((s) => PillBadge(label: '✓ $s', tone: PillTone.success))
                  .toList(),
            ),

            const SectionTitle(title: 'Critical Skill Gaps (Focus Here)'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.skillGaps
                  .map((s) => PillBadge(label: '! $s', tone: PillTone.coral))
                  .toList(),
            ),

            const SectionTitle(title: 'Preparation Roadmap'),
            ...result.preparationRoadmap.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(FeatherIcons.arrowRight, size: 14, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: AppTypography.regular(12, color: colors.foreground, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SectionTitle(title: 'Tailored Interview Questions'),
            ...result.customQuestions.map((q) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(FeatherIcons.helpCircle, size: 14, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q,
                        style: AppTypography.regular(11, color: colors.foreground, height: 1.45),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            AppButton(
              label: 'Start Tailored Mock Interview',
              icon: FeatherIcons.arrowRight,
              onPress: _startTailoredInterview,
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
