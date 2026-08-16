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
import '../../domain/entities/resume_entity.dart';
import '../controllers/resume_controller.dart';

class ResumePage extends StatefulWidget {
  const ResumePage({super.key});

  @override
  State<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends State<ResumePage> {
  bool _pasteOpen = false;
  final _pasteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final resumeCtrl = context.watch<ResumeController>();
    final resume = resumeCtrl.resume;
    final isAnalyzing = resume.status == ResumeStatus.analyzing;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'My resume',
            onBack: () => Navigator.of(context).pop(),
            right: IconButton(
              icon: Icon(FeatherIcons.moreHorizontal, size: 20, color: colors.foreground),
              onPressed: () {},
            ),
          ),

          // Resume Card
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.mint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: isAnalyzing
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.navy),
                          ),
                        )
                      : Icon(FeatherIcons.fileText, size: 24, color: colors.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAnalyzing ? 'Analyzing your resume…' : resume.name,
                        style: AppTypography.semiBold(14, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAnalyzing ? 'Extracting skills and experience' : 'Updated 4 days ago · 1.2 MB',
                        style: AppTypography.regular(10, color: const Color(0xFFBFCBE5)),
                      ),
                      const SizedBox(height: 8),
                      PillBadge(
                        label: isAnalyzing ? 'Processing' : 'Default resume',
                        tone: PillTone.success,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isAnalyzing ? FeatherIcons.loader : FeatherIcons.checkCircle,
                  size: 19,
                  color: colors.mint,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          AppButton(
            label: 'Upload another resume',
            icon: FeatherIcons.uploadCloud,
            variant: ButtonVariant.secondary,
            onPress: () => resumeCtrl.simulateUpload(),
          ),

          const SectionTitle(title: 'Resume analysis', action: 'Edit'),

          // Analysis Metric Card
          Container(
            padding: const EdgeInsets.all(17),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume.experience,
                          style: AppTypography.bold(21, color: colors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Experience',
                          style: AppTypography.regular(10, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${resume.projects}',
                          style: AppTypography.bold(21, color: colors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Projects',
                          style: AppTypography.regular(10, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${resume.skills.length}',
                          style: AppTypography.bold(21, color: colors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Skills',
                          style: AppTypography.regular(10, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.border, thickness: 1),
                const SizedBox(height: 14),
                Text(
                  'Primary skills',
                  style: AppTypography.medium(11, color: colors.mutedForeground),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: resume.skills.map((skill) {
                    return PillBadge(label: skill, tone: PillTone.muted);
                  }).toList(),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Or paste your resume'),
          Text(
            'No file? Paste your resume text and we’ll use the same analysis.',
            style: AppTypography.regular(12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 12),

          if (_pasteOpen) ...[
            AppTextField(
              controller: _pasteController,
              placeholder: 'Paste your resume here…',
              multiline: true,
              minLines: 4,
              maxLines: 6,
            ),
            AppButton(
              label: 'Analyze pasted resume',
              icon: FeatherIcons.star,
              onPress: () {
                resumeCtrl.simulatePaste(_pasteController.text);
                setState(() => _pasteOpen = false);
              },
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _pasteOpen = true),
                borderRadius: BorderRadius.circular(17),
                child: Ink(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.clipboard, size: 18, color: colors.primary),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Paste resume text',
                          style: AppTypography.semiBold(13, color: colors.foreground),
                        ),
                      ),
                      Icon(FeatherIcons.chevronRight, size: 17, color: colors.mutedForeground),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
