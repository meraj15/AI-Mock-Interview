import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/ai_interview_service.dart';
import '../../../resume/domain/entities/resume_entity.dart';
import '../../domain/entities/interview_config_entity.dart';
import '../../data/datasources/interview_remote_data_source.dart';


enum SessionStatus { idle, loading, active, followUp, evaluating, complete }

class InterviewSession {
  final List<String> questions;
  final List<String> followUps;
  final List<String> answers;
  final List<String> followUpAnswers;
  final String category;

  const InterviewSession({
    required this.questions,
    required this.followUps,
    required this.answers,
    required this.followUpAnswers,
    required this.category,
  });

  InterviewSession copyWith({
    List<String>? questions,
    List<String>? followUps,
    List<String>? answers,
    List<String>? followUpAnswers,
    String? category,
  }) {
    return InterviewSession(
      questions: questions ?? this.questions,
      followUps: followUps ?? this.followUps,
      answers: answers ?? this.answers,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      category: category ?? this.category,
    );
  }
}

class InterviewController extends ChangeNotifier {
  InterviewConfigEntity _config = InterviewConfigEntity.initial();
  bool _interviewActive = false;
  SessionStatus _sessionStatus = SessionStatus.idle;
  List<AIQuestionPrompt> _prompts = [];
  int _currentIndex = 0;
  bool _isFollowUp = false;
  AIEvaluationResult? _lastEvaluation;

  /// Optional — injected in main.dart. When set, completed sessions are
  /// persisted to the backend automatically.
  final InterviewRemoteDataSource? remoteDataSource;

  /// ApiClient for calling the AI questions endpoint.
  final ApiClient? apiClient;

  /// Callback invoked after a session is saved so the dashboard can refresh.
  void Function()? _onSessionSaved;

  /// Tracks when the current session started (for durationSecs).
  DateTime? _sessionStartedAt;

  final List<Map<String, String>> _sessionHistory = [];

  InterviewController({this.remoteDataSource, this.apiClient});

  /// Called by the ProxyProvider in main.dart to wire the dashboard refresh.
  void setOnSessionSaved(void Function()? callback) {
    _onSessionSaved = callback;
  }

  InterviewConfigEntity get config => _config;
  bool get interviewActive => _interviewActive;
  SessionStatus get sessionStatus => _sessionStatus;
  List<AIQuestionPrompt> get prompts => _prompts;
  int get currentIndex => _currentIndex;
  bool get isFollowUp => _isFollowUp;
  AIEvaluationResult? get lastEvaluation => _lastEvaluation;
  List<Map<String, String>> get sessionHistory => _sessionHistory;

  AIQuestionPrompt? get currentPrompt =>
      _prompts.isNotEmpty && _currentIndex < _prompts.length ? _prompts[_currentIndex] : null;

  String get currentQuestion {
    if (_prompts.isEmpty || _currentIndex >= _prompts.length) return '';
    return _isFollowUp ? _prompts[_currentIndex].followUpQuestion : _prompts[_currentIndex].primaryQuestion;
  }

  String get currentContextHint {
    if (_prompts.isEmpty || _currentIndex >= _prompts.length) return '';
    return _prompts[_currentIndex].contextHint;
  }

  String get currentCategory {
    if (_prompts.isEmpty || _currentIndex >= _prompts.length) return '';
    return _prompts[_currentIndex].category;
  }

  int get questionNumber => _currentIndex + 1;
  int get totalQuestions => _config.questions;

  void updateConfig({
    String? role,
    String? company,
    String? experience,
    String? difficulty,
    int? questions,
    List<String>? focusTopics,
    String? language,
    bool? enableVoiceMode,
    String? aiPersona,
    int? timeLimitPerQuestion,
    bool? showHints,
    bool? enableFollowUps,
    String? codingLanguage,
  }) {
    _config = _config.copyWith(
      role: role,
      company: company,
      experience: experience,
      difficulty: difficulty,
      questions: questions,
      focusTopics: focusTopics,
      language: language,
      enableVoiceMode: enableVoiceMode,
      aiPersona: aiPersona,
      timeLimitPerQuestion: timeLimitPerQuestion,
      showHints: showHints,
      enableFollowUps: enableFollowUps,
      codingLanguage: codingLanguage,
    );
    notifyListeners();
  }

