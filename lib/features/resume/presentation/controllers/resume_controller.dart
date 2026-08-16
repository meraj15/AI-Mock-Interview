import 'package:flutter/material.dart';
import '../../domain/entities/resume_entity.dart';

class ResumeController extends ChangeNotifier {
  List<ResumeEntity> _resumes = [
    ResumeEntity.defaultResume(),
    ResumeEntity.secondaryResume(),
  ];

  String _activeResumeId = 'res_default';

  List<ResumeEntity> get resumes => _resumes;

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
    if (_resumes.length <= 1) return; // Keep at least one
    _resumes.removeWhere((r) => r.id == id);
    if (_activeResumeId == id) {
      _activeResumeId = _resumes.first.id;
      _resumes.first = _resumes.first.copyWith(isDefault: true);
    }
    notifyListeners();
  }

  Future<void> simulateUpload({String? customName}) async {
    final newId = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final newResume = ResumeEntity(
      id: newId,
      name: customName ?? 'Meraj_Senior_Resume.pdf',
      source: ResumeSource.upload,
      status: ResumeStatus.analyzing,
      isDefault: true,
      skills: ['Flutter', 'Dart', 'Riverpod', 'Clean Architecture', 'REST APIs', 'Firebase'],
      experience: '2.5 years',
      projects: 7,
    );

    _resumes.insert(0, newResume);
    _activeResumeId = newId;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    final index = _resumes.indexWhere((r) => r.id == newId);
    if (index != -1) {
      _resumes[index] = _resumes[index].copyWith(
        status: ResumeStatus.ready,
        skills: ['Flutter', 'Dart', 'Riverpod', 'Clean Architecture', 'REST APIs', 'Firebase', 'GraphQL', 'CI/CD'],
        frameworks: ['Flutter SDK', 'Riverpod', 'BLoC', 'Fastlane'],
        databases: ['Firebase', 'PostgreSQL', 'SQLite'],
        tools: ['Git', 'Docker', 'Postman', 'Figma'],
        experience: '2.5 years',
        projects: 7,
      );
      notifyListeners();
    }
  }

  Future<void> simulatePaste(String text) async {
    if (text.trim().isEmpty) return;
    final newId = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final newResume = ResumeEntity(
      id: newId,
      name: 'Pasted_Text_Resume.txt',
      source: ResumeSource.paste,
      status: ResumeStatus.analyzing,
      isDefault: true,
      summary: text.length > 120 ? '${text.substring(0, 120)}...' : text,
      skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase'],
      experience: '1.5 years',
      projects: 4,
    );

    _resumes.insert(0, newResume);
    _activeResumeId = newId;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    final index = _resumes.indexWhere((r) => r.id == newId);
    if (index != -1) {
      _resumes[index] = _resumes[index].copyWith(
        status: ResumeStatus.ready,
        skills: ['Flutter', 'Dart', 'State Management', 'REST APIs', 'Firebase', 'SQL'],
        experience: '1.8 years',
        projects: 5,
      );
      notifyListeners();
    }
  }
}
