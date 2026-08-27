import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../features/interview/domain/entities/interview_config_entity.dart';
import '../../features/resume/domain/entities/resume_entity.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class InterviewTopic {
  final String name;
  final String objective;

  const InterviewTopic({
    required this.name,
    required this.objective,
  });

  factory InterviewTopic.fromJson(Map<String, dynamic> j) => InterviewTopic(
        name: j['name'] as String? ?? 'General',
        objective: j['objective'] as String? ?? '',
      );
}

class ConversationalStartResult {
  final String sessionId;
  final String role;
  final List<InterviewTopic> topics;
  final String currentTopic;
  final int currentTopicIndex;
  final int totalTopics;
  final String firstQuestion;

  const ConversationalStartResult({
    required this.sessionId,
    required this.role,
    required this.topics,
    required this.currentTopic,
    required this.currentTopicIndex,
    required this.totalTopics,
    required this.firstQuestion,
  });

  factory ConversationalStartResult.fromJson(Map<String, dynamic> j) {
    final rawTopics = j['topics'] as List<dynamic>? ?? [];
    return ConversationalStartResult(
      sessionId: j['sessionId'] as String? ?? '',
      role: j['role'] as String? ?? '',
      topics: rawTopics
          .whereType<Map<String, dynamic>>()
          .map(InterviewTopic.fromJson)
          .toList(),
      currentTopic: j['currentTopic'] as String? ?? 'Introduction',
      currentTopicIndex: (j['currentTopicIndex'] as num?)?.toInt() ?? 0,
      totalTopics: (j['totalTopics'] as num?)?.toInt() ?? 1,
      firstQuestion: j['firstQuestion'] as String? ?? '',
    );
  }
}

class ConversationalTurnResult {
  final String acknowledgement;
  final String action; // 'follow_up' | 'new_topic' | 'end_interview'
  final String nextQuestion;
  final String nextTopic;
  final int currentTopicIndex;
  final int totalTopics;
  final bool isComplete;

  const ConversationalTurnResult({
    required this.acknowledgement,
    required this.action,
    required this.nextQuestion,
    required this.nextTopic,
    required this.currentTopicIndex,
    required this.totalTopics,
    required this.isComplete,
  });

  factory ConversationalTurnResult.fromJson(Map<String, dynamic> j) {
    return ConversationalTurnResult(
      acknowledgement: j['acknowledgement'] as String? ?? '',
      action: j['action'] as String? ?? 'new_topic',
      nextQuestion: j['nextQuestion'] as String? ?? '',
      nextTopic: j['nextTopic'] as String? ?? '',
      currentTopicIndex: (j['currentTopicIndex'] as num?)?.toInt() ?? 0,
      totalTopics: (j['totalTopics'] as num?)?.toInt() ?? 1,
      isComplete: j['isComplete'] as bool? ?? false,
    );
  }
}

class QuestionReview {
  final String question;
  final String answer;
  final String feedback;
  final int score;

  const QuestionReview({
    required this.question,
    required this.answer,
    required this.feedback,
    required this.score,
  });

  factory QuestionReview.fromJson(Map<String, dynamic> j) => QuestionReview(
        question: j['question'] as String? ?? '',
        answer: j['answer'] as String? ?? '',
        feedback: j['feedback'] as String? ?? '',
        score: (j['score'] as num?)?.toInt() ?? 75,
      );
}

class RoleBenchmark {
  final int percentile;
  final int industryAverageScore;
  final String readinessLevel;
  final String companyCultureAlignment;

  const RoleBenchmark({
    required this.percentile,
    required this.industryAverageScore,
    required this.readinessLevel,
    required this.companyCultureAlignment,
  });
}

class AIEvaluationResult {
  final int overallScore;
  final String performanceLabel;
  final String hiringBand;
  final RoleBenchmark benchmark;
  final Map<String, int> skillScores;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<String> recommendedTopics;
  final List<QuestionReview> questionReviews;
  List<QuestionReview> get questionEvaluations => questionReviews;
  final String summary;

  const AIEvaluationResult({
    required this.overallScore,
    required this.performanceLabel,
    required this.hiringBand,
    required this.benchmark,
    required this.skillScores,
    required this.strengths,
    required this.areasToImprove,
    required this.recommendedTopics,
    required this.questionReviews,
    required this.summary,
  });

