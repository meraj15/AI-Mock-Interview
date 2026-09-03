import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../interview/data/datasources/interview_remote_data_source.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';

class InterviewsPage extends StatefulWidget {
  const InterviewsPage({super.key});

  @override
  State<InterviewsPage> createState() => _InterviewsPageState();
}

class _InterviewsPageState extends State<InterviewsPage> {
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    // Refresh sessions when entering the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().load();
    });
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }

  String _formatDuration(int secs) {
    if (secs == 0) return '0 min';
    final m = (secs / 60).round();
    return '$m min';
  }

  PillTone _getBandTone(String band, int score) {
    final b = band.toLowerCase();
    if (b.contains('strong') || score >= 80) return PillTone.success;
    if (b.contains('hire') || score >= 65) return PillTone.violet;
    return PillTone.muted;
  }

  void _showSessionDetails(BuildContext context, InterviewSessionSummary session, AppColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            final scoreColor = session.score >= 80
                ? colors.success
                : session.score >= 60
                    ? colors.primary
                    : colors.coral;

            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.role,
                              style: AppTypography.bold(18, color: colors.foreground),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(session.createdAt)} · ${_formatDuration(session.durationSecs)} · ${session.difficulty}',
                              style: AppTypography.regular(12, color: colors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${session.score}%',
                          style: AppTypography.bold(18, color: scoreColor),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: colors.border.withValues(alpha: 0.5)),
                  const SizedBox(height: 14),

                  // Performance Band
                  Row(
                    children: [
                      Text(
                        'Evaluation: ',
                        style: AppTypography.semiBold(13, color: colors.foreground),
                      ),
                      PillBadge(
                        label: session.hiringBand,
                        tone: _getBandTone(session.hiringBand, session.score),
                      ),
                    ],
                  ),

                  if (session.summary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'AI Summary',
                      style: AppTypography.bold(14, color: colors.foreground),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        session.summary,
                        style: AppTypography.regular(12.5, color: colors.foreground, height: 1.45),
                      ),
                    ),
                  ],

                  if (session.strengths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Strengths',
                      style: AppTypography.bold(14, color: colors.success),
                    ),
                    const SizedBox(height: 6),
                    ...session.strengths.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(FeatherIcons.checkCircle, size: 14, color: colors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: AppTypography.regular(12, color: colors.foreground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (session.areasToImprove.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Areas for Growth',
                      style: AppTypography.bold(14, color: colors.coral),
                    ),
                    const SizedBox(height: 6),
                    ...session.areasToImprove.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(FeatherIcons.arrowUpRight, size: 14, color: colors.coral),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a,
                                style: AppTypography.regular(12, color: colors.foreground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final dashboard = context.watch<DashboardController>();

    final sessions = List<InterviewSessionSummary>.from(dashboard.recentSessions);

    if (_sortBy == 'Highest Score') {
      sessions.sort((a, b) => b.score.compareTo(a.score));
    } else if (_sortBy == 'Lowest Score') {
      sessions.sort((a, b) => a.score.compareTo(b.score));
    } else {
      // Newest
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return AppScaffold(
      scrollable: false,
      body: RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.card,
        onRefresh: () => dashboard.load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'My Interviews',
                subtitle: 'Your full interview practice history',
                alignLeft: true,
                right: PopupMenuButton<String>(
                  icon: Icon(FeatherIcons.sliders, size: 19, color: colors.foreground),
                  color: colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
                  ),
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'Newest',
                      child: Text('Sort by: Newest', style: AppTypography.medium(12, color: colors.foreground)),
                    ),
                    PopupMenuItem(
                      value: 'Highest Score',
                      child: Text('Sort by: Highest Score', style: AppTypography.medium(12, color: colors.foreground)),
                    ),
                    PopupMenuItem(
                      value: 'Lowest Score',
                      child: Text('Sort by: Lowest Score', style: AppTypography.medium(12, color: colors.foreground)),
                    ),
                  ],
                ),
              ),

              SectionTitle(
                title: '${sessions.length} sessions',
                action: 'Sorted: $_sortBy',
              ),

              if (dashboard.isLoading && sessions.isEmpty) ...[
                _buildLoadingShimmer(colors),
              ] else if (sessions.isEmpty) ...[
                EmptyStateWidget(
                  icon: FeatherIcons.layers,
                  title: 'No interviews yet',
                  description: 'Start your first AI mock interview session to see your full history and feedback here.',
                  actionLabel: 'Start Interview',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuickInterviewSetupPage(),
                      ),
                    );
                  },
                ),
              ] else ...[
                ...sessions.map((session) {
                  final score = session.score;
                  final scoreColor = score >= 80
                      ? colors.success
                      : score >= 60
                          ? colors.primary
                          : colors.coral;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showSessionDetails(context, session, colors),
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(FeatherIcons.code,
                                    size: 19, color: colors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.role,
                                      style: AppTypography.semiBold(
                                          14, color: colors.foreground),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_formatDate(session.createdAt)} · ${_formatDuration(session.durationSecs)}',
                                      style: AppTypography.regular(
                                          10.5, color: colors.mutedForeground),
                                    ),
                                    const SizedBox(height: 8),
                                    PillBadge(
                                      label: session.hiringBand,
                                      tone: _getBandTone(session.hiringBand, score),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$score',
                                        style: AppTypography.bold(
                                            20, color: scoreColor),
                                      ),
                                      Text(
                                        '/100',
                                        style: AppTypography.regular(
                                            9, color: colors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(FeatherIcons.chevronRight,
                                      size: 16, color: colors.mutedForeground),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(AppColorScheme colors) {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      color: colors.border.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
