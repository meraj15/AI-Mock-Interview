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

enum _SetupMode { choice, upload, manual }

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  _SetupMode _mode = _SetupMode.choice;

  // Upload state
  String? _pickedFileName;
  String? _pickedFilePath;
  bool _isProcessing = false;
  double _uploadProgress = 0;
  String _statusMessage = '';
  String? _errorMessage;

  // Manual form — only fields NOT already known from signup
  final _roleCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _projectsCtrl = TextEditingController();

  // Pre-filled existing values read from ProfileController
  String _existingName = '';
  String _existingEmail = '';
  bool _existingHasRole = false;
  bool _existingHasSkills = false;

  // Pulse animation — nullable so it's only created when first needed
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  Animation<double> get _pulse {
    if (_pulseAnim != null) return _pulseAnim!;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
    );
    return _pulseAnim!;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  /// Pre-fill form fields from whatever profile data we already have.
  void _loadExistingProfile() {
    final profileCtrl = context.read<ProfileController>();
    final profile = profileCtrl.profile;
    final authUser = context.read<AuthController>().user;

    // Name: prefer profile fullName → then auth user name
    _existingName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (authUser?.name ?? '');

    // Email: from auth user (always available after signup)
    _existingEmail = authUser?.email ?? '';

    // Role
    final existingRole = profile?.targetRole ?? '';
    _existingHasRole = existingRole.isNotEmpty;
    if (_existingHasRole) {
      _roleCtrl.text = existingRole;
    }

    // Skills
    final existingSkills = profile?.skills ?? [];
    _existingHasSkills = existingSkills.isNotEmpty;
    if (_existingHasSkills) {
      _skillsCtrl.text = existingSkills.join(', ');
    }

    // Experience
    if (profile?.experienceLabel.isNotEmpty == true) {
      _expCtrl.text = profile!.experienceLabel;
    }
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _expCtrl.dispose();
    _skillsCtrl.dispose();
    _educationCtrl.dispose();
    _projectsCtrl.dispose();
    _pulseCtrl?.dispose();
    super.dispose();
  }

  // ── File Picker ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() => _errorMessage = null);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (file != null) {
      setState(() {
        _pickedFileName = file.name;
        _pickedFilePath = file.path;
        _mode = _SetupMode.upload;
        _uploadProgress = 0;
        _statusMessage = '';
      });
    }
  }

  Future<void> _submitUpload() async {
    if (_pickedFileName == null) return;
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.05;
      _statusMessage = 'Reading your resume…';
      _errorMessage = null;
    });

    try {
      final resumeEntity =
          await context.read<ResumeController>().uploadFromFilePicker(
        fileName: _pickedFileName!,
        filePath: _pickedFilePath,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = p;
            _statusMessage = p < 0.35
                ? 'Extracting content…'
                : p < 0.7
                    ? 'Identifying skills & experience…'
                    : 'Merging into your profile…';
          });
        },
      );

      if (!mounted) return;

      // ── Merge resume data into the unified UserProfile (non-destructive) ──
      // Existing user-provided values are preserved; only blank fields are filled.
      final skills = resumeEntity.skills;
      final educationText = resumeEntity.education;

      await context.read<ProfileController>().mergeResumeProfile(
            targetRole: resumeEntity.experience,
            skills: skills.isNotEmpty ? skills : null,
            education: educationText.isNotEmpty
                ? [EducationItem(degree: educationText)]
                : null,
          );

      if (!mounted) return;
      context.read<AuthController>().markProfileSetupComplete();
      _goHome();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.message;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  // ── Manual Submit ────────────────────────────────────────────────────────────

  Future<void> _submitManual() async {
    // Gather role & skills — either pre-filled or newly entered
    final role = _roleCtrl.text.trim();
    if (role.isEmpty) {
      setState(() => _errorMessage = 'Please enter your target role.');
      return;
    }

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Parse experience years from text
    double? expYears;
    final expText = _expCtrl.text.trim();
    final expNum = double.tryParse(
        expText.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (expNum != null) expYears = expNum;

    // Parse education
    final educationText = _educationCtrl.text.trim();
    final educationItems = educationText.isNotEmpty
        ? [EducationItem(degree: educationText)]
        : <EducationItem>[];

    // Parse projects
    final projectsText = _projectsCtrl.text.trim();
    final projectItems = projectsText.isNotEmpty
        ? [ProjectItem(name: projectsText)]
        : <ProjectItem>[];

    setState(() => _errorMessage = null);

    // Save everything to the unified profile via ProfileController
    final success = await context.read<ProfileController>().updateProfile(
          targetRole: role,
          skills: skills.isNotEmpty ? skills : null,
          experienceYears: expYears,
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
    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavPage()),
      (route) => false,
    );
  }

  // ── Root build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: switch (_mode) {
          _SetupMode.choice => _ChoiceScreen(
              key: const ValueKey('choice'),
              colors: colors,
              onUpload: _pickFile,
              onManual: () => setState(() {
                _mode = _SetupMode.manual;
                _errorMessage = null;
              }),
            ),
          _SetupMode.upload => _UploadScreen(
              key: const ValueKey('upload'),
              colors: colors,
              fileName: _pickedFileName,
              isProcessing: _isProcessing,
              progress: _uploadProgress,
              statusMessage: _statusMessage,
              errorMessage: _errorMessage,
              pulseAnim: _pulse,
              onPickFile: _pickFile,
              onSubmit: _submitUpload,
              onBack: () => setState(() {
                _mode = _SetupMode.choice;
                _pickedFileName = null;
                _pickedFilePath = null;
                _errorMessage = null;
              }),
            ),
          _SetupMode.manual => _ManualScreen(
              key: const ValueKey('manual'),
              colors: colors,
              // Pre-filled read-only context
              existingName: _existingName,
              existingEmail: _existingEmail,
              existingHasRole: _existingHasRole,
              existingHasSkills: _existingHasSkills,
              // Editable controllers
              roleCtrl: _roleCtrl,
              expCtrl: _expCtrl,
              skillsCtrl: _skillsCtrl,
              educationCtrl: _educationCtrl,
              projectsCtrl: _projectsCtrl,
              errorMessage: _errorMessage,
              isLoading:
                  context.watch<ProfileController>().isSaving,
              onSubmit: _submitManual,
              onBack: () => setState(() {
                _mode = _SetupMode.choice;
                _errorMessage = null;
              }),
            ),
        },
      ),
    );
  }
}

