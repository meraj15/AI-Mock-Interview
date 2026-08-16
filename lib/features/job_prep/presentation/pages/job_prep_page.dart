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
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/controllers/interview_controller.dart';
import '../../../interview/presentation/pages/create_interview_page.dart';

class JobPrepPage extends StatefulWidget {
  const JobPrepPage({super.key});

  @override
  State<JobPrepPage> createState() => _JobPrepPageState();
}

class _JobPrepPageState extends State<JobPrepPage> {
  String _company = 'Google';
  final _jdController = TextEditingController(
    text: 'We are looking for a Flutter engineer to build reliable, delightful mobile experiences. You will work with Dart, Firebase, REST APIs, and a cross-functional product team.',
  );
  bool _analyzing = false;
  bool _analyzed = false;

  void _analyze() async {
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _analyzing = false;
        _analyzed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.read<InterviewController>();

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Prepare for a job',
            subtitle: 'Turn a job description into a plan',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Hero
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
                const SizedBox(height: 14),
                Text(
                  'Practice for the role, not just the question.',
                  style: AppTypography.bold(22, color: Colors.white, height: 1.22),
                ),
                const SizedBox(height: 8),
                Text(
                  'We’ll compare the role requirements with your resume and highlight the gaps worth practicing.',
                  style: AppTypography.regular(11, color: const Color(0xFFBFCBE5), height: 1.5),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Target company'),

          // Company selector
          Row(
            children: ['Google', 'Microsoft', 'Startup'].map((item) {
              final isSelected = _company == item;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _company = item),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : colors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? colors.primary : colors.border),
                    ),
                    child: Text(
                      item,
                      style: AppTypography.semiBold(
                        12,
                        color: isSelected ? colors.primaryForeground : colors.foreground,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SectionTitle(title: 'Job description'),
          Text(
            'Paste the role you’re targeting. This mock flow uses local sample analysis.',
            style: AppTypography.regular(11, color: colors.mutedForeground),
          ),
          const SizedBox(height: 10),

          AppTextField(
            controller: _jdController,
            placeholder: 'Paste a job description…',
            multiline: true,
            minLines: 4,
            maxLines: 6,
          ),

          if (_analyzing) ...[
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analyzing role requirements…',
                    style: AppTypography.semiBold(12, color: colors.foreground),
                  ),
                ],
              ),
            ),
          ] else ...[
            AppButton(
              label: _analyzed ? 'Re-analyze job description' : 'Analyze job description',
              icon: FeatherIcons.search,
              onPress: _analyze,
            ),
          ],

          if (_analyzed) ...[
            const SectionTitle(title: 'Role snapshot'),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flutter Engineer',
                        style: AppTypography.bold(16, color: colors.foreground),
                      ),
                      const PillBadge(label: 'Good match', tone: PillTone.success),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your resume matches 4 of 6 core skills for this role.',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      const PillBadge(label: 'Flutter', tone: PillTone.success),
                      const PillBadge(label: 'Dart', tone: PillTone.success),
                      const PillBadge(label: 'Firebase', tone: PillTone.success),
                      const PillBadge(label: 'REST APIs', tone: PillTone.success),
                      const PillBadge(label: 'Clean Architecture · gap', tone: PillTone.coral),
                      const PillBadge(label: 'Testing · gap', tone: PillTone.coral),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Gap recommendation box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(FeatherIcons.compass, size: 16, color: colors.primary),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended focus',
                                style: AppTypography.semiBold(11, color: colors.foreground),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Practice Clean Architecture before your next interview.',
                                style: AppTypography.regular(10, color: colors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppButton(
                    label: 'Practice this role',
                    icon: FeatherIcons.arrowRight,
                    onPress: () {
                      interviewCtrl.updateConfig(role: 'Flutter Developer', company: _company);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateInterviewPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          Center(
            child: InkWell(
              onTap: () => setState(() => _analyzed = false),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.upload, size: 14, color: colors.primary),
                  const SizedBox(width: 7),
                  Text(
                    'Upload a job description instead',
                    style: AppTypography.semiBold(11, color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
