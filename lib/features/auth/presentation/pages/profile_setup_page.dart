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

  // Manual form
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  // Pulse animation — nullable so it's only created when first needed
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  /// Lazily initialise the pulse animation the first time it is needed.
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _expCtrl.dispose();
    _skillsCtrl.dispose();
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
                    : 'Finalising your profile…';
          });
        },
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
        _errorMessage = e.message ?? 'Server error. Please try again.';
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

  void _submitManual() {
    final name = _nameCtrl.text.trim();
    final role = _roleCtrl.text.trim();
    if (name.isEmpty || role.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name and target role.');
      return;
    }
    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    context.read<ResumeController>().addManualProfile(
          candidateName: name,
          targetRole: role,
          experience: _expCtrl.text.trim().isNotEmpty ? _expCtrl.text.trim() : 'Fresher',
          skills: skills.isNotEmpty ? skills : ['Flutter', 'Dart'],
          summary: '$role — ${_expCtrl.text.trim().isNotEmpty ? _expCtrl.text.trim() : 'early career'}',
        );
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
              nameCtrl: _nameCtrl,
              roleCtrl: _roleCtrl,
              expCtrl: _expCtrl,
              skillsCtrl: _skillsCtrl,
              errorMessage: _errorMessage,
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
                // Icon chip
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
                  'Add your resume',
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
                  // Upload option
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

                  // Manual option
                  _OptionTile(
                    icon: FeatherIcons.edit3,
                    iconColor: colors.accentForeground,
                    iconBg: colors.accent,
                    title: 'Enter info manually',
                    subtitle: 'Name, role, skills & experience',
                    colors: colors,
                    onTap: onManual,
                  ),

                  const Spacer(),

                  // Privacy note
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

    // ── Processing overlay ────────────────────────────────────────────
    if (isProcessing) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated orb
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

              // Progress bar
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

              // Stage checklist
              _StageCheck(label: 'Read document', done: progress > 0.25, colors: colors),
              _StageCheck(label: 'Extract skills & experience', done: progress > 0.5, colors: colors),
              _StageCheck(label: 'Identify work history', done: progress > 0.75, colors: colors),
              _StageCheck(label: 'Build structured profile', done: progress >= 1.0, colors: colors),
            ],
          ),
        ),
      );
    }

    // ── Idle state ────────────────────────────────────────────────────
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
                  // Drop zone
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

                  // Format tags
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

                  // Error
                  if (errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _ErrorBanner(message: errorMessage!, colors: colors),
                  ],

                  const SizedBox(height: 28),

                  // How it works card
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

class _ManualScreen extends StatelessWidget {
  final AppColorScheme colors;
  final TextEditingController nameCtrl;
  final TextEditingController roleCtrl;
  final TextEditingController expCtrl;
  final TextEditingController skillsCtrl;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ManualScreen({
    super.key,
    required this.colors,
    required this.nameCtrl,
    required this.roleCtrl,
    required this.expCtrl,
    required this.skillsCtrl,
    required this.errorMessage,
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
                  'Your background',
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
                    'Just the basics.',
                    style: AppTypography.bold(22, color: colors.foreground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We\'ll use this to tailor interview questions to your level.',
                    style: AppTypography.regular(
                      13,
                      color: colors.mutedForeground,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _Field(
                    label: 'Full name',
                    required: true,
                    child: AppTextField(
                      controller: nameCtrl,
                      placeholder: 'e.g. Alex Johnson',
                    ),
                  ),

                  _Field(
                    label: 'Target role',
                    required: true,
                    child: AppTextField(
                      controller: roleCtrl,
                      placeholder: 'e.g. Flutter Developer, Backend Engineer',
                    ),
                  ),

                  _Field(
                    label: 'Years of experience',
                    child: AppTextField(
                      controller: expCtrl,
                      placeholder: 'e.g. 2 years, Fresher',
                    ),
                  ),

                  _Field(
                    label: 'Key skills',
                    hint: 'Separate with commas',
                    child: AppTextField(
                      controller: skillsCtrl,
                      placeholder: 'e.g. Flutter, Dart, Firebase, REST APIs',
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
              onPress: onSubmit,
            ),
          ),
        ],
      ),
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
            (FeatherIcons.checkCircle, 'You review and confirm before saving'),
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
