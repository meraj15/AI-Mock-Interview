import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../controllers/resume_controller.dart';
import 'resume_preview_page.dart';
import 'resume_upload_page.dart';

class ResumePage extends StatelessWidget {
  const ResumePage({super.key});

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
            subtitle: resumes.isEmpty
                ? 'No resumes uploaded'
                : '${resumes.length} resume${resumes.length == 1 ? '' : 's'} managed',
            onBack: () => Navigator.of(context).pop(),
            right: IconButton(
              icon: Icon(FeatherIcons.plus, size: 20, color: colors.foreground),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          if (resumes.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.fileText, size: 28, color: colors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Resumes Uploaded Yet',
                    style: AppTypography.bold(16, color: colors.foreground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload your resume in PDF/DOC format to automatically extract your skills, experience, and tailor your mock interviews.',
                    style: AppTypography.regular(12, color: colors.mutedForeground, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Upload & Parse Resume',
                    icon: FeatherIcons.uploadCloud,
                    onPress: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            // Multi-Resume List
            ...resumes.map((item) {
              final isSelected = activeResume != null && item.id == activeResume.id;

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
                          child: Icon(
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
                                item.name,
                                style: AppTypography.bold(
                                  14,
                                  color: isSelected ? Colors.white : colors.foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.uploadedDate} · ${item.fileSize}',
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
                    const SizedBox(height: 12),
                    Divider(color: isSelected ? Colors.white.withValues(alpha: 0.15) : colors.border, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResumePreviewPage(resume: item),
                              ),
                            );
                          },
                          icon: Icon(FeatherIcons.eye, size: 14, color: isSelected ? colors.mint : colors.primary),
                          label: Text(
                            'View Details',
                            style: AppTypography.semiBold(
                              11.5,
                              color: isSelected ? colors.mint : colors.primary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (!isSelected)
                              IconButton(
                                icon: Icon(FeatherIcons.checkCircle, size: 16, color: colors.mutedForeground),
                                onPressed: () => resumeCtrl.setActiveResume(item.id),
                                tooltip: 'Set as Active Default',
                              ),
                            IconButton(
                              icon: Icon(FeatherIcons.refreshCw, size: 15, color: colors.mutedForeground),
                              tooltip: 'Replace Resume',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResumeUploadPage(
                                      isReplacing: true,
                                      replaceId: item.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(FeatherIcons.trash2, size: 15, color: colors.destructive),
                              tooltip: 'Delete Resume',
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
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            AppButton(
              label: 'Upload & Parse New Resume',
              icon: FeatherIcons.uploadCloud,
              variant: ButtonVariant.secondary,
              onPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
                );
              },
            ),

            if (activeResume != null) ...[
              const SectionTitle(title: 'Active Resume Summary', action: 'Verify Data'),

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
                            Text(activeResume.experience.isNotEmpty ? activeResume.experience : '—', style: AppTypography.bold(21, color: colors.foreground)),
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
                    if (activeResume.skills.isNotEmpty) ...[
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
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
