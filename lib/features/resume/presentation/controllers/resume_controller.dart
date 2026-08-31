import 'dart:io';

import 'package:flutter/material.dart';
import '../../../resume/data/datasources/resume_remote_data_source.dart';
import '../../domain/entities/resume_entity.dart';

enum ParsingStage {
  readingDocument,
  extractingSkills,
  analyzingExperience,
  finalizingProfile,
  completed,
}

class ParsingProgress {
  final ParsingStage stage;
  final String stageMessage;
  final double progressPercent;

  const ParsingProgress({
    required this.stage,
    required this.stageMessage,
    required this.progressPercent,
  });
}

class ResumeController extends ChangeNotifier {
  final ResumeRemoteDataSource? remoteDataSource;

  ResumeController({this.remoteDataSource});

  List<ResumeEntity> _resumes = [];

  String? _activeResumeId;
  bool _isParsing = false;
  ParsingProgress? _parsingProgress;
  bool _hasUserUploadedResume = false;

  List<ResumeEntity> get resumes => _resumes;
  bool get isParsing => _isParsing;
  ParsingProgress? get parsingProgress => _parsingProgress;
  bool get hasUserResume => _hasUserUploadedResume || _resumes.isNotEmpty;

  ResumeEntity? get resume {
    if (_resumes.isEmpty) return null;
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
    if (_resumes.isEmpty) return;
    _resumes.removeWhere((r) => r.id == id);
    if (_activeResumeId == id) {
      _activeResumeId = _resumes.isNotEmpty ? _resumes.first.id : null;
      if (_resumes.isNotEmpty) {
        _resumes.first = _resumes.first.copyWith(isDefault: true);
      }
    }
    notifyListeners();
  }

  Future<ResumeEntity> pasteAndParse(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Resume text cannot be empty.');
    }

    _isParsing = true;
    _parsingProgress = const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Structuring text profile…',
      progressPercent: 0.2,
    );
    notifyListeners();

    try {
      final newId = 'res_paste_${DateTime.now().millisecondsSinceEpoch}';
      final summary = text.length > 200 ? '${text.substring(0, 200)}…' : text;

      final parsedResume = ResumeEntity(
        id: newId,
        name: 'Pasted Text Profile',
        candidateName: '',
        email: '',
        phone: '',
        source: ResumeSource.paste,
        status: ResumeStatus.ready,
        isDefault: true,
        uploadedDate: _formattedToday(),
        fileSize: '${(text.length / 1024).toStringAsFixed(1)} KB',
        summary: summary,
        skills: [],
        experience: 'Not specified',
        education: '',
        projects: 0,
        confidenceScore: 85,
      );

      _resumes.insert(0, parsedResume);
      _activeResumeId = parsedResume.id;
      _isParsing = false;
      _parsingProgress = null;
      _hasUserUploadedResume = true;
      notifyListeners();
      return parsedResume;
    } catch (e) {
      _isParsing = false;
      _parsingProgress = null;
      notifyListeners();
      rethrow;
    }
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
    if (skill.trim().isEmpty || resume == null) return;
    final current = resume!;
    if (!current.skills.contains(skill.trim())) {
      final updated = current.copyWith(
        skills: [...current.skills, skill.trim()],
      );
      updateResume(updated);
    }
  }

  void removeSkillFromActiveResume(String skill) {
    if (resume == null) return;
    final current = resume!;
    final updated = current.copyWith(
      skills: current.skills.where((s) => s != skill).toList(),
    );
    updateResume(updated);
  }

  /// Upload a file from the device and parse it via the backend Gemini service.
  Future<ResumeEntity> uploadFromFilePicker({
    required String fileName,
    String? filePath,
    void Function(double progress)? onProgress,
  }) async {
    if (remoteDataSource == null || filePath == null) {
      throw Exception('Backend resume parsing service is not available or file path is invalid.');
    }

    _isParsing = true;
    _parsingProgress = const ParsingProgress(
      stage: ParsingStage.readingDocument,
      stageMessage: 'Uploading resume to AI…',
      progressPercent: 0.1,
    );
    notifyListeners();

    ResumeEntity parsedResume;

    try {
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
                    ? 'Gemini is building your profile…'
                    : 'Finalizing structured profile…',
            progressPercent: p,
          );
          notifyListeners();
        },
      );

      String fileSize = '—';
      try {
        fileSize = await _readableFileSize(filePath);
      } catch (_) {}

      parsedResume = profile.toResumeEntity(
        fileName: fileName,
        fileSize: fileSize,
      );
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

  Future<String> _readableFileSize(String filePath) async {
    try {
      final bytes = await File(filePath).length();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '—';
    }
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
