import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/entities/resume_entity.dart';
import '../controllers/resume_controller.dart';
import 'resume_preview_page.dart';

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
    final resumes = resumeCtrl.resumes;
    final activeResume = resumeCtrl.resume;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'My Resumes',
            subtitle: '${resumes.length} resumes managed',
            onBack: () => Navigator.of(context).pop(),
            right: IconButton(
              icon: Icon(FeatherIcons.plus, size: 20, color: colors.foreground),
              onPressed: () => resumeCtrl.simulateUpload(),
            ),
          ),

          const SizedBox(height: 8),

          // Multi-Resume List
          ...resumes.map((item) {
            final isAnalyzing = item.status == ResumeStatus.analyzing;
            final isSelected = item.id == activeResume.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? colors.navy : colors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? colors.navy : colors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.mint : colors.secondary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: isAnalyzing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? colors.navy : colors.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                FeatherIcons.fileText,
                                size: 22,
                                color: isSelected ? colors.navy : colors.primary,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAnalyzing ? 'Analyzing resume…' : item.name,
                              style: AppTypography.bold(
                                14,
                                color: isSelected ? Colors.white : colors.foreground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isAnalyzing ? 'Extracting skills...' : '${item.uploadedDate} · ${item.fileSize}',
                              style: AppTypography.regular(
                                10,
                                color: isSelected ? const Color(0xFFBFCBE5) : colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PillBadge(
                        label: isSelected ? 'Active Default' : 'Saved',
                        tone: isSelected ? PillTone.success : PillTone.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResumePreviewPage(resume: item),
                              ),
                            );
                          },
                          icon: Icon(
                            FeatherIcons.eye,
                            size: 14,
                            color: isSelected ? Colors.white : colors.foreground,
                          ),
                          label: Text(
                            'Preview',
                            style: AppTypography.semiBold(
                              11,
                              color: isSelected ? Colors.white : colors.foreground,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isSelected ? Colors.white.withValues(alpha: 0.3) : colors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSelected) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => resumeCtrl.setActiveResume(item.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                            ),
                            child: Text(
                              'Set Active',
                              style: AppTypography.semiBold(11, color: colors.primaryForeground),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(FeatherIcons.trash2, size: 16, color: colors.destructive),
                          onPressed: () async {
                            final confirm = await ConfirmationDialog.show(
                              context,
                              title: 'Delete Resume',
                              message: 'Are you sure you want to remove ${item.name}?',
                              confirmLabel: 'Delete',
                              isDestructive: true,
                            );
                            if (confirm == true) {
                              resumeCtrl.deleteResume(item.id);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          AppButton(
            label: 'Upload new resume (PDF/DOCX)',
            icon: FeatherIcons.uploadCloud,
            variant: ButtonVariant.secondary,
            onPress: () => resumeCtrl.simulateUpload(),
          ),

          const SectionTitle(title: 'Active Resume Summary', action: 'Full Preview'),

          // Quick metrics of active resume
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
                        Text(activeResume.experience, style: AppTypography.bold(21, color: colors.foreground)),
                        const SizedBox(height: 2),
                        Text('Experience', style: AppTypography.regular(10, color: colors.mutedForeground)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${activeResume.projects}', style: AppTypography.bold(21, color: colors.foreground)),
                        const SizedBox(height: 2),
                        Text('Projects', style: AppTypography.regular(10, color: colors.mutedForeground)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${activeResume.skills.length}', style: AppTypography.bold(21, color: colors.foreground)),
                        const SizedBox(height: 2),
                        Text('Core Skills', style: AppTypography.regular(10, color: colors.mutedForeground)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.border, thickness: 1),
                const SizedBox(height: 12),
                Text('Primary matched skills', style: AppTypography.medium(11, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: activeResume.skills.map((s) => PillBadge(label: s, tone: PillTone.muted)).toList(),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Or Paste Resume Manually'),
          Text(
            'No file on hand? Paste your resume text and our parser will structure it into the same profile format.',
            style: AppTypography.regular(12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 12),

          if (_pasteOpen) ...[
            AppTextField(
              controller: _pasteController,
              placeholder: 'Paste your resume content, experience, and projects here…',
              multiline: true,
              minLines: 4,
              maxLines: 6,
            ),
            AppButton(
              label: 'Parse and Save Resume',
              icon: FeatherIcons.check,
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