  factory AIEvaluationResult.fromJson(
    Map<String, dynamic> j, {
    required InterviewConfigEntity config,
  }) {
    final rawScores = j['skillPerformance'] as Map<String, dynamic>? ?? {};
    final skillScores = rawScores.map((k, v) => MapEntry(k, (v as num).toInt()));

    final rawStrengths = (j['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rawAreas = (j['areasToImprove'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rawRecs = (j['recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rawReviews = (j['questionReviews'] as List?) ?? [];

    final overall = (j['overallScore'] as num?)?.toInt() ?? 75;
    final level = j['performanceLevel'] as String? ?? 'Good';
    final summary = j['summary'] as String? ?? '';

    final benchmark = RoleBenchmark(
      percentile: overall >= 85 ? 90 : overall >= 75 ? 82 : 68,
      industryAverageScore: 72,
      readinessLevel: level,
      companyCultureAlignment: 'Strong alignment with ${config.company.isNotEmpty ? config.company : "target role"} criteria.',
    );

    final hiringBand = overall >= 85
        ? 'Strong Hire'
        : overall >= 75
            ? 'Hire'
            : overall >= 65
                ? 'Leaning Hire'
                : 'Needs Practice';

    return AIEvaluationResult(
      overallScore: overall,
      performanceLabel: level,
      hiringBand: hiringBand,
      benchmark: benchmark,
      skillScores: skillScores.isNotEmpty
          ? skillScores
          : {
              'Technical Knowledge': overall,
              'Communication & Clarity': overall,
              'Problem Solving': overall,
              'Architecture & Design': overall,
              'Role Mastery': overall,
            },
      strengths: rawStrengths.isNotEmpty
          ? rawStrengths
          : ['Demonstrated clear domain concepts and structured answers.'],
      areasToImprove: rawAreas.isNotEmpty
          ? rawAreas
          : ['Add more quantified metrics and explore edge cases.'],
      recommendedTopics: rawRecs,
      questionReviews: rawReviews
          .whereType<Map<String, dynamic>>()
          .map(QuestionReview.fromJson)
          .toList(),
      summary: summary,
    );
  }
}

// ── Abstract service ──────────────────────────────────────────────────────────

abstract class AIInterviewService {
  Future<ConversationalStartResult> startConversationalInterview({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  });

  Future<ConversationalTurnResult> submitConversationalAnswer({
    required String sessionId,
    required String answer,
  });

  Future<AIEvaluationResult> getFinalEvaluation({
    required String sessionId,
    required InterviewConfigEntity config,
  });
}

// ── Real Gemini-backed service ────────────────────────────────────────────────

class GeminiAIInterviewService implements AIInterviewService {
  final ApiClient apiClient;

  GeminiAIInterviewService({required this.apiClient});

  @override
  Future<ConversationalStartResult> startConversationalInterview({
    required InterviewConfigEntity config,
    required ResumeEntity resume,
  }) async {
    final skills = config.skills.isNotEmpty
        ? config.skills
        : resume.skills.isNotEmpty
            ? resume.skills
            : [config.role];

    final requestBody = {
      'role': config.role,
      'skills': skills,
      'difficulty': config.difficulty,
      'questionCount': config.questions,
      if (config.experience.isNotEmpty) 'experience': config.experience,
    };

    debugPrint('======================================================');
    debugPrint('[GeminiAIInterviewService] Starting Conversational Interview');
    debugPrint('  Endpoint: ${ApiConfig.interviewStartEndpoint}');
    debugPrint('  Payload:  $requestBody');
    debugPrint('======================================================');

    try {
      final response = await apiClient.post(
        ApiConfig.interviewStartEndpoint,
        body: requestBody,
        requiresAuth: true,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final startResult = ConversationalStartResult.fromJson(inner);
      debugPrint('[GeminiAIInterviewService] Started session: ${startResult.sessionId}, topics: ${startResult.topics.length}');
      debugPrint('  First question: "${startResult.firstQuestion}"');

      return startResult;
    } catch (e, stackTrace) {
      debugPrint('[GeminiAIInterviewService] ERROR Starting Conversational Interview: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<ConversationalTurnResult> submitConversationalAnswer({
    required String sessionId,
    required String answer,
  }) async {
    final requestBody = {
      'answer': answer,
    };

    final endpoint = ApiConfig.interviewAnswerEndpoint(sessionId);

    debugPrint('======================================================');
    debugPrint('[GeminiAIInterviewService] Submitting Answer for Turn');
    debugPrint('  Endpoint: $endpoint');
    debugPrint('  Answer: "$answer"');
    debugPrint('======================================================');

    try {
      final response = await apiClient.post(
        endpoint,
        body: requestBody,
        requiresAuth: true,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final turnResult = ConversationalTurnResult.fromJson(inner);
      debugPrint('[GeminiAIInterviewService] Turn result: action=${turnResult.action}, isComplete=${turnResult.isComplete}');
      if (turnResult.acknowledgement.isNotEmpty) {
        debugPrint('  Acknowledgement: "${turnResult.acknowledgement}"');
      }
      debugPrint('  Next Question: "${turnResult.nextQuestion}"');

      return turnResult;
    } catch (e, stackTrace) {
      debugPrint('[GeminiAIInterviewService] ERROR Submitting Answer: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<AIEvaluationResult> getFinalEvaluation({
    required String sessionId,
    required InterviewConfigEntity config,
  }) async {
    final endpoint = ApiConfig.interviewResultEndpoint(sessionId);

    debugPrint('======================================================');
    debugPrint('[GeminiAIInterviewService] Requesting Final Evaluation Scorecard');
    debugPrint('  Endpoint: $endpoint');
    debugPrint('======================================================');

    try {
      final response = await apiClient.get(
        endpoint,
        requiresAuth: true,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final eval = AIEvaluationResult.fromJson(inner, config: config);
      debugPrint('[GeminiAIInterviewService] Final Score: ${eval.overallScore}, band: ${eval.hiringBand}');
      return eval;
    } catch (e, stackTrace) {
      debugPrint('[GeminiAIInterviewService] ERROR getting final evaluation: $e\n$stackTrace');
      rethrow;
    }
  }
}
