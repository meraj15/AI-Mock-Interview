import 'package:flutter/material.dart';
import '../../domain/entities/interview_config_entity.dart';

class InterviewController extends ChangeNotifier {
  InterviewConfigEntity _config = InterviewConfigEntity.initial();
  bool _interviewActive = false;

  InterviewConfigEntity get config => _config;
  bool get interviewActive => _interviewActive;

  void updateConfig({
    String? role,
    String? company,
    String? experience,
    String? difficulty,
    String? type,
    int? questions,
  }) {
    _config = _config.copyWith(
      role: role,
      company: company,
      experience: experience,
      difficulty: difficulty,
      type: type,
      questions: questions,
    );
    notifyListeners();
  }

  void startInterview() {
    _interviewActive = true;
    notifyListeners();
  }

  void finishInterview() {
    _interviewActive = false;
    notifyListeners();
  }
}
