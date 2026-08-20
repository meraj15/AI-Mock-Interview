import 'package:feather_icons/feather_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../controllers/resume_controller.dart';
import 'edit_parsed_resume_page.dart';

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
  int _selectedTab = 0; // 0: Upload File, 1: Paste Text
  final _pasteController = TextEditingController();
  String _selectedFileName = 'No file selected';
  String _selectedFileSize = '';
  bool _fileSelected = false;

  /// Opens the native file picker and picks a PDF/DOC/DOCX file
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // load bytes into memory (no permanent storage)
      );

      if (result == null || result.files.isEmpty) return; // user cancelled

      final file = result.files.first;
      final name = file.name;
      final sizeBytes = file.size;
      final sizeLabel = sizeBytes >= 1048576
          ? '${(sizeBytes / 1048576).toStringAsFixed(1)} MB'
          : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';

      setState(() {
        _selectedFileName = name;
        _selectedFileSize = sizeLabel;
        _fileSelected = true;
      });

      // Auto-start parsing right after file selection
      _startFileUpload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  void _startFileUpload() async {
    final resumeCtrl = context.read<ResumeController>();
    final parsed = await resumeCtrl.uploadAndParse(
      fileName: _selectedFileName,
      fileSize: _selectedFileSize,
    );

    if (widget.isReplacing && widget.replaceId != null) {
      resumeCtrl.replaceResume(widget.replaceId!, parsed);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EditParsedResumePage(resume: parsed),
        ),
      );
    }
  }

  void _startTextParse() async {
    if (_pasteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your resume text before proceeding.')),
      );
      return;
    }

    final resumeCtrl = context.read<ResumeController>();
    final parsed = await resumeCtrl.pasteAndParse(_pasteController.text.trim());

    if (widget.isReplacing && widget.replaceId != null) {
      resumeCtrl.replaceResume(widget.replaceId!, parsed);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EditParsedResumePage(resume: parsed),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final resumeCtrl = context.watch<ResumeController>();
    final isParsing = resumeCtrl.isParsing;
    final progress = resumeCtrl.parsingProgress;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: widget.isReplacing ? 'Replace Resume' : 'Add Resume',
            subtitle: 'AI Parsing Engine',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          // Parsing Live State Overlay
          if (isParsing && progress != null) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Analyzing & Parsing Resume',
                    style: AppTypography.bold(18, color: colors.foreground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progress.stageMessage,
                    style: AppTypography.regular(12, color: colors.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  ProgressBar(
                    value: progress.progressPercent * 100,
                    height: 6,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress.progressPercent * 100).toInt()}% completed',
                    style: AppTypography.bold(11, color: colors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ] else ...[
            // Tab Switcher
            Container(
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? colors.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Upload File (PDF/DOC)',
                          style: AppTypography.semiBold(
                            12,
                            color: _selectedTab == 0 ? colors.foreground : colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? colors.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Paste Text',
                          style: AppTypography.semiBold(
                            12,
                            color: _selectedTab == 1 ? colors.foreground : colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_selectedTab == 0) ...[
              // Upload File Dropzone
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                     alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _fileSelected
                                ? colors.success.withValues(alpha: 0.1)
                                : colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _fileSelected ? FeatherIcons.checkCircle : FeatherIcons.uploadCloud,
                            size: 26,
                            color: _fileSelected ? colors.success : colors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _fileSelected ? 'File Selected' : 'Tap to browse & upload',
                          style: AppTypography.bold(16, color: colors.foreground),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fileSelected
                              ? 'Tap again to choose a different file'
                              : 'PDF, DOC or DOCX supported',
                          style: AppTypography.regular(11, color: colors.mutedForeground),
                        ),

                        if (_fileSelected) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.success.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FeatherIcons.fileText, size: 14, color: colors.success),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _selectedFileSize.isNotEmpty
                                        ? '$_selectedFileName  •  $_selectedFileSize'
                                        : _selectedFileName,
                                    style: AppTypography.semiBold(11, color: colors.success),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              AppButton(
                label: _fileSelected ? 'Parse & Verify Resume' : 'Browse & Choose File',
                icon: _fileSelected ? FeatherIcons.arrowRight : FeatherIcons.folder,
                onPress: _fileSelected ? _startFileUpload : _pickFile,
              ),
            ] else ...[
              // Paste Text View
              Text(
                'Paste Resume Content',
                style: AppTypography.semiBold(12, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _pasteController,
                placeholder: 'Paste your full resume summary, skills, experience history, and projects here…',
                multiline: true,
                minLines: 8,
                maxLines: 12,
              ),

              const SizedBox(height: 16),

              AppButton(
                label: 'Extract & Structure Resume',
                icon: FeatherIcons.cpu,
                onPress: _startTextParse,
              ),
            ],
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}
