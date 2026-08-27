import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/ai_interview_service.dart';
import '../../../resume/domain/entities/resume_entity.dart';
import '../../domain/entities/interview_config_entity.dart';
import '../../data/datasources/interview_remote_data_source.dart';

enum SessionStatus { idle, loading, active, followUp, evaluating, complete, error }

class InterviewController extends ChangeNotifier {
  InterviewConfigEntity _config = InterviewConfigEntity.initial();
  bool _interviewActive = false;
  SessionStatus _sessionStatus = SessionStatus.idle;
  String? _errorMessage;

  String? _sessionId;
  List<InterviewTopic> _topics = [];
  String _currentQuestion = '';
  String _currentAcknowledgement = '';
  String _currentTopic = '';
  int _currentTopicIndex = 0;
  int _totalTopics = 5;
  bool _isFollowUp = false;
  bool _isComplete = false;

  AIEvaluationResult? _lastEvaluation;

  /// Optional — injected in main.dart.
  final InterviewRemoteDataSource? remoteDataSource;

  /// ApiClient for calling the backend AI interview endpoints.
  final ApiClient? apiClient;

  /// Callback invoked after a session is saved so the dashboard can refresh.
  void Function()? _onSessionSaved;

  final List<Map<String, String>> _sessionHistory = [];

  InterviewController({this.remoteDataSource, this.apiClient});

  /// Called by ProxyProvider to wire dashboard refresh.
  void setOnSessionSaved(void Function()? callback) {
    _onSessionSaved = callback;
  }

  InterviewConfigEntity get config => _config;
  bool get interviewActive => _interviewActive;
  SessionStatus get sessionStatus => _sessionStatus;
  String? get errorMessage => _errorMessage;
  String? get sessionId => _sessionId;
  List<InterviewTopic> get topics => _topics;

  String get currentQuestion => _currentQuestion;
  String get currentAcknowledgement => _currentAcknowledgement;
  String get currentCategory => _currentTopic.isNotEmpty ? _currentTopic : 'General';
  String get currentContextHint => _topics.isNotEmpty && _currentTopicIndex < _topics.length
      ? _topics[_currentTopicIndex].objective
      : '';

  int get currentIndex => _currentTopicIndex;
  int get questionNumber => _currentTopicIndex + 1;
  int get totalQuestions => _totalTopics;
  bool get isFollowUp => _isFollowUp;
  bool get isComplete => _isComplete;

  AIEvaluationResult? get lastEvaluation => _lastEvaluation;
  List<Map<String, String>> get sessionHistory => _sessionHistory;

  // Non-empty placeholder so existing guards recognize session has questions
  List<String> get prompts => _currentQuestion.isNotEmpty ? [_currentQuestion] : [];

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

  /// STAGE 1: Start Conversational Interview
  Future<void> startInterview({ResumeEntity? resume}) async {
    _interviewActive = true;
    _sessionStatus = SessionStatus.loading;
    _errorMessage = null;
    _currentQuestion = '';
    _currentAcknowledgement = '';
    _currentTopic = '';
    _currentTopicIndex = 0;
    _totalTopics = _config.questions > 0 ? _config.questions : 5;
    _isFollowUp = false;
    _isComplete = false;
    _topics = [];
    _sessionHistory.clear();

    // Seed role + skills from resume if provided
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

    if (apiClient == null) {
      const err = 'Backend API client is not configured.';
      debugPrint('[InterviewController] ERROR: $err');
      _errorMessage = err;
      _sessionStatus = SessionStatus.error;
      _interviewActive = false;
      notifyListeners();
      return;
    }

    final ai = GeminiAIInterviewService(apiClient: apiClient!);

    try {
      debugPrint('[InterviewController] Starting live conversational interview for "${_config.role}"...');
      final startResult = await ai.startConversationalInterview(
        config: _config,
        resume: resume ?? ResumeEntity.defaultResume(),
      );

      _sessionId = startResult.sessionId;
      _topics = startResult.topics;
      _currentTopic = startResult.currentTopic;
      _currentTopicIndex = startResult.currentTopicIndex;
      _totalTopics = startResult.totalTopics;
      _currentQuestion = startResult.firstQuestion;
      _currentAcknowledgement = '';
      _isComplete = false;
      _sessionStatus = SessionStatus.active;
      _errorMessage = null;

      debugPrint('[InterviewController] Session started: $_sessionId, Q1: "$_currentQuestion"');
    } catch (e, stackTrace) {
      final cleanError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('[InterviewController] START INTERVIEW FAILED: $cleanError\n$stackTrace');
      _errorMessage = cleanError;
      _sessionStatus = SessionStatus.error;
      _interviewActive = false;
    }

    notifyListeners();
  }

