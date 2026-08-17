import 'package:flutter/material.dart';
import '../../../../core/services/resume_parsing_service.dart';
import '../../domain/entities/resume_entity.dart';

class ResumeController extends ChangeNotifier {
  final ResumeParsingService _parsingService = MockResumeParsingService();

  List<ResumeEntity> _resumes = [
    ResumeEntity.defaultResume(),
    ResumeEntity.secondaryResume(),
  ];

  String _activeResumeId = 'res_default';
  bool _isParsing = false;
  ParsingProgress? _parsingProgress;

  List<ResumeEntity> get resumes => _resumes;
  bool get isParsing => _isParsing;
  ParsingProgress? get parsingProgress => _parsingProgress;

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
}
