import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../interview/data/datasources/interview_remote_data_source.dart';

enum DashboardLoadState { idle, loading, loaded, error }

class DashboardController extends ChangeNotifier {
  final InterviewRemoteDataSource _dataSource;

  DashboardController({required InterviewRemoteDataSource dataSource})
      : _dataSource = dataSource;

  // ── State ─────────────────────────────────────────────────────────────────

  DashboardLoadState _loadState = DashboardLoadState.idle;
  InterviewStatsModel _stats = InterviewStatsModel.empty;
  List<InterviewSessionSummary> _recentSessions = [];
  String? _errorMessage;

  // ── Analytics Timeframe State ──────────────────────────────────────────────
  int _analyticsDays = 30;
  InterviewStatsModel _analyticsStats = InterviewStatsModel.empty;
  bool _isAnalyticsLoading = false;
  String? _analyticsError;
  final Map<int, InterviewStatsModel> _analyticsCache = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  DashboardLoadState get loadState => _loadState;
  InterviewStatsModel get stats => _stats;
  List<InterviewSessionSummary> get recentSessions => _recentSessions;
  bool get isLoading => _loadState == DashboardLoadState.loading;
  bool get hasData => _loadState == DashboardLoadState.loaded;
  String? get errorMessage => _errorMessage;

  int get analyticsDays => _analyticsDays;
  InterviewStatsModel get analyticsStats =>
      _analyticsStats == InterviewStatsModel.empty ? _stats : _analyticsStats;
  bool get isAnalyticsLoading => _isAnalyticsLoading;
  String? get analyticsError => _analyticsError;

  // ── Formatted values for the StatCards ───────────────────────────────────

  /// "78%" or "—" before first interview
  String get avgScoreLabel {
    if (_stats.totalInterviews == 0) return '—';
    return '${_stats.averageScore}%';
  }

  /// "+8% this month" / "-3% this month" / "—"
  String? get avgScoreChange {
    if (_stats.totalInterviews == 0) return null;
    final ch = _stats.monthlyChange;
    if (ch == 0) return 'Same as last month';
    final sign = ch > 0 ? '+' : '';
    return '$sign$ch% this month';
  }

  /// "12" or "0"
  String get totalInterviewsLabel => '${_stats.totalInterviews}';

  /// "+3 this week" or null
  String? get thisWeekChange {
    if (_stats.thisWeekCount == 0) return null;
    return '+${_stats.thisWeekCount} this week';
  }

  /// "91%" or "—"
  String get bestScoreLabel {
    if (_stats.totalInterviews == 0) return '—';
    return '${_stats.bestScore}%';
  }

  /// "4 days" / "1 day" / "—"
  String get streakLabel {
    final s = _stats.currentStreak;
    if (s == 0) return '—';
    return '$s ${s == 1 ? 'day' : 'days'}';
  }

  InterviewSessionSummary? get latestSession =>
      _recentSessions.isNotEmpty ? _recentSessions.first : null;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Load stats + sessions from backend. Safe to call multiple times.
  Future<void> load() async {
    if (_loadState == DashboardLoadState.loading) return;
    _loadState = DashboardLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dataSource.getStats(),
        _dataSource.listSessions(limit: 50),
      ]);

      _stats          = results[0] as InterviewStatsModel;
      _recentSessions = results[1] as List<InterviewSessionSummary>;
      if (_analyticsDays == 30 && _analyticsStats == InterviewStatsModel.empty) {
        _analyticsStats = _stats;
        _analyticsCache[30] = _stats;
      }
      _loadState      = DashboardLoadState.loaded;
    } on NetworkException catch (e) {
      _errorMessage = e.message;
      _loadState    = DashboardLoadState.error;
    } on AuthException {
      // Silently swallow — auth layer will handle redirect
      _loadState = DashboardLoadState.error;
    } catch (e) {
      _errorMessage = 'Could not load dashboard data.';
      _loadState    = DashboardLoadState.error;
    }

    notifyListeners();
  }

  /// Sets the analytics timeframe (7, 15, or 30 days) and loads stats.
  Future<void> setAnalyticsDays(int days) async {
    if (_analyticsDays == days && _analyticsStats != InterviewStatsModel.empty) {
      return;
    }
    _analyticsDays = days;
    if (_analyticsCache.containsKey(days)) {
      _analyticsStats = _analyticsCache[days]!;
      _analyticsError = null;
      notifyListeners();
      return;
    }
    await loadAnalytics();
  }

  /// Load analytics stats for the currently selected timeframe.
  Future<void> loadAnalytics({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _analyticsCache.remove(_analyticsDays);
    }
    _isAnalyticsLoading = true;
    _analyticsError = null;
    notifyListeners();

    try {
      final res = await _dataSource.getStats(days: _analyticsDays);
      _analyticsStats = res;
      _analyticsCache[_analyticsDays] = res;
    } on NetworkException catch (e) {
      _analyticsError = e.message;
    } catch (_) {
      _analyticsError = 'Could not load analytics data.';
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  /// Called after the user completes an interview so the stats refresh.
  Future<void> refresh() {
    _analyticsCache.clear();
    return Future.wait([
      load(),
      loadAnalytics(forceRefresh: true),
    ]);
  }
}
