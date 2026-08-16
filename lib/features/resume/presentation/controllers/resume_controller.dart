import 'package:flutter/material.dart';
import '../../domain/entities/resume_entity.dart';

class ResumeController extends ChangeNotifier {
  ResumeEntity _resume = ResumeEntity.initial();

  ResumeEntity get resume => _resume;

  void updateResume({
    String? name,
    ResumeSource? source,
    ResumeStatus? status,
    List<String>? skills,
    String? experience,
    int? projects,
  }) {
    _resume = _resume.copyWith(
      name: name,
      source: source,
      status: status,
      skills: skills,
      experience: experience,
      projects: projects,
    );
    notifyListeners();
  }

  Future<void> simulateUpload() async {
    updateResume(
      name: 'Meraj_Resume_v2.pdf',
      source: ResumeSource.upload,
      status: ResumeStatus.analyzing,
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    updateResume(
      status: ResumeStatus.ready,
      skills: ['Flutter', 'Dart', 'Riverpod', 'REST APIs', 'Clean Architecture', 'Firebase'],
      experience: '1.5 years',
      projects: 6,
    );
  }

  Future<void> simulatePaste(String text) async {
    if (text.trim().isEmpty) return;
    updateResume(
      name: 'Pasted resume',
      source: ResumeSource.paste,
      status: ResumeStatus.analyzing,
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    updateResume(
      status: ResumeStatus.ready,
      skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Provider', 'Supabase'],
    );
  }
}