  /// STAGE 2: Submit candidate answer and transition conversational turn
  Future<void> submitAnswer(String answer) async {
    if (_sessionId == null || apiClient == null) {
      debugPrint('[InterviewController] submitAnswer called without active session');
      return;
    }

    _sessionStatus = SessionStatus.loading;
    notifyListeners();

    _sessionHistory.add({
      'topic': _currentTopic,
      'question': _currentQuestion,
      'answer': answer,
      'type': _isFollowUp ? 'follow_up' : 'primary',
    });

    final ai = GeminiAIInterviewService(apiClient: apiClient!);

    try {
      final turn = await ai.submitConversationalAnswer(
        sessionId: _sessionId!,
        answer: answer,
      );

      _isFollowUp = turn.action == 'follow_up';
      _currentAcknowledgement = turn.acknowledgement;
      _currentQuestion = turn.nextQuestion;
      _currentTopic = turn.nextTopic;
      _currentTopicIndex = turn.currentTopicIndex;
      _totalTopics = turn.totalTopics;
      _isComplete = turn.isComplete;

      if (turn.isComplete || turn.action == 'end_interview') {
        _sessionStatus = SessionStatus.evaluating;
        _interviewActive = false;
        notifyListeners();
        await _fetchFinalEvaluation();
        return;
      } else {
        _sessionStatus = _isFollowUp ? SessionStatus.followUp : SessionStatus.active;
      }
    } catch (e, stackTrace) {
      debugPrint('[InterviewController] submitAnswer error: $e\n$stackTrace');
      // If error occurs, attempt to fetch evaluation if turns were already recorded
      if (_sessionHistory.length >= 3) {
        _sessionStatus = SessionStatus.evaluating;
        _interviewActive = false;
        notifyListeners();
        await _fetchFinalEvaluation();
        return;
      } else {
        _errorMessage = e.toString();
        _sessionStatus = SessionStatus.error;
      }
    }

    notifyListeners();
  }

  /// STAGE 3: Final evaluation retrieval
  Future<void> _fetchFinalEvaluation() async {
    if (_sessionId == null || apiClient == null) return;

    final ai = GeminiAIInterviewService(apiClient: apiClient!);

    try {
      debugPrint('[InterviewController] Fetching final evaluation from backend...');
      _lastEvaluation = await ai.getFinalEvaluation(
        sessionId: _sessionId!,
        config: _config,
      );
      _sessionStatus = SessionStatus.complete;
      _onSessionSaved?.call();
    } catch (e, stackTrace) {
      debugPrint('[InterviewController] _fetchFinalEvaluation error: $e\n$stackTrace');
      _errorMessage = e.toString();
      _sessionStatus = SessionStatus.error;
    }

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

  void finishInterview() {
    _interviewActive = false;
    _sessionStatus = SessionStatus.evaluating;
    notifyListeners();
    _fetchFinalEvaluation();
  }

  void reset() {
    _config = InterviewConfigEntity.initial();
    _interviewActive = false;
    _sessionStatus = SessionStatus.idle;
    _errorMessage = null;
    _sessionId = null;
    _topics = [];
    _currentQuestion = '';
    _currentAcknowledgement = '';
    _currentTopic = '';
    _currentTopicIndex = 0;
    _totalTopics = 5;
    _isFollowUp = false;
    _isComplete = false;
    _lastEvaluation = null;
    _sessionHistory.clear();
    notifyListeners();
  }
}
