import 'package:feather_icons/feather_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/auth_controller.dart';

/// Compact, job-portal style Profile Setup screen.
///
/// Designed to minimize scrolling, maximize visual clarity, and provide
/// a first-class experience for entering Target Role(s), adding Skills via
/// authentic removable chips, and setting Experience Level.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _roleCtrl = TextEditingController();
  final _skillInputCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _projectsCtrl = TextEditingController();
  final _skillFocusNode = FocusNode();

  final List<String> _skills = [];
  String _selectedExpLabel = '1–3 yrs';
  double _selectedExpYears = 2.0;
  bool _showAdditional = false;
  bool _isUploadingResume = false;
  String? _errorMessage;

  static const List<String> _popularRoles = [
    'Flutter Developer',
    'Frontend Engineer',
    'Backend Engineer',
    'Full Stack Developer',
    'Mobile Developer',
    'DevOps Engineer',
    'AI / ML Engineer',
    'Product Manager',
    'Data Scientist',
    'QA Engineer',
  ];

  static const List<String> _suggestedSkills = [
    'Flutter',
    'Dart',
    'React',
    'Node.js',
    'Python',
    'TypeScript',
    'PostgreSQL',
    'Docker',
    'AWS',
    'REST APIs',
    'System Design',
    'Git',
    'SQL',
    'MongoDB',
    'GraphQL',
  ];

  static const List<({String label, double years})> _expOptions = [
    (label: 'Fresher (< 1y)', years: 0.5),
    (label: '1–3 yrs', years: 2.0),
    (label: '3–5 yrs', years: 4.0),
    (label: '5+ yrs', years: 6.0),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _skillInputCtrl.dispose();
    _educationCtrl.dispose();
    _projectsCtrl.dispose();
    _skillFocusNode.dispose();
    super.dispose();
  }

  void _loadExistingProfile() {
    final profile = context.read<ProfileController>().profile;
    if (profile == null) return;

    if (profile.targetRole != null && profile.targetRole!.isNotEmpty) {
      _roleCtrl.text = profile.targetRole!;
    }
    if (profile.skills.isNotEmpty) {
      _skills.addAll(profile.skills);
    }
    if (profile.experienceYears != null) {
      final y = profile.experienceYears!;
      _selectedExpYears = y;
      if (y < 1) {
        _selectedExpLabel = 'Fresher (< 1y)';
      } else if (y <= 3) {
        _selectedExpLabel = '1–3 yrs';
      } else if (y <= 5) {
        _selectedExpLabel = '3–5 yrs';
      } else {
        _selectedExpLabel = '5+ yrs';
      }
    }
  }

  void _addSkill(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // Handle comma-separated input gracefully
    final parts = trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final part in parts) {
        if (!_skills.any((s) => s.toLowerCase() == part.toLowerCase())) {
          _skills.add(part);
        }
      }
      _errorMessage = null;
    });

    _skillInputCtrl.clear();
    _skillFocusNode.requestFocus();
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.removeWhere((s) => s.toLowerCase() == skill.toLowerCase());
    });
  }

  void _selectRole(String role) {
    setState(() {
      if (_roleCtrl.text.trim().toLowerCase() == role.toLowerCase()) {
        _roleCtrl.clear();
      } else {
        _roleCtrl.text = role;
      }
      _errorMessage = null;
    });
  }

  Future<void> _pickAndParseResume() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (file == null) return;
      if (!mounted) return;

      setState(() => _isUploadingResume = true);

      final resumeEntity = await context.read<ResumeController>().uploadFromFilePicker(
            fileName: file.name,
            filePath: file.path,
            onProgress: (_) {},
          );

      if (!mounted) return;

      // Populate extracted resume data directly into our form
      setState(() {
        _isUploadingResume = false;

        // Populate role if empty or overwrite with resume role
        final extractedRole = resumeEntity.workExperiences.isNotEmpty &&
                resumeEntity.workExperiences.first.role.trim().isNotEmpty
            ? resumeEntity.workExperiences.first.role.trim()
            : (resumeEntity.name.contains('–')
                ? resumeEntity.name.split('–').last.trim()
                : null);

        if (extractedRole != null && extractedRole.isNotEmpty) {
          _roleCtrl.text = extractedRole;
        }

        // Add extracted skills
        for (final skill in resumeEntity.skills) {
          if (!_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
            _skills.add(skill);
          }
        }

        // Populate education if present
        if (resumeEntity.education.isNotEmpty && _educationCtrl.text.isEmpty) {
          _educationCtrl.text = resumeEntity.education;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume parsed! Extracted skills & role applied.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingResume = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingResume = false;
        _errorMessage = 'Could not parse resume. You can enter details manually.';
      });
    }
  }

  Future<void> _submitProfile() async {
    final role = _roleCtrl.text.trim();
    if (role.isEmpty) {
      setState(() => _errorMessage = 'Please enter or select your target role.');
      return;
    }

    if (_skills.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one key skill.');
      return;
    }

    setState(() => _errorMessage = null);

    final educationItems = _educationCtrl.text.trim().isNotEmpty
        ? [EducationItem(degree: _educationCtrl.text.trim())]
        : <EducationItem>[];

    final projectItems = _projectsCtrl.text.trim().isNotEmpty
        ? [ProjectItem(name: _projectsCtrl.text.trim())]
        : <ProjectItem>[];

    final success = await context.read<ProfileController>().updateProfile(
          targetRole: role,
          skills: _skills,
          experienceYears: _selectedExpYears,
          education: educationItems.isNotEmpty ? educationItems : null,
          projects: projectItems.isNotEmpty ? projectItems : null,
        );

    if (!mounted) return;

    if (!success) {
      setState(() =>
          _errorMessage = context.read<ProfileController>().errorMessage ??
              'Failed to save profile. Please try again.');
      return;
    }

    context.read<AuthController>().markProfileSetupComplete();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final isSaving = context.watch<ProfileController>().isSaving;

    final unselectedSkills = _suggestedSkills
        .where((s) => !_skills.any((item) => item.toLowerCase() == s.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Profile Setup',
          style: AppTypography.bold(17, color: colors.foreground),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Step 2 of 2',
              style: AppTypography.bold(11, color: colors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Headline ──────────────────────────────────────
                    Text(
                      'Personalize Your Practice',
                      style: AppTypography.bold(21, color: colors.foreground),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'AI tailors interview questions to your exact stack & level.',
                      style: AppTypography.regular(12, color: colors.mutedForeground),
                    ),

                    const SizedBox(height: 14),

                    // ── Fast-Track Resume Banner ─────────────────────────────
                    InkWell(
                      onTap: _isUploadingResume ? null : _pickAndParseResume,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: _isUploadingResume
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(colors.primary),
                                      ),
                                    )
                                  : Icon(FeatherIcons.zap, size: 16, color: colors.primary),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isUploadingResume
                                        ? 'Parsing resume with AI…'
                                        : 'Have a resume? Auto-fill profile',
                                    style: AppTypography.semiBold(12, color: colors.foreground),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Upload PDF/DOCX to extract role & skills instantly',
                                    style: AppTypography.regular(10, color: colors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isUploadingResume ? 'Working' : 'Upload',
                                style: AppTypography.bold(11, color: colors.primaryForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Target Role ──────────────────────────────────────────
                    Row(
                      children: [
                        Icon(FeatherIcons.briefcase, size: 13, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Target Role',
                          style: AppTypography.semiBold(13, color: colors.foreground),
                        ),
                        Text(' *', style: AppTypography.bold(13, color: colors.coral)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _roleCtrl,
                              style: AppTypography.medium(13, color: colors.foreground),
                              decoration: InputDecoration(
                                hintText: 'e.g. Flutter Developer, Backend Engineer',
                                hintStyle: AppTypography.regular(12, color: colors.mutedForeground),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_roleCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _roleCtrl.clear()),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(FeatherIcons.x, size: 14, color: colors.mutedForeground),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Role Quick-Pick Pills (Horizontal Scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _popularRoles.map((role) {
                          final isSelected = _roleCtrl.text.trim().toLowerCase() == role.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => _selectRole(role),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? colors.primary : colors.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? colors.primary : colors.border,
                                    width: isSelected ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: AppTypography.semiBold(
                                    11,
                                    color: isSelected ? colors.primaryForeground : colors.foreground,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Key Skills & Technologies ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(FeatherIcons.code, size: 13, color: colors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Key Skills',
                              style: AppTypography.semiBold(13, color: colors.foreground),
                            ),
                            Text(' *', style: AppTypography.bold(13, color: colors.coral)),
                          ],
                        ),
                        if (_skills.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_skills.length} added',
                              style: AppTypography.bold(10, color: colors.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Authentic Job-Portal Tag Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _skills.isEmpty ? colors.border : colors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selected Skill Chips
                          if (_skills.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colors.primary.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        skill,
                                        style: AppTypography.semiBold(11, color: colors.foreground),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _removeSkill(skill),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(
                                            FeatherIcons.x,
                                            size: 11,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              color: colors.border.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Input line
                          Row(
                            children: [
                              Icon(FeatherIcons.search, size: 13, color: colors.mutedForeground),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _skillInputCtrl,
                                  focusNode: _skillFocusNode,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: _addSkill,
                                  style: AppTypography.medium(12, color: colors.foreground),
                                  decoration: InputDecoration(
                                    hintText: _skills.isEmpty
                                        ? 'Type skill (e.g. Flutter, SQL) & press Enter'
                                        : 'Add another skill...',
                                    hintStyle: AppTypography.regular(11, color: colors.mutedForeground),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _addSkill(_skillInputCtrl.text),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+ Add',
                                    style: AppTypography.bold(11, color: colors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Suggested Skills (Horizontal Row)
                    if (unselectedSkills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Quick add:',
                            style: AppTypography.semiBold(10, color: colors.mutedForeground),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: unselectedSkills.take(9).map((skill) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: InkWell(
                                      onTap: () => _addSkill(skill),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors.secondary,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: colors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(FeatherIcons.plus, size: 9, color: colors.primary),
                                            const SizedBox(width: 3),
                                            Text(
                                              skill,
                                              style: AppTypography.medium(10, color: colors.foreground),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),

                    // ── Experience Level ─────────────────────────────────────
                    Row(
                      children: [
                        Icon(FeatherIcons.clock, size: 13, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Experience Level',
                          style: AppTypography.semiBold(13, color: colors.foreground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _expOptions.map((opt) {
                        final isSelected = _selectedExpLabel == opt.label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () => setState(() {
                                _selectedExpLabel = opt.label;
                                _selectedExpYears = opt.years;
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? colors.primary : colors.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? colors.primary : colors.border,
                                    width: isSelected ? 1.2 : 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  opt.label,
                                  style: AppTypography.semiBold(
                                    10,
                                    color: isSelected ? colors.primaryForeground : colors.foreground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Collapsible Optional Details (Education & Projects) ──
                    InkWell(
                      onTap: () => setState(() => _showAdditional = !_showAdditional),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: colors.secondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(FeatherIcons.bookOpen, size: 13, color: colors.mutedForeground),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add Education & Projects (Optional)',
                                style: AppTypography.semiBold(11, color: colors.foreground),
                              ),
                            ),
                            Icon(
                              _showAdditional ? FeatherIcons.chevronUp : FeatherIcons.chevronDown,
                              size: 15,
                              color: colors.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showAdditional) ...[
                      const SizedBox(height: 10),
                      Text('Education', style: AppTypography.medium(11, color: colors.foreground)),
                      const SizedBox(height: 4),
                      AppTextField(
                        controller: _educationCtrl,
                        placeholder: 'e.g. B.Tech Computer Science, 2024',
                      ),
                      const SizedBox(height: 8),
                      Text('Notable Project', style: AppTypography.medium(11, color: colors.foreground)),
                      const SizedBox(height: 4),
                      AppTextField(
                        controller: _projectsCtrl,
                        placeholder: 'e.g. Real-time chat app with Flutter & Node.js',
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.coral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.coral.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(FeatherIcons.alertCircle, size: 14, color: colors.coral),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.semiBold(11, color: colors.coral),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Sticky Action Button ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: AppButton(
                label: 'Save & Start Practicing',
                icon: FeatherIcons.arrowRight,
                isLoading: isSaving,
                onPress: _submitProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
