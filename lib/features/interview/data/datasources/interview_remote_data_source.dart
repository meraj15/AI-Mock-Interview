import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';

// ── DTOs ──────────────────────────────────────────────────────────────────────

class SaveInterviewRequest {
  final String role;
  final String type;
  final String difficulty;
  final int questionCount;
  final int score;
  final String hiringBand;
  final String summary;
  final List<String> strengths;
  final List<String> areasToImprove;
  final int durationSecs;

  const SaveInterviewRequest({
    required this.role,
    required this.type,
    required this.difficulty,
    required this.questionCount,
    required this.score,
    required this.hiringBand,
    required this.summary,
    required this.strengths,
    required this.areasToImprove,
    required this.durationSecs,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'type': type,
        'difficulty': difficulty,
        'questionCount': questionCount,
        'score': score,
        'hiringBand': hiringBand,
        'summary': summary,
        'strengths': strengths,
        'areasToImprove': areasToImprove,
        'durationSecs': durationSecs,
      };
}

/// Aggregated stats returned by GET /api/v1/interviews/stats
class InterviewStatsModel {
  /// SUM(scores) / COUNT — rounded integer
  final int averageScore;

  /// COUNT of all completed interviews
  final int totalInterviews;

  /// COUNT since Monday of the current week
  final int thisWeekCount;

  /// MAX score across all interviews
  final int bestScore;

  /// Consecutive days with ≥1 interview ending today
  final int currentStreak;

  /// currentMonthAvg - previousMonthAvg (can be negative)
  final int monthlyChange;

  const InterviewStatsModel({
    required this.averageScore,
    required this.totalInterviews,
    required this.thisWeekCount,
    required this.bestScore,
    required this.currentStreak,
    required this.monthlyChange,
  });

  factory InterviewStatsModel.fromJson(Map<String, dynamic> j) =>
      InterviewStatsModel(
        averageScore:    (j['averageScore']    as num?)?.toInt() ?? 0,
        totalInterviews: (j['totalInterviews'] as num?)?.toInt() ?? 0,
        thisWeekCount:   (j['thisWeekCount']   as num?)?.toInt() ?? 0,
        bestScore:       (j['bestScore']       as num?)?.toInt() ?? 0,
        currentStreak:   (j['currentStreak']   as num?)?.toInt() ?? 0,
        monthlyChange:   (j['monthlyChange']   as num?)?.toInt() ?? 0,
      );

  /// Zero-state — shown before any interview is completed
  static const empty = InterviewStatsModel(
    averageScore: 0,
    totalInterviews: 0,
    thisWeekCount: 0,
    bestScore: 0,
    currentStreak: 0,
    monthlyChange: 0,
  );
}

/// Lightweight summary of one session for the Recent Interviews list.
class InterviewSessionSummary {
  final String id;
  final String role;
  final String type;
  final int score;
  final DateTime createdAt;
  final int durationSecs;

  const InterviewSessionSummary({
    required this.id,
    required this.role,
    required this.type,
    required this.score,
    required this.createdAt,
    required this.durationSecs,
  });

  factory InterviewSessionSummary.fromJson(Map<String, dynamic> j) =>
      InterviewSessionSummary(
        id:          j['id'] as String,
        role:        j['role'] as String? ?? '',
        type:        j['type'] as String? ?? '',
        score:       (j['score'] as num?)?.toInt() ?? 0,
        createdAt:   DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        durationSecs: (j['durationSecs'] as num?)?.toInt() ?? 0,
      );
}

// ── Data source ───────────────────────────────────────────────────────────────

abstract class InterviewRemoteDataSource {
  Future<void> saveSession(SaveInterviewRequest request);
  Future<InterviewStatsModel> getStats();
  Future<List<InterviewSessionSummary>> listSessions({int limit, int offset});
}

class InterviewRemoteDataSourceImpl implements InterviewRemoteDataSource {
  final ApiClient apiClient;

  const InterviewRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> saveSession(SaveInterviewRequest request) async {
    await apiClient.post(
      ApiConfig.interviewsEndpoint,
      body: request.toJson(),
    );
  }

  @override
  Future<InterviewStatsModel> getStats() async {
    final response = await apiClient.get(ApiConfig.interviewStatsEndpoint);
    final data = response.data as Map<String, dynamic>? ?? {};
    return InterviewStatsModel.fromJson(data);
  }

  @override
  Future<List<InterviewSessionSummary>> listSessions({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await apiClient.get(
      ApiConfig.interviewsEndpoint,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final raw = response.data;
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InterviewSessionSummary.fromJson)
        .toList();
  }
}
