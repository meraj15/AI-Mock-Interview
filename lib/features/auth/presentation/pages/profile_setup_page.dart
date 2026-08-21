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

class _ProfileSetupPageState extends State<ProfileSetupPage> {
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
  final _summaryCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _expCtrl.dispose();
    _skillsCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  // ─── File Picker ────────────────────────────────────────────────────────────

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
      _statusMessage = 'Uploading resume…';
      _errorMessage = null;
    });

    try {
      final resumeCtrl = context.read<ResumeController>();

      await resumeCtrl.uploadFromFilePicker(
        fileName: _pickedFileName!,
        filePath: _pickedFilePath,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = p;
            _statusMessage = p < 0.4
                ? 'Sending to AI parser…'
                : p < 0.75
                    ? 'Extracting skills & experience…'
                    : 'Building your profile…';
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  // ─── Manual Submit ─────────────────────────────────────────────────────────

  void _submitManual() {
    final name = _nameCtrl.text.trim();
    final role = _roleCtrl.text.trim();
    if (name.isEmpty || role.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name and target role.');
      return;
    }
    setState(() => _errorMessage = null);

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    context.read<ResumeController>().addManualProfile(
          candidateName: name,
          targetRole: role,
          experience: _expCtrl.text.trim().isNotEmpty
              ? _expCtrl.text.trim()
              : 'Fresher',
          skills: skills.isNotEmpty ? skills : ['Flutter', 'Dart'],
          summary: _summaryCtrl.text.trim().isNotEmpty
              ? _summaryCtrl.text.trim()
              : '$role with ${_expCtrl.text.trim().isNotEmpty ? _expCtrl.text.trim() : 'some'} experience.',
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: switch (_mode) {
          _SetupMode.choice => _buildChoiceScreen(colors),
          _SetupMode.upload => _buildUploadScreen(colors),
          _SetupMode.manual => _buildManualScreen(colors),
        },
      ),
    );
  }

  // ─── Choice Screen ─────────────────────────────────────────────────────────

  Widget _buildChoiceScreen(AppColorScheme colors) {
    return Column(
      children: [
        // Top gradient header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          decoration: BoxDecoration(
            color: colors.navy,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(FeatherIcons.fileText, size: 22, color: colors.mint),
              ),
              const SizedBox(height: 18),
              Text(
                'Add your resume',
                style: AppTypography.bold(28, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll use it to personalize every interview\nquestion to your actual experience.',
                style: AppTypography.regular(13, color: const Color(0xFFBFCBE5), height: 1.5),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How would you like to add it?',
                  style: AppTypography.semiBold(13, color: colors.mutedForeground),
                ),
                const SizedBox(height: 16),

                // Upload card
                _BigOptionCard(
                  icon: FeatherIcons.upload,
                  iconBg: colors.primary.withValues(alpha: 0.12),
                  iconColor: colors.primary,
                  title: 'Upload resume',
                  subtitle: 'PDF, DOC, DOCX or TXT',
                  tag: 'Recommended',
                  tagColor: colors.mint,
                  colors: colors,
                  onTap: _pickFile,
                ),

                const SizedBox(height: 12),

                // Manual card
                _BigOptionCard(
                  icon: FeatherIcons.edit3,
                  iconBg: colors.accent.withValues(alpha: 0.15),
                  iconColor: colors.accent,
                  title: 'Enter info manually',
                  subtitle: 'Name, role, skills & experience',
                  colors: colors,
                  onTap: () => setState(() {
                    _mode = _SetupMode.manual;
                    _errorMessage = null;
                  }),
                ),

                const SizedBox(height: 28),

                // Why we need it
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FeatherIcons.info, size: 15, color: colors.mutedForeground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your resume is parsed once and converted into a structured profile. It\'s never stored or sent to AI during interviews — only the profile data is used.',
                          style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.5),
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
    );
  }

  // ─── Upload Screen ─────────────────────────────────────────────────────────

  Widget _buildUploadScreen(AppColorScheme colors) {
    final hasFile = _pickedFileName != null;

    return Column(
      children: [
        // Back bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(
            children: [
              if (!_isProcessing)
                IconButton(
                  icon: Icon(FeatherIcons.arrowLeft, color: colors.foreground, size: 20),
                  onPressed: () => setState(() {
                    _mode = _SetupMode.choice;
                    _pickedFileName = null;
                    _pickedFilePath = null;
                    _errorMessage = null;
                  }),
                ),
              if (!_isProcessing) ...[
                Text('Upload resume', style: AppTypography.bold(16, color: colors.foreground)),
              ],
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File drop zone
                GestureDetector(
                  onTap: _isProcessing ? null : _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: hasFile
                          ? colors.primary.withValues(alpha: 0.06)
                          : colors.secondary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: hasFile ? colors.primary : colors.border,
                        width: hasFile ? 1.5 : 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: hasFile
                        ? _FilePreviewContent(
                            fileName: _pickedFileName!,
                            colors: colors,
                            onReplace: _isProcessing ? null : _pickFile,
                          )
                        : _DropZoneContent(colors: colors),
                  ),
                ),

                // Progress area (shown while uploading)
                if (_isProcessing) ...[
                  const SizedBox(height: 28),
                  _UploadProgressCard(
                    progress: _uploadProgress,
                    message: _statusMessage,
                    colors: colors,
                  ),
                ],

                // Error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: _errorMessage!, colors: colors),
                ],

                const SizedBox(height: 28),

                // Supported formats
                if (!_isProcessing) ...[
                  Text(
                    'SUPPORTED FORMATS',
                    style: AppTypography.bold(10, color: colors.mutedForeground, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['PDF', 'DOC', 'DOCX', 'TXT'].map((f) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(f, style: AppTypography.semiBold(11, color: colors.foreground)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max file size: 10 MB',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom CTA
        if (!_isProcessing)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: AppButton(
              label: hasFile ? 'Parse & continue' : 'Choose a file',
              icon: hasFile ? FeatherIcons.zap : FeatherIcons.upload,
              onPress: hasFile ? _submitUpload : _pickFile,
            ),
          ),
      ],
    );
  }

  // ─── Manual Screen ─────────────────────────────────────────────────────────

  Widget _buildManualScreen(AppColorScheme colors) {
    return Column(
      children: [
        // Back bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(FeatherIcons.arrowLeft, color: colors.foreground, size: 20),
                onPressed: () => setState(() {
                  _mode = _SetupMode.choice;
                  _errorMessage = null;
                }),
              ),
              Text('Your background', style: AppTypography.bold(16, color: colors.foreground)),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just the basics — we\'ll personalize questions based on what you share.',
                  style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
                ),
                const SizedBox(height: 24),

                _FormLabel(label: 'Full name *', colors: colors),
                AppTextField(controller: _nameCtrl, placeholder: 'e.g. Alex Johnson'),
                const SizedBox(height: 16),

                _FormLabel(label: 'Target role *', colors: colors),
                AppTextField(
                  controller: _roleCtrl,
                  placeholder: 'e.g. Flutter Developer, Backend Engineer',
                ),
                const SizedBox(height: 16),

                _FormLabel(label: 'Years of experience', colors: colors),
                AppTextField(
                  controller: _expCtrl,
                  placeholder: 'e.g. 2 years, Fresher, 6 months',
                ),
                const SizedBox(height: 16),

                _FormLabel(label: 'Key skills', colors: colors),
                Text(
                  'Separate with commas',
                  style: AppTypography.regular(10, color: colors.mutedForeground),
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _skillsCtrl,
                  placeholder: 'e.g. Flutter, Dart, Firebase, REST APIs',
                ),
                const SizedBox(height: 16),

                _FormLabel(label: 'Short bio / summary', colors: colors),
                AppTextField(
                  controller: _summaryCtrl,
                  placeholder: 'A brief sentence about your background...',
                  multiline: true,
                  minLines: 3,
                  maxLines: 4,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: _errorMessage!, colors: colors),
                ],

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: AppButton(
            label: 'Save & go to home',
            icon: FeatherIcons.arrowRight,
            onPress: _submitManual,
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BigOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? tag;
  final Color? tagColor;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _BigOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.tag,
    this.tagColor,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: AppTypography.bold(15, color: colors.foreground)),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (tagColor ?? colors.primary).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag!,
                              style: AppTypography.bold(9, color: tagColor ?? colors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTypography.regular(12, color: colors.mutedForeground)),
                  ],
                ),
              ),
              Icon(FeatherIcons.chevronRight, size: 16, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropZoneContent extends StatelessWidget {
  final AppColorScheme colors;
  const _DropZoneContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.border,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(FeatherIcons.upload, size: 26, color: colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select your resume',
          style: AppTypography.semiBold(14, color: colors.foreground),
        ),
        const SizedBox(height: 4),
        Text(
          'PDF, DOC, DOCX or TXT',
          style: AppTypography.regular(12, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _FilePreviewContent extends StatelessWidget {
  final String fileName;
  final AppColorScheme colors;
  final VoidCallback? onReplace;

  const _FilePreviewContent({
    required this.fileName,
    required this.colors,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(FeatherIcons.fileText, size: 22, color: colors.primary),
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
              const SizedBox(height: 4),
              Text(
                'Ready to parse',
                style: AppTypography.regular(11, color: colors.mint),
              ),
            ],
          ),
        ),
        if (onReplace != null)
          TextButton(
            onPressed: onReplace,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Replace',
              style: AppTypography.semiBold(11, color: colors.primary),
            ),
          ),
      ],
    );
  }
}

class _UploadProgressCard extends StatelessWidget {
  final double progress;
  final String message;
  final AppColorScheme colors;

  const _UploadProgressCard({
    required this.progress,
    required this.message,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.mint),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.semiBold(13, color: Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTypography.bold(13, color: colors.mint),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colors.mint),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This may take a few seconds…',
            style: AppTypography.regular(10, color: const Color(0xFFBFCBE5)),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FeatherIcons.alertCircle, size: 15, color: colors.coral),
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

class _FormLabel extends StatelessWidget {
  final String label;
  final AppColorScheme colors;

  const _FormLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTypography.semiBold(12, color: colors.foreground)),
    );
  }
}