// ── Choice Screen ─────────────────────────────────────────────────────────────

class _ChoiceScreen extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onUpload;
  final VoidCallback onManual;

  const _ChoiceScreen({
    super.key,
    required this.colors,
    required this.onUpload,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Full-width navy hero ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.mint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.fileText, size: 21, color: colors.mint),
                ),
                const SizedBox(height: 20),
                Text(
                  'Complete your profile',
                  style: AppTypography.bold(26, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every interview question is tailored\nto your actual background.',
                  style: AppTypography.regular(
                    13,
                    color: const Color(0xFFBFCBE5),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),

          // ── Options ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  _OptionTile(
                    icon: FeatherIcons.upload,
                    iconColor: colors.primary,
                    iconBg: colors.primary.withValues(alpha: 0.1),
                    title: 'Upload resume',
                    subtitle: 'PDF, DOC, DOCX or TXT',
                    badge: 'Recommended',
                    badgeColor: colors.mint,
                    badgeTextColor: colors.navy,
                    colors: colors,
                    onTap: onUpload,
                  ),

                  const SizedBox(height: 12),

                  _OptionTile(
                    icon: FeatherIcons.edit3,
                    iconColor: colors.accentForeground,
                    iconBg: colors.accent,
                    title: 'Continue manually',
                    subtitle: 'Add experience & education — we already have the basics',
                    colors: colors,
                    onTap: onManual,
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(FeatherIcons.shield, size: 16, color: colors.mutedForeground),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your resume is parsed once. Only the structured profile is used — never the raw file.',
                            style: AppTypography.regular(
                              11,
                              color: colors.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upload Screen ─────────────────────────────────────────────────────────────

class _UploadScreen extends StatelessWidget {
  final AppColorScheme colors;
  final String? fileName;
  final bool isProcessing;
  final double progress;
  final String statusMessage;
  final String? errorMessage;
  final Animation<double> pulseAnim;
  final VoidCallback onPickFile;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _UploadScreen({
    super.key,
    required this.colors,
    required this.fileName,
    required this.isProcessing,
    required this.progress,
    required this.statusMessage,
    required this.errorMessage,
    required this.pulseAnim,
    required this.onPickFile,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    if (isProcessing) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: pulseAnim,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.25),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.mint),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Parsing resume',
                style: AppTypography.bold(22, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              Text(
                statusMessage,
                style: AppTypography.regular(
                  13,
                  color: colors.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colors.secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Working on it…',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTypography.bold(11, color: colors.primary),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              _StageCheck(label: 'Read document', done: progress > 0.25, colors: colors),
              _StageCheck(label: 'Extract skills & experience', done: progress > 0.5, colors: colors),
              _StageCheck(label: 'Identify work history', done: progress > 0.75, colors: colors),
              _StageCheck(label: 'Merge into your profile', done: progress >= 1.0, colors: colors),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(FeatherIcons.arrowLeft, size: 20, color: colors.foreground),
                ),
                Text(
                  'Upload resume',
                  style: AppTypography.bold(17, color: colors.foreground),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onPickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: hasFile ? 20 : 40,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: hasFile
                            ? colors.primary.withValues(alpha: 0.05)
                            : colors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: hasFile ? colors.primary : colors.border,
                          width: hasFile ? 1.5 : 1,
                        ),
                      ),
                      child: hasFile
                          ? _FileRow(
                              fileName: fileName!,
                              colors: colors,
                              onReplace: onPickFile,
                            )
                          : _EmptyDrop(colors: colors),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'SUPPORTED FORMATS',
                    style: AppTypography.bold(
                      10,
                      color: colors.mutedForeground,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['PDF', 'DOC', 'DOCX', 'TXT'].map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            f,
                            style: AppTypography.semiBold(11, color: colors.foreground),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Max 10 MB',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _ErrorBanner(message: errorMessage!, colors: colors),
                  ],

                  const SizedBox(height: 28),
                  _HowItWorksCard(colors: colors),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: AppButton(
              label: hasFile ? 'Parse & continue' : 'Choose a file',
              icon: hasFile ? FeatherIcons.zap : FeatherIcons.upload,
              onPress: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manual Screen ─────────────────────────────────────────────────────────────
// Only shows information the app does NOT already have.
// Pre-filled data is shown read-only with an edit affordance.

class _ManualScreen extends StatelessWidget {
  final AppColorScheme colors;
  // Pre-filled (already known) data
  final String existingName;
  final String existingEmail;
  final bool existingHasRole;
  final bool existingHasSkills;
  // Editable controllers (may be pre-filled if data exists)
  final TextEditingController roleCtrl;
  final TextEditingController expCtrl;
  final TextEditingController skillsCtrl;
  final TextEditingController educationCtrl;
  final TextEditingController projectsCtrl;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ManualScreen({
    super.key,
    required this.colors,
    required this.existingName,
    required this.existingEmail,
    required this.existingHasRole,
    required this.existingHasSkills,
    required this.roleCtrl,
    required this.expCtrl,
    required this.skillsCtrl,
    required this.educationCtrl,
    required this.projectsCtrl,
    required this.errorMessage,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(FeatherIcons.arrowLeft, size: 20, color: colors.foreground),
                ),
                Text(
                  'Complete your profile',
                  style: AppTypography.bold(17, color: colors.foreground),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Almost there.',
                    style: AppTypography.bold(22, color: colors.foreground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We already have the basics from signup. Just add a few more details to tailor your interviews.',
                    style: AppTypography.regular(
                      13,
                      color: colors.mutedForeground,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Already collected banner ────────────────────────────
                  _AlreadyCollectedSection(
                    colors: colors,
                    name: existingName,
                    email: existingEmail,
                  ),

                  const SizedBox(height: 24),

                  // ── Role (editable — may or may not be pre-filled) ─────
                  _Field(
                    label: 'Target role',
                    required: true,
                    hint: existingHasRole ? 'Pre-filled from your profile — edit if needed' : null,
                    child: AppTextField(
                      controller: roleCtrl,
                      placeholder: 'e.g. Flutter Developer, Backend Engineer',
                    ),
                  ),

                  // ── Skills (editable — may or may not be pre-filled) ───
                  _Field(
                    label: 'Key skills',
                    hint: existingHasSkills
                        ? 'Pre-filled from your profile — edit if needed'
                        : 'Separate with commas',
                    child: AppTextField(
                      controller: skillsCtrl,
                      placeholder: 'e.g. Flutter, Dart, Firebase, REST APIs',
                    ),
                  ),

                  const SizedBox(height: 4),
                  _SectionDivider(label: 'Additional details', colors: colors),
                  const SizedBox(height: 16),

                  // ── Experience ────────────────────────────────────────
                  _Field(
                    label: 'Years of experience',
                    child: AppTextField(
                      controller: expCtrl,
                      placeholder: 'e.g. 2 years, Fresher',
                    ),
                  ),

                  // ── Education ─────────────────────────────────────────
                  _Field(
                    label: 'Education',
                    hint: 'Optional — e.g. B.Tech Computer Science, MIT 2022',
                    child: AppTextField(
                      controller: educationCtrl,
                      placeholder: 'Degree, Institution, Year',
                    ),
                  ),

                  // ── Projects ──────────────────────────────────────────
                  _Field(
                    label: 'Notable project',
                    hint: 'Optional — your most impressive project',
                    child: AppTextField(
                      controller: projectsCtrl,
                      placeholder: 'e.g. E-commerce app with Flutter & Firebase',
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _ErrorBanner(message: errorMessage!, colors: colors),
                  ],

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: AppButton(
              label: 'Save & continue',
              icon: FeatherIcons.arrowRight,
              isLoading: isLoading,
              onPress: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Already Collected Section ─────────────────────────────────────────────────

class _AlreadyCollectedSection extends StatelessWidget {
  final AppColorScheme colors;
  final String name;
  final String email;

  const _AlreadyCollectedSection({
    required this.colors,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = name.isNotEmpty || email.isNotEmpty;
    if (!hasData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.mint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.checkCircle, size: 14, color: colors.mint),
              const SizedBox(width: 8),
              Text(
                'Already collected from signup',
                style: AppTypography.semiBold(12, color: colors.mint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (name.isNotEmpty)
            _InfoRow(label: 'Name', value: name, colors: colors),
          if (email.isNotEmpty)
            _InfoRow(label: 'Email', value: email, colors: colors),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme colors;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: AppTypography.regular(12, color: colors.mutedForeground),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.semiBold(12, color: colors.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  final AppColorScheme colors;

  const _SectionDivider({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: colors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.bold(
              9,
              color: colors.mutedForeground,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border, thickness: 1)),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 21, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.bold(14, color: colors.foreground),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? colors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: AppTypography.bold(
                                9,
                                color: badgeTextColor ?? colors.primaryForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.regular(12, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(FeatherIcons.chevronRight, size: 16, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDrop extends StatelessWidget {
  final AppColorScheme colors;
  const _EmptyDrop({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(FeatherIcons.upload, size: 25, color: colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select your resume',
          style: AppTypography.semiBold(15, color: colors.foreground),
        ),
        const SizedBox(height: 4),
        Text(
          'PDF, DOC, DOCX or TXT · Max 10 MB',
          style: AppTypography.regular(12, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  final String fileName;
  final AppColorScheme colors;
  final VoidCallback onReplace;

  const _FileRow({
    required this.fileName,
    required this.colors,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 52,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(FeatherIcons.fileText, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: AppTypography.semiBold(13, color: colors.foreground),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Ready to parse',
                    style: AppTypography.regular(11, color: colors.success),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onReplace,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: colors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Replace',
            style: AppTypography.semiBold(11, color: colors.foreground),
          ),
        ),
      ],
    );
  }
}

class _StageCheck extends StatelessWidget {
  final String label;
  final bool done;
  final AppColorScheme colors;

  const _StageCheck({
    required this.label,
    required this.done,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: done
                  ? colors.success.withValues(alpha: 0.15)
                  : colors.secondary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              done ? FeatherIcons.check : FeatherIcons.circle,
              size: 12,
              color: done ? colors.success : colors.border,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.medium(
              13,
              color: done ? colors.foreground : colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final AppColorScheme colors;
  const _HowItWorksCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.zap, size: 14, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'What happens next',
                style: AppTypography.semiBold(13, color: colors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            (FeatherIcons.fileText, 'Text is extracted from your file'),
            (FeatherIcons.cpu, 'AI builds a structured candidate profile'),
            (FeatherIcons.checkCircle, 'Data is merged into your existing profile'),
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(step.$1, size: 14, color: colors.mutedForeground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: AppTypography.regular(
                        12,
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final AppColorScheme colors;

  const _ErrorBanner({required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FeatherIcons.alertCircle, size: 14, color: colors.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.semiBold(12, color: colors.coral),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final Widget child;

  const _Field({
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.semiBold(12, color: colors.foreground),
              ),
              if (required)
                Text(
                  ' *',
                  style: AppTypography.bold(12, color: colors.coral),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: AppTypography.regular(10, color: colors.mutedForeground),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
