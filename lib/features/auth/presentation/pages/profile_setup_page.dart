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

/// Modern, job-portal style Profile Setup screen (like Naukri / Indeed).
///
/// Provides typeahead search-as-you-type autocomplete for Target Roles and
/// Skills without static clutter.
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

  final _roleFocusNode = FocusNode();
  final _skillFocusNode = FocusNode();

  final _scrollCtrl = ScrollController();
  final _roleKey = GlobalKey();
  final _skillKey = GlobalKey();

  final List<String> _skills = [];
  String _selectedExpLabel = '1–3 yrs';
  double _selectedExpYears = 2.0;
  bool _showAdditional = false;
  bool _isUploadingResume = false;
  String? _errorMessage;

  static const List<String> _allRolesCatalog = [
    'Software Engineer',
    'Senior Software Engineer',
    'Full Stack Developer',
    'Backend Engineer',
    'Frontend Engineer',
    'Mobile Developer',
    'Android Developer',
    'Flutter developer',
    'iOS Developer',
    'DevOps Engineer',
    'Cloud Solutions Architect',
    'Site Reliability Engineer (SRE)',
    'AI / Machine Learning Engineer',
    'Data Scientist',
    'Data Engineer',
    'System Architect',
    'Database Administrator (DBA)',
    'Cyber Security Engineer',
    'QA Automation Engineer',
    'Software Development Engineer in Test (SDET)',
    'Product Manager',
    'Technical Program Manager',
    'Solutions Architect',
    'Engineering Manager',
    'UI/UX Developer',
    'Systems Engineer',
    'Embedded Systems Engineer',
    'Network Engineer',
    'Blockchain Developer',
    'Game Developer',
    'Microservices Architect',
    'Big Data Engineer',
    'Security Analyst',
  ];

  static const List<String> _allSkillsCatalog = [
    'Python',
    'Java',
    'JavaScript',
    'TypeScript',
    'C++',
    'C#',
    'Go',
    'Rust',
    'Kotlin',
    'Swift',
    'PHP',
    'Ruby',
    'SQL',
    'HTML / CSS',
    'React',
    'React Native',
    'Angular',
    'Vue.js',
    'Next.js',
    'Node.js',
    'Express.js',
    'NestJS',
    'Spring Boot',
    'Django',
    'FastAPI',
    'Flask',
    'ASP.NET Core',
    'Laravel',
    'PostgreSQL',
    'MySQL',
    'MongoDB',
    'Redis',
    'SQLite',
    'Cassandra',
    'Elasticsearch',
    'DynamoDB',
    'Oracle',
    'Firebase',
    'Docker',
    'Kubernetes',
    'AWS',
    'Google Cloud (GCP)',
    'Microsoft Azure',
    'Terraform',
    'Ansible',
    'Jenkins',
    'GitHub Actions',
    'GitLab CI',
    'Linux',
    'Bash / Shell Scripting',
    'REST APIs',
    'GraphQL',
    'gRPC',
    'WebSockets',
    'Microservices',
    'System Design',
    'Distributed Systems',
    'Event-Driven Architecture',
    'Kafka',
    'RabbitMQ',
    'Git',
    'CI/CD',
    'Unit Testing',
    'Integration Testing',
    'Jest',
    'PyTest',
    'Selenium',
    'Cypress',
    'Playwright',
    'OOP',
    'Data Structures & Algorithms',
    'Clean Architecture',
    'Design Patterns',
    'TensorFlow',
    'PyTorch',
    'Scikit-Learn',
    'Pandas',
    'NumPy',
    'Computer Vision',
    'NLP',
    'LLMs & Prompt Engineering',
    'OAuth 2.0',
    'JWT',
    'Cyber Security',
    'Dart',
    'Flutter',
  ];

  static const List<({String label, String sub, double years})> _expOptions = [
    (label: 'Fresher', sub: 'Core Basics', years: 0.5),
    (label: '1–3 yrs', sub: 'Hands-on', years: 2.0),
    (label: '3–5 yrs', sub: 'Mid-Senior', years: 4.0),
    (label: '5+ yrs', sub: 'Lead / Staff', years: 6.0),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();

    _roleFocusNode.addListener(() {
      if (_roleFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _roleFocusNode.hasFocus) {
            _scrollToRole();
          }
        });
      }
      if (mounted) setState(() {});
    });
    _skillFocusNode.addListener(() {
      if (_skillFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _skillFocusNode.hasFocus) {
            _scrollToSkill();
          }
        });
      }
      if (mounted) setState(() {});
    });
  }

  void _scrollToRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _roleKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToSkill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _skillKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _roleCtrl.dispose();
    _skillInputCtrl.dispose();
    _educationCtrl.dispose();
    _projectsCtrl.dispose();
    _roleFocusNode.dispose();
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

    final parts =
        trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
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
      _roleCtrl.text = role;
      _roleFocusNode.unfocus();
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

      final resumeEntity =
          await context.read<ResumeController>().uploadFromFilePicker(
                fileName: file.name,
                filePath: file.path,
                onProgress: (_) {},
              );

      if (!mounted) return;

      setState(() {
        _isUploadingResume = false;

        final extractedRole = resumeEntity.workExperiences.isNotEmpty &&
                resumeEntity.workExperiences.first.role.trim().isNotEmpty
            ? resumeEntity.workExperiences.first.role.trim()
            : (resumeEntity.name.contains('–')
                ? resumeEntity.name.split('–').last.trim()
                : null);

        if (extractedRole != null && extractedRole.isNotEmpty) {
          _roleCtrl.text = extractedRole;
        }

        for (final skill in resumeEntity.skills) {
          if (!_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
            _skills.add(skill);
          }
        }

        if (resumeEntity.education.isNotEmpty && _educationCtrl.text.isEmpty) {
          _educationCtrl.text = resumeEntity.education;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume parsed! Extracted skills & role applied.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
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
        _errorMessage =
            'Could not parse resume. You can enter details manually.';
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
      setState(() => _errorMessage = 'Please add at least one core skill.');
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

    // Filter matching roles as user types
    final roleQuery = _roleCtrl.text.trim().toLowerCase();
    final matchingRoles = roleQuery.isEmpty
        ? <String>[]
        : _allRolesCatalog
            .where((r) =>
                r.toLowerCase().contains(roleQuery) &&
                r.toLowerCase() != roleQuery)
            .take(5)
            .toList();

    // Filter matching skills as user types
    final skillQuery = _skillInputCtrl.text.trim().toLowerCase();
    final matchingSkills = skillQuery.isEmpty
        ? <String>[]
        : _allSkillsCatalog
            .where((s) =>
                s.toLowerCase().contains(skillQuery) &&
                !_skills.any((existing) =>
                    existing.toLowerCase() == s.toLowerCase()))
            .take(5)
            .toList();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(FeatherIcons.target, size: 16, color: colors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Profile Setup',
              style: AppTypography.bold(17, color: colors.foreground),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Step 2 of 2',
                  style: AppTypography.bold(11, color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: colors.primary),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(color: colors.primary),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                      18, 14, 18, isKeyboardOpen ? 320 : 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header Headline ────────────────────────────────────
                      Text(
                        'Personalize Your Practice',
                        style: AppTypography.bold(22, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set your target job role and technical skills. AI simulates authentic interviews tailored to your exact background.',
                        style: AppTypography.regular(12.5,
                            color: colors.mutedForeground, height: 1.4),
                      ),

                      const SizedBox(height: 16),

                      // ── Fast-Track Resume Banner ───────────────────────────
                      InkWell(
                        onTap: _isUploadingResume ? null : _pickAndParseResume,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: _isUploadingResume
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation(
                                              colors.primary),
                                        ),
                                      )
                                    : Icon(FeatherIcons.fileText,
                                        size: 19, color: colors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isUploadingResume
                                          ? 'Parsing resume with AI…'
                                          : 'Fast-Track with Resume',
                                      style: AppTypography.bold(13,
                                          color: colors.foreground),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Upload PDF or DOCX to auto-fill role & skills',
                                      style: AppTypography.regular(11,
                                          color: colors.mutedForeground),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _isUploadingResume ? 'Working' : 'Upload',
                                  style: AppTypography.bold(11.5,
                                      color: colors.primaryForeground),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Target Role Section (Typeahead / Autocomplete) ──────
                      Container(
                        key: _roleKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                        children: [
                          Icon(FeatherIcons.briefcase,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 7),
                          Text(
                            'Target Role',
                            style: AppTypography.bold(14,
                                color: colors.foreground),
                          ),
                          Text(' *',
                              style: AppTypography.bold(14,
                                  color: colors.coral)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _roleFocusNode.hasFocus
                                ? colors.primary
                                : colors.border,
                            width: _roleFocusNode.hasFocus ? 1.4 : 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 3),
                        child: Row(
                          children: [
                            Icon(FeatherIcons.search,
                                size: 15, color: colors.mutedForeground),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _roleCtrl,
                                focusNode: _roleFocusNode,
                                style: AppTypography.medium(13.5,
                                    color: colors.foreground),
                                decoration: InputDecoration(
                                  hintText: 'Type your target role (e.g. Software Engineer)',
                                  hintStyle: AppTypography.regular(12.5,
                                      color: colors.mutedForeground),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                  if (_roleCtrl.text.trim().isNotEmpty) {
                                    _scrollToRole();
                                  }
                                },
                              ),
                            ),
                            if (_roleCtrl.text.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() => _roleCtrl.clear()),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(FeatherIcons.xCircle,
                                      size: 15, color: colors.mutedForeground),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Dynamic Role Autocomplete Dropdown (As You Type)
                      if (matchingRoles.isNotEmpty && _roleFocusNode.hasFocus) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: colors.primary.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: matchingRoles.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final role = entry.value;
                                  return InkWell(
                                    onTap: () => _selectRole(role),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 11),
                                      decoration: BoxDecoration(
                                        border: idx < matchingRoles.length - 1
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: colors.border
                                                        .withValues(alpha: 0.6)))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(FeatherIcons.briefcase,
                                              size: 13, color: colors.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              role,
                                              style: AppTypography.medium(13,
                                                  color: colors.foreground),
                                            ),
                                          ),
                                          Icon(FeatherIcons.arrowUpLeft,
                                              size: 13,
                                              color: colors.mutedForeground),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Core Skills & Tech Stack Section ───────────────────
                      Container(
                        key: _skillKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(FeatherIcons.code,
                                  size: 14, color: colors.primary),
                              const SizedBox(width: 7),
                              Text(
                                'Core Skills & Technologies',
                                style: AppTypography.bold(14,
                                    color: colors.foreground),
                              ),
                              Text(' *',
                                  style: AppTypography.bold(14,
                                      color: colors.coral)),
                            ],
                          ),
                          if (_skills.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_skills.length} added',
                                style: AppTypography.bold(10.5,
                                    color: colors.primary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Skill Box with Selected Chips & Inline Search Input
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _skillFocusNode.hasFocus
                                ? colors.primary
                                : (_skills.isEmpty
                                    ? colors.border
                                    : colors.primary.withValues(alpha: 0.35)),
                            width: _skillFocusNode.hasFocus ? 1.4 : 1.2,
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
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 5, 7, 5),
                                    decoration: BoxDecoration(
                                      color:
                                          colors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: colors.primary
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          skill,
                                          style: AppTypography.semiBold(11.5,
                                              color: colors.foreground),
                                        ),
                                        const SizedBox(width: 5),
                                        GestureDetector(
                                          onTap: () => _removeSkill(skill),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: colors.primary
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              FeatherIcons.x,
                                              size: 10,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                color: colors.border.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 6),
                            ],

                            // Input line
                            Row(
                              children: [
                                Icon(FeatherIcons.plusCircle,
                                    size: 15, color: colors.mutedForeground),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _skillInputCtrl,
                                    focusNode: _skillFocusNode,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: _addSkill,
                                    style: AppTypography.medium(12.5,
                                        color: colors.foreground),
                                    decoration: InputDecoration(
                                      hintText: _skills.isEmpty
                                          ? 'Type skill (e.g. Python, SQL, React) & press Enter'
                                          : 'Type next skill...',
                                      hintStyle: AppTypography.regular(11.5,
                                          color: colors.mutedForeground),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                    onChanged: (_) {
                                      setState(() {});
                                      if (_skillInputCtrl.text.trim().isNotEmpty) {
                                        _scrollToSkill();
                                      }
                                    },
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _addSkill(_skillInputCtrl.text),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          colors.primary.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+ Add',
                                      style: AppTypography.bold(11.5,
                                          color: colors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Dynamic Skill Autocomplete Dropdown (As You Type)
                      if (matchingSkills.isNotEmpty && _skillFocusNode.hasFocus) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: colors.primary.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: matchingSkills.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final skill = entry.value;
                                  return InkWell(
                                    onTap: () => _addSkill(skill),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: idx < matchingSkills.length - 1
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: colors.border
                                                        .withValues(alpha: 0.6)))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(FeatherIcons.plus,
                                              size: 13, color: colors.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              skill,
                                              style: AppTypography.medium(13,
                                                  color: colors.foreground),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: colors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Add',
                                              style: AppTypography.bold(10,
                                                  color: colors.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Experience Level Section ───────────────────────────
                      Row(
                        children: [
                          Icon(FeatherIcons.clock,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 7),
                          Text(
                            'Experience Level',
                            style: AppTypography.bold(14,
                                color: colors.foreground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: _expOptions.map((opt) {
                          final isSelected = _selectedExpLabel == opt.label;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.5),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedExpLabel = opt.label;
                                  _selectedExpYears = opt.years;
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.border,
                                      width: isSelected ? 1.2 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Text(
                                        opt.label,
                                        style: AppTypography.bold(
                                          11,
                                          color: isSelected
                                              ? colors.primaryForeground
                                              : colors.foreground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.sub,
                                        style: AppTypography.regular(
                                          9.5,
                                          color: isSelected
                                              ? colors.primaryForeground
                                                  .withValues(alpha: 0.8)
                                              : colors.mutedForeground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // ── Collapsible Optional Details (Education & Projects) ─
                      InkWell(
                        onTap: () =>
                            setState(() => _showAdditional = !_showAdditional),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(FeatherIcons.bookOpen,
                                  size: 14, color: colors.mutedForeground),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Education & Key Projects (Optional)',
                                      style: AppTypography.bold(12,
                                          color: colors.foreground),
                                    ),
                                    Text(
                                      'Helps AI ask in-depth background questions',
                                      style: AppTypography.regular(10.5,
                                          color: colors.mutedForeground),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showAdditional
                                    ? FeatherIcons.chevronUp
                                    : FeatherIcons.chevronDown,
                                size: 16,
                                color: colors.mutedForeground,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showAdditional) ...[
                        const SizedBox(height: 12),
                        Text('Education',
                            style: AppTypography.semiBold(12,
                                color: colors.foreground)),
                        const SizedBox(height: 5),
                        AppTextField(
                          controller: _educationCtrl,
                          placeholder: 'e.g. B.Tech in Computer Science, 2024',
                        ),
                        const SizedBox(height: 10),
                        Text('Featured Project',
                            style: AppTypography.semiBold(12,
                                color: colors.foreground)),
                        const SizedBox(height: 5),
                        AppTextField(
                          controller: _projectsCtrl,
                          placeholder:
                              'e.g. Real-time distributed chat platform with WebSockets & Redis',
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colors.coral.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Icon(FeatherIcons.alertCircle,
                                  size: 16, color: colors.coral),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.semiBold(11.5,
                                      color: colors.coral),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Action Button ────────────────────────────────────
                      AppButton(
                        label: 'Save & Start Practicing',
                        icon: FeatherIcons.arrowRight,
                        isLoading: isSaving,
                        onPress: _submitProfile,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
