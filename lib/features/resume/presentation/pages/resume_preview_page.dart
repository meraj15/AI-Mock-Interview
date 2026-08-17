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
import '../../domain/entities/resume_entity.dart';
import '../controllers/resume_controller.dart';
import 'edit_parsed_resume_page.dart';

class ResumePreviewPage extends StatelessWidget {
  final ResumeEntity resume;

  const ResumePreviewPage({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final resumeCtrl = context.watch<ResumeController>();
    final currentResume = resumeCtrl.resumes.firstWhere(
      (r) => r.id == resume.id,
      orElse: () => resume,
    );

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Parsed Resume',
            subtitle: currentResume.name,
            onBack: () => Navigator.of(context).pop(),
            right: IconButton(
              icon: Icon(FeatherIcons.edit2, size: 18, color: colors.foreground),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditParsedResumePage(resume: currentResume),
                  ),
                );
              },
            ),
          ),

          // Top Resume Banner
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.fileText, color: colors.navy, size: 22),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.mint.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${currentResume.confidenceScore}% Confidence',
                            style: AppTypography.semiBold(9, color: colors.mint),
                          ),
                        ),
                        const SizedBox(width: 6),
                        PillBadge(
                          label: currentResume.isDefault ? 'Active Default' : 'Saved',
                          tone: PillTone.success,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  currentResume.candidateName,
                  style: AppTypography.bold(20, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentResume.email} · ${currentResume.phone}',
                  style: AppTypography.regular(11, color: const Color(0xFFBFCBE5)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded ${currentResume.uploadedDate} · ${currentResume.fileSize}',
                  style: AppTypography.regular(10, color: const Color(0xFF8E9BB5)),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Professional Summary'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              currentResume.summary,
              style: AppTypography.regular(13, color: colors.foreground, height: 1.5),
            ),
          ),

          const SectionTitle(title: 'Extracted Skills & Domains'),
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
                Text('Programming Languages', style: AppTypography.semiBold(11, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: currentResume.languages.map((l) => PillBadge(label: l, tone: PillTone.success)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Frameworks & State Management', style: AppTypography.semiBold(11, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: currentResume.frameworks.map((f) => PillBadge(label: f, tone: PillTone.muted)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Databases & Cloud Architecture', style: AppTypography.semiBold(11, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: currentResume.databases.map((db) => PillBadge(label: db, tone: PillTone.violet)).toList(),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Work Experience History'),
          ...currentResume.workExperiences.map((work) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      Text(work.company, style: AppTypography.bold(14, color: colors.foreground)),
                      Text(work.duration, style: AppTypography.regular(10, color: colors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(work.role, style: AppTypography.semiBold(12, color: colors.primary)),
                  const SizedBox(height: 8),
                  ...work.responsibilities.map((resp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: AppTypography.bold(12, color: colors.mutedForeground)),
                          Expanded(
                            child: Text(
                              resp,
                              style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: work.technologiesUsed.map((t) => PillBadge(label: t, tone: PillTone.muted)).toList(),
                  ),
                ],
              ),
            );
          }),

          const SectionTitle(title: 'Featured Projects & Metrics'),
          ...currentResume.projectItems.map((project) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        project.title,
                        style: AppTypography.bold(14, color: colors.foreground),
                      ),
                      PillBadge(label: project.role, tone: PillTone.coral),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                  ),
                  if (project.metricAchievement != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(FeatherIcons.trendingUp, size: 14, color: colors.mint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            project.metricAchievement!,
                            style: AppTypography.semiBold(10, color: colors.foreground),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: project.techStack.map((tech) => PillBadge(label: tech, tone: PillTone.muted)).toList(),
                  ),
                ],
              ),
            );
          }),

          const SectionTitle(title: 'Education & Certifications'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.award, size: 18, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentResume.education,
                            style: AppTypography.bold(13, color: colors.foreground),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified Degree & Credentials',
                            style: AppTypography.regular(10, color: colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (currentResume.certifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: colors.border, thickness: 1),
                  const SizedBox(height: 8),
                  ...currentResume.certifications.map((cert) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cert.name, style: AppTypography.semiBold(12, color: colors.foreground)),
                          Text('${cert.issuer} · ${cert.issueYear}', style: AppTypography.regular(10, color: colors.mutedForeground)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Edit Parsed Data',
                  variant: ButtonVariant.secondary,
                  icon: FeatherIcons.edit3,
                  onPress: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditParsedResumePage(resume: currentResume),
                      ),
                    );
                  },
                ),
              ),
              if (!currentResume.isDefault) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Set as Active',
                    icon: FeatherIcons.check,
                    onPress: () {
                      resumeCtrl.setActiveResume(currentResume.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Active default resume updated!')),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
