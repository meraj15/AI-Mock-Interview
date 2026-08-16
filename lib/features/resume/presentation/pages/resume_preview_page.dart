import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/entities/resume_entity.dart';

class ResumePreviewPage extends StatelessWidget {
  final ResumeEntity resume;

  const ResumePreviewPage({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Parsed Resume',
            subtitle: resume.name,
            onBack: () => Navigator.of(context).pop(),
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
                    PillBadge(
                      label: resume.isDefault ? 'Active Default' : 'Saved Resume',
                      tone: PillTone.success,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  resume.name,
                  style: AppTypography.bold(17, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded ${resume.uploadedDate} · ${resume.fileSize}',
                  style: AppTypography.regular(11, color: const Color(0xFFBFCBE5)),
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
              resume.summary,
              style: AppTypography.regular(13, color: colors.foreground, height: 1.5),
            ),
          ),

          const SectionTitle(title: 'Extracted Skills & Tools'),
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
                Text('Core Languages & Skills', style: AppTypography.semiBold(12, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resume.skills.map((s) => PillBadge(label: s, tone: PillTone.success)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Frameworks & State Management', style: AppTypography.semiBold(12, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resume.frameworks.map((f) => PillBadge(label: f, tone: PillTone.muted)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Databases & Storage', style: AppTypography.semiBold(12, color: colors.mutedForeground)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resume.databases.map((db) => PillBadge(label: db, tone: PillTone.violet)).toList(),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Featured Projects'),
          ...resume.projectItems.map((project) {
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

          const SectionTitle(title: 'Education & Credentials'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
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
                        resume.education,
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
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
