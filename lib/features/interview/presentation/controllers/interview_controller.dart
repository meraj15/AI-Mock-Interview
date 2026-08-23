import 'package:flutter/material.dart';
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

  /// Callback invoked after a session is saved so the dashboard can refresh.
  /// Mutable so the ProxyProvider can wire it after construction.
  void Function()? _onSessionSaved;

  /// Tracks when the current session started (for durationSecs).
  DateTime? _sessionStartedAt;

  // Track all answers for session review
  final List<Map<String, String>> _sessionHistory = [];

  InterviewController({this.remoteDataSource});

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
    String? type,
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
      type: type,
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
    notifyListeners();

    final ai = MockAIInterviewService();
    _prompts = await ai.generateQuestions(
      config: _config,
      resume: resume ?? ResumeEntity.defaultResume(),
    );

    // Clamp prompts to configured question count
    if (_prompts.length > _config.questions) {
      _prompts = _prompts.sublist(0, _config.questions);
    }

    _sessionStatus = SessionStatus.active;
    notifyListeners();
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
          type:           _config.type,
          difficulty:     _config.difficulty,
          questionCount:  _config.questions,
          score:          _lastEvaluation!.overallScore,
          hiringBand:     _lastEvaluation!.hiringBand,
          summary:        _lastEvaluation!.summary,
          strengths:      _lastEvaluation!.strengths,
          areasToImprove: _lastEvaluation!.areasToImprove,
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
