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

  // ── Getters ───────────────────────────────────────────────────────────────

  DashboardLoadState get loadState => _loadState;
  InterviewStatsModel get stats => _stats;
  List<InterviewSessionSummary> get recentSessions => _recentSessions;
  bool get isLoading => _loadState == DashboardLoadState.loading;
  bool get hasData => _loadState == DashboardLoadState.loaded;
  String? get errorMessage => _errorMessage;

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

  /// Called after the user completes an interview so the stats refresh.
  Future<void> refresh() => load();
}
