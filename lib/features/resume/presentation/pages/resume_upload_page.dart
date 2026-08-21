import 'package:feather_icons/feather_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../controllers/resume_controller.dart';
import 'edit_parsed_resume_page.dart';

enum _Tab { upload, paste }

class ResumeUploadPage extends StatefulWidget {
  final bool isReplacing;
  final String? replaceId;

  const ResumeUploadPage({
    super.key,
    this.isReplacing = false,
    this.replaceId,
  });

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}

class _ResumeUploadPageState extends State<ResumeUploadPage> {
  _Tab _tab = _Tab.upload;

  // File picker
  String? _pickedFileName;
  String? _pickedFilePath;

  // Paste
  final _pasteCtrl = TextEditingController();

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  // ── File picker ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (file != null) {
      setState(() {
        _pickedFileName = file.name;
        _pickedFilePath = file.path;
      });
    }
  }

  Future<void> _submitUpload() async {
    if (_pickedFileName == null) {
      await _pickFile();
      return;
    }
    final resumeCtrl = context.read<ResumeController>();
    final parsed = await resumeCtrl.uploadFromFilePicker(
      fileName: _pickedFileName!,
      filePath: _pickedFilePath,
    );
    if (widget.isReplacing && widget.replaceId != null) {
      resumeCtrl.replaceResume(widget.replaceId!, parsed);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EditParsedResumePage(resume: parsed)),
      );
    }
  }

  Future<void> _submitPaste() async {
    final text = _pasteCtrl.text.trim();
    if (text.isEmpty) return;
    final resumeCtrl = context.read<ResumeController>();
    final parsed = await resumeCtrl.pasteAndParse(text);
    if (widget.isReplacing && widget.replaceId != null) {
      resumeCtrl.replaceResume(widget.replaceId!, parsed);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EditParsedResumePage(resume: parsed)),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final resumeCtrl = context.watch<ResumeController>();
    final isParsing = resumeCtrl.isParsing;
    final progress = resumeCtrl.parsingProgress;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: isParsing && progress != null
            ? _buildParsingState(colors, progress)
            : _buildIdleState(colors),
      ),
    );
  }

  // ── Parsing overlay ─────────────────────────────────────────────────────

  Widget _buildParsingState(AppColorScheme colors, dynamic progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.navy,
              borderRadius: BorderRadius.circular(26),
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

          const SizedBox(height: 28),

          Text(
            'Parsing your resume',
            style: AppTypography.bold(22, color: colors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            progress.stageMessage,
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ProgressBar(
              value: (progress.progressPercent as double) * 100,
              height: 6,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _stageLabel(progress.stage.toString()),
                style: AppTypography.semiBold(11, color: colors.mutedForeground),
              ),
              Text(
                '${((progress.progressPercent as double) * 100).toInt()}%',
                style: AppTypography.bold(11, color: colors.primary),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Stage steps
          _StageRow(
            label: 'Read document',
            done: (progress.progressPercent as double) > 0.25,
            colors: colors,
          ),
          _StageRow(
            label: 'Extract skills & experience',
            done: (progress.progressPercent as double) > 0.5,
            colors: colors,
          ),
          _StageRow(
            label: 'Analyse work history',
            done: (progress.progressPercent as double) > 0.75,
            colors: colors,
          ),
          _StageRow(
            label: 'Build structured profile',
            done: (progress.progressPercent as double) >= 1.0,
            colors: colors,
          ),
        ],
      ),
    );
  }

  String _stageLabel(String raw) {
    if (raw.contains('reading')) return 'Reading document…';
    if (raw.contains('skills')) return 'Extracting skills…';
    if (raw.contains('experience')) return 'Analysing experience…';
    if (raw.contains('finaliz')) return 'Building profile…';
    return 'Processing…';
  }

  // ── Idle state ──────────────────────────────────────────────────────────

  Widget _buildIdleState(AppColorScheme colors) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: colors.navy,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    FeatherIcons.arrowLeft,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.isReplacing ? 'Replace resume' : 'Add your resume',
                style: AppTypography.bold(24, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload a file or paste your resume text.\nWe\'ll extract your experience automatically.',
                style: AppTypography.regular(
                  13,
                  color: const Color(0xFFBFCBE5),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Upload file',
                        icon: FeatherIcons.upload,
                        selected: _tab == _Tab.upload,
                        colors: colors,
                        onTap: () => setState(() => _tab = _Tab.upload),
                      ),
                      _TabChip(
                        label: 'Paste text',
                        icon: FeatherIcons.edit3,
                        selected: _tab == _Tab.paste,
                        colors: colors,
                        onTap: () => setState(() => _tab = _Tab.paste),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_tab == _Tab.upload) ...[
                  _buildUploadTab(colors),
                ] else ...[
                  _buildPasteTab(colors),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom CTA ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: _tab == _Tab.upload
              ? AppButton(
                  label: _pickedFileName != null ? 'Parse & continue' : 'Choose a file',
                  icon: _pickedFileName != null ? FeatherIcons.zap : FeatherIcons.upload,
                  onPress: _submitUpload,
                )
              : AppButton(
                  label: 'Extract & structure',
                  icon: FeatherIcons.cpu,
                  disabled: _pasteCtrl.text.trim().isEmpty,
                  onPress: _submitPaste,
                ),
        ),
      ],
    );
  }

  // ── Upload tab content ───────────────────────────────────────────────────

  Widget _buildUploadTab(AppColorScheme colors) {
    final hasFile = _pickedFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop zone
        GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: hasFile
                  ? colors.primary.withValues(alpha: 0.06)
                  : colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasFile ? colors.primary : colors.border,
                width: hasFile ? 1.5 : 1,
              ),
            ),
            child: hasFile
                ? _FilePreview(
                    fileName: _pickedFileName!,
                    colors: colors,
                    onReplace: _pickFile,
                  )
                : _DropZoneEmpty(colors: colors),
          ),
        ),

        const SizedBox(height: 20),

        // Supported formats
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
                color: colors.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                f,
                style: AppTypography.semiBold(11, color: colors.foreground),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),
        Text(
          'Max file size: 10 MB',
          style: AppTypography.regular(11, color: colors.mutedForeground),
        ),

        const SizedBox(height: 24),

        // How it works
        _HowItWorksCard(colors: colors),
      ],
    );
  }

  // ── Paste tab content ────────────────────────────────────────────────────

  Widget _buildPasteTab(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste your resume',
          style: AppTypography.bold(15, color: colors.foreground),
        ),
        const SizedBox(height: 4),
        Text(
          'Include your skills, experience, and projects for best results.',
          style: AppTypography.regular(12, color: colors.mutedForeground, height: 1.5),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _pasteCtrl,
          placeholder: 'Paste the full content of your resume here…',
          multiline: true,
          minLines: 9,
          maxLines: 14,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _HowItWorksCard(colors: colors),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? colors.primary : colors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.semiBold(
                  12,
                  color: selected ? colors.foreground : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropZoneEmpty extends StatelessWidget {
  final AppColorScheme colors;
  const _DropZoneEmpty({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(FeatherIcons.upload, size: 24, color: colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to select your resume',
          style: AppTypography.semiBold(15, color: colors.foreground),
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

class _FilePreview extends StatelessWidget {
  final String fileName;
  final AppColorScheme colors;
  final VoidCallback onReplace;

  const _FilePreview({
    required this.fileName,
    required this.colors,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
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

class _StageRow extends StatelessWidget {
  final String label;
  final bool done;
  final AppColorScheme colors;

  const _StageRow({
    required this.label,
    required this.done,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? colors.mint.withValues(alpha: 0.18)
                  : colors.secondary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              done ? FeatherIcons.check : FeatherIcons.circle,
              size: 13,
              color: done ? colors.mint : colors.border,
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
      padding: const EdgeInsets.all(16),
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
                'How AI parsing works',
                style: AppTypography.semiBold(13, color: colors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            ('1', 'We extract text from your file'),
            ('2', 'AI structures it into a candidate profile'),
            ('3', 'You review and confirm before saving'),
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.$1,
                      style: AppTypography.bold(9, color: colors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: AppTypography.regular(12, color: colors.mutedForeground, height: 1.4),
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