  Future<void> startInterview({ResumeEntity? resume}) async {
    _interviewActive = true;
    _sessionStatus = SessionStatus.loading;
    _currentIndex = 0;
    _isFollowUp = false;
    _sessionHistory.clear();
    _sessionStartedAt = DateTime.now();

    // Seed role + skills from the user's profile into the config
    if (resume != null) {
      final profileRole = resume.name.contains('–')
          ? resume.name.split('–').last.trim()
          : resume.skills.isNotEmpty
              ? _inferRoleFromSkills(resume.skills)
              : _config.role;
      _config = _config.copyWith(
        role: _config.role.isNotEmpty &&
                _config.role != InterviewConfigEntity.initial().role
            ? _config.role
            : profileRole,
        experience: resume.experience.isNotEmpty ? resume.experience : _config.experience,
        skills: resume.skills.isNotEmpty ? resume.skills : _config.skills,
      );
    }

    notifyListeners();

    // Use real Gemini service when apiClient is available, fallback to mock
    final AIInterviewService ai = apiClient != null
        ? GeminiAIInterviewService(apiClient: apiClient!)
        : MockAIInterviewService();

    try {
      _prompts = await ai.generateQuestions(
        config: _config,
        resume: resume ?? ResumeEntity.defaultResume(),
      );
    } catch (_) {
      // If real API fails, fall back to mock so the session always starts
      _prompts = await MockAIInterviewService().generateQuestions(
        config: _config,
        resume: resume ?? ResumeEntity.defaultResume(),
      );
    }

    if (_prompts.length > _config.questions) {
      _prompts = _prompts.sublist(0, _config.questions);
    }

    _sessionStatus = SessionStatus.active;
    notifyListeners();
  }

  /// Simple heuristic: pick a role label from known skill keywords.
  String _inferRoleFromSkills(List<String> skills) {
    final s = skills.map((e) => e.toLowerCase()).toList();
    if (s.any((e) => e.contains('flutter') || e.contains('dart'))) return 'Flutter Developer';
    if (s.any((e) => e.contains('react') || e.contains('next'))) return 'Frontend Engineer';
    if (s.any((e) => e.contains('node') || e.contains('express') || e.contains('nestjs'))) return 'Backend Engineer';
    if (s.any((e) => e.contains('python') || e.contains('django') || e.contains('fastapi'))) return 'Python Developer';
    if (s.any((e) => e.contains('android') || e.contains('kotlin'))) return 'Android Developer';
    if (s.any((e) => e.contains('ios') || e.contains('swift'))) return 'iOS Developer';
    if (s.any((e) => e.contains('data') || e.contains('ml') || e.contains('tensorflow'))) return 'Data / ML Engineer';
    return _config.role;
  }

  void submitAnswer(String answer) {
    if (_isFollowUp) {
      // Store follow-up answer and move to next question
      _sessionHistory.add({
        'question': currentPrompt?.primaryQuestion ?? '',
        'followUp': currentPrompt?.followUpQuestion ?? '',
        'answer': answer,
        'category': currentCategory,
      });
      _isFollowUp = false;

      if (_currentIndex < _prompts.length - 1) {
        _currentIndex++;
        _sessionStatus = SessionStatus.active;
      } else {
        _sessionStatus = SessionStatus.evaluating;
        _interviewActive = false;
        _generateEvaluation();
      }
    } else {
      // Show follow-up
      _isFollowUp = true;
      _sessionStatus = SessionStatus.followUp;
    }
    notifyListeners();
  }

  Future<void> _generateEvaluation() async {
    final ai = MockAIInterviewService();
    _lastEvaluation = await ai.evaluateInterview(
      config: _config,
      questions: _prompts.map((p) => p.primaryQuestion).toList(),
      answers: _sessionHistory.map((h) => h['answer'] ?? '').toList(),
    );
    _sessionStatus = SessionStatus.complete;
    notifyListeners();

    // ── Persist to backend (fire-and-forget, does not block UI) ──────────
    _persistSession();
  }

  /// Saves the completed session to the backend.
  /// Errors are silently swallowed so a network failure never breaks the UI.
  Future<void> _persistSession() async {
    if (remoteDataSource == null || _lastEvaluation == null) return;

    final durationSecs = _sessionStartedAt != null
        ? DateTime.now().difference(_sessionStartedAt!).inSeconds
        : 0;

    try {
      await remoteDataSource!.saveSession(
        SaveInterviewRequest(
          role:           _config.role,
          difficulty:     _config.difficulty,
          questionCount:  _config.questions,
          score:          _lastEvaluation!.overallScore,
          hiringBand:     _lastEvaluation!.hiringBand,
          summary:        _lastEvaluation!.summary,
          strengths:      _lastEvaluation!.strengths,
          areasToImprove: _lastEvaluation!.areasToImprove,
          skillScores:    _lastEvaluation!.skillScores,
          durationSecs:   durationSecs,
        ),
      );
      // Tell the dashboard controller to refresh its stats
      _onSessionSaved?.call();
    } catch (_) {
      // Network failures must not disrupt the result screen
    }
  }

  void finishInterview() {
    _interviewActive = false;
    _sessionStatus = SessionStatus.evaluating;
    notifyListeners();
  }

  void reset() {
    _config = InterviewConfigEntity.initial();
    _interviewActive = false;
    _sessionStatus = SessionStatus.idle;
    _prompts = [];
    _currentIndex = 0;
    _isFollowUp = false;
    _lastEvaluation = null;
    _sessionHistory.clear();
    notifyListeners();
  }
}
