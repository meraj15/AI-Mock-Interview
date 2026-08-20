import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/entities/resume_entity.dart';
import '../controllers/resume_controller.dart';
import '../../../../features/onboarding/presentation/pages/profile_ready_page.dart';

class EditParsedResumePage extends StatefulWidget {
  final ResumeEntity resume;

  const EditParsedResumePage({super.key, required this.resume});

  @override
  State<EditParsedResumePage> createState() => _EditParsedResumePageState();
}

class _EditParsedResumePageState extends State<EditParsedResumePage> {
  late TextEditingController _nameController;
  late TextEditingController _summaryController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;
  late TextEditingController _newSkillController;

  late List<String> _skills;
  late List<ResumeProjectItem> _projects;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.resume.candidateName);
    _summaryController = TextEditingController(text: widget.resume.summary);
    _experienceController = TextEditingController(text: widget.resume.experience);
    _educationController = TextEditingController(text: widget.resume.education);
    _newSkillController = TextEditingController();

    _skills = List<String>.from(widget.resume.skills);
    _projects = List<ResumeProjectItem>.from(widget.resume.projectItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _newSkillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _newSkillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _save() {
    final updated = widget.resume.copyWith(
      candidateName: _nameController.text.trim(),
      summary: _summaryController.text.trim(),
      experience: _experienceController.text.trim(),
      education: _educationController.text.trim(),
      skills: _skills,
      projectItems: _projects,
    );

    context.read<ResumeController>().updateResume(updated);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileReadyPage(
          name: updated.candidateName,
          role: updated.skills.isNotEmpty ? updated.skills.first : 'Developer',
          experience: updated.experience,
          skills: updated.skills,
          isFromResume: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Verify Parsed Data',
            subtitle: 'Fine-tune extracted fields',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          // Confidence Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.mint.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.checkCircle, size: 18, color: colors.mint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Parser extraction confidence: ${widget.resume.confidenceScore}%. Review and edit below.',
                    style: AppTypography.semiBold(11, color: colors.foreground),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Candidate Name & Summary'),
          Text('Candidate Name', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            placeholder: 'Candidate full name',
          ),

          Text('Professional Summary', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _summaryController,
            placeholder: 'Professional summary',
            multiline: true,
            minLines: 3,
            maxLines: 5,
          ),

          const SectionTitle(title: 'Experience & Education'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Experience', style: AppTypography.semiBold(12, color: colors.foreground)),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _experienceController,
                      placeholder: 'e.g. 1.5 years',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Education', style: AppTypography.semiBold(12, color: colors.foreground)),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _educationController,
                      placeholder: 'e.g. B.Sc in CS',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SectionTitle(title: 'Extracted Skills'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _skills.map((skill) {
              return Chip(
                backgroundColor: colors.secondary,
                label: Text(
                  skill,
                  style: AppTypography.semiBold(11, color: colors.foreground),
                ),
                deleteIcon: Icon(FeatherIcons.x, size: 13, color: colors.mutedForeground),
                onDeleted: () => _removeSkill(skill),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: colors.border),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Add skill row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _newSkillController,
                  placeholder: 'Add new skill (e.g. GraphQL, Docker)',
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: IconButton(
                  onPressed: _addSkill,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: Icon(FeatherIcons.plus, size: 18, color: colors.primaryForeground),
                ),
              ),
            ],
          ),

          const SectionTitle(title: 'Extracted Projects'),
          ..._projects.asMap().entries.map((entry) {
            final idx = entry.key;
            final proj = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
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
                      Text(proj.title, style: AppTypography.bold(14, color: colors.foreground)),
                      IconButton(
                        icon: Icon(FeatherIcons.trash2, size: 15, color: colors.destructive),
                        onPressed: () {
                          setState(() => _projects.removeAt(idx));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proj.description,
                    style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                  ),
                  if (proj.metricAchievement != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Metric: ${proj.metricAchievement!}',
                      style: AppTypography.semiBold(10, color: colors.primary),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          AppButton(
            label: 'Save & Confirm Profile',
            icon: FeatherIcons.check,
            onPress: _save,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
