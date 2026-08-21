import 'package:flutter/material.dart';
import '../../../../core/services/resume_parsing_service.dart';
import '../../../resume/data/datasources/resume_remote_data_source.dart';
import '../../domain/entities/resume_entity.dart';

class ResumeController extends ChangeNotifier {
  final ResumeParsingService _parsingService = MockResumeParsingService();
  final ResumeRemoteDataSource? remoteDataSource;

  ResumeController({this.remoteDataSource});

  List<ResumeEntity> _resumes = [
    ResumeEntity.defaultResume(),
    ResumeEntity.secondaryResume(),
  ];

  String _activeResumeId = 'res_default';
  bool _isParsing = false;
  ParsingProgress? _parsingProgress;
  bool _hasUserUploadedResume = false;

  List<ResumeEntity> get resumes => _resumes;
  bool get isParsing => _isParsing;
  ParsingProgress? get parsingProgress => _parsingProgress;
  bool get hasUserResume => _hasUserUploadedResume;

  ResumeEntity get resume {
    return _resumes.firstWhere(
      (r) => r.id == _activeResumeId,
      orElse: () => _resumes.first,
    );
  }

  void setActiveResume(String id) {
    _activeResumeId = id;
    _resumes = _resumes.map((r) => r.copyWith(isDefault: r.id == id)).toList();
    notifyListeners();
  }

  void deleteResume(String id) {
    if (_resumes.length <= 1) return;
    _resumes.removeWhere((r) => r.id == id);
    if (_activeResumeId == id) {
      _activeResumeId = _resumes.first.id;
      _resumes.first = _resumes.first.copyWith(isDefault: true);
    }
    notifyListeners();
  }

  Future<ResumeEntity> uploadAndParse({
    String fileName = 'Meraj_Senior_Resume.pdf',
    String fileSize = '1.8 MB',
  }) async {
    _isParsing = true;
    _parsingProgress = const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Uploading and extracting document…',
      progressPercent: 0.1,
    );
    notifyListeners();

    final parsedResume = await _parsingService.parseDocument(
      fileName: fileName,
      fileSizeBytes: fileSize,
      onProgress: (progress) {
        _parsingProgress = progress;
        notifyListeners();
      },
    );

    _resumes.insert(0, parsedResume);
    _activeResumeId = parsedResume.id;
    _isParsing = false;
    _parsingProgress = null;
    notifyListeners();

    return parsedResume;
  }

  Future<ResumeEntity> pasteAndParse(String text) async {
    if (text.trim().isEmpty) return resume;

    _isParsing = true;
    _parsingProgress = const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Reading text structure…',
      progressPercent: 0.1,
    );
    notifyListeners();

    final parsedResume = await _parsingService.parseRawText(
      rawText: text,
      onProgress: (progress) {
        _parsingProgress = progress;
        notifyListeners();
      },
    );

    _resumes.insert(0, parsedResume);
    _activeResumeId = parsedResume.id;
    _isParsing = false;
    _parsingProgress = null;
    notifyListeners();

    return parsedResume;
  }

  void updateResume(ResumeEntity updated) {
    final index = _resumes.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _resumes[index] = updated;
      notifyListeners();
    }
  }

  void replaceResume(String oldId, ResumeEntity newResume) {
    final index = _resumes.indexWhere((r) => r.id == oldId);
    if (index != -1) {
      _resumes[index] = newResume;
      if (_activeResumeId == oldId) {
        _activeResumeId = newResume.id;
      }
      notifyListeners();
    }
  }

  void addSkillToActiveResume(String skill) {
    if (skill.trim().isEmpty) return;
    final current = resume;
    if (!current.skills.contains(skill.trim())) {
      final updated = current.copyWith(
        skills: [...current.skills, skill.trim()],
      );
      updateResume(updated);
    }
  }

  void removeSkillFromActiveResume(String skill) {
    final current = resume;
    final updated = current.copyWith(
      skills: current.skills.where((s) => s != skill).toList(),
    );
    updateResume(updated);
  }

  /// Upload a file from the device using file_picker and parse it.
  /// Uses the real API if [remoteDataSource] is injected, otherwise falls back to mock.
  Future<ResumeEntity> uploadFromFilePicker({
    required String fileName,
    String? filePath,
    void Function(double progress)? onProgress,
  }) async {
    _isParsing = true;
    _parsingProgress = const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Uploading resume to AI…',
      progressPercent: 0.1,
    );
    notifyListeners();

    ResumeEntity parsedResume;

    try {
      if (remoteDataSource != null && filePath != null) {
        // ── Real API path ─────────────────────────────────────────
        _parsingProgress = const ParsingProgress(
          stage: ParsingStage.readingDocument,
          stageMessage: 'Sending resume to server…',
          progressPercent: 0.2,
        );
        notifyListeners();

        final profile = await remoteDataSource!.parseResume(
          filePath: filePath,
          fileName: fileName,
          onProgress: (p) {
            onProgress?.call(p);
            _parsingProgress = ParsingProgress(
              stage: p < 0.5
                  ? ParsingStage.readingDocument
                  : p < 0.8
                      ? ParsingStage.extractingSkills
                      : ParsingStage.finalizingProfile,
              stageMessage: p < 0.5
                  ? 'Extracting text from PDF…'
                  : p < 0.8
                      ? 'AI is building your profile…'
                      : 'Finalizing structured profile…',
              progressPercent: p,
            );
            notifyListeners();
          },
        );

        parsedResume = profile.toResumeEntity(
          fileName: fileName,
          fileSize: filePath.isNotEmpty ? '—' : '—',
        );
      } else {
        // ── Mock fallback ─────────────────────────────────────────
        parsedResume = await _parsingService.parseDocument(
          fileName: fileName,
          fileSizeBytes: '—',
          onProgress: (progress) {
            _parsingProgress = progress;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      _isParsing = false;
      _parsingProgress = null;
      notifyListeners();
      rethrow;
    }

    _resumes.insert(0, parsedResume);
    _activeResumeId = parsedResume.id;
    _isParsing = false;
    _parsingProgress = null;
    _hasUserUploadedResume = true;
    notifyListeners();

    return parsedResume;
  }

  /// Add a manually entered profile as a resume.
  void addManualProfile({
    required String candidateName,
    required String targetRole,
    required String experience,
    required List<String> skills,
    required String summary,
  }) {
    final id = 'res_manual_${DateTime.now().millisecondsSinceEpoch}';
    final manualResume = ResumeEntity(
      id: id,
      name: '$candidateName – $targetRole',
      candidateName: candidateName,
      email: '',
      phone: '',
      source: ResumeSource.paste,
      status: ResumeStatus.ready,
      isDefault: true,
      uploadedDate: _formattedToday(),
      fileSize: '—',
      summary: summary,
      skills: skills,
      experience: experience,
      education: '',
      projects: 0,
    );

    _resumes.insert(0, manualResume);
    _activeResumeId = id;
    _resumes = _resumes.map((r) => r.copyWith(isDefault: r.id == id)).toList();
    _hasUserUploadedResume = true;
    notifyListeners();
  }

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
