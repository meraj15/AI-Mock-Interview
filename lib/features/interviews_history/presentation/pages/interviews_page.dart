import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';
import '../../../interview/presentation/pages/interview_result_page.dart';

class InterviewsPage extends StatefulWidget {
  const InterviewsPage({super.key});

  @override
  State<InterviewsPage> createState() => _InterviewsPageState();
}

class _InterviewsPageState extends State<InterviewsPage> {
  String _sortBy = 'Newest';

  final List<Map<String, dynamic>> _interviews = [
    {
      'role': 'Flutter Developer',
      'date': 'Aug 11, 2026',
      'score': 82,
      'tone': PillTone.success,
      'status': 'Strong performance',
      'duration': '18 min',
    },
    {
      'role': 'Flutter Developer',
      'date': 'Aug 07, 2026',
      'score': 76,
      'tone': PillTone.violet,
      'status': 'Good progress',
      'duration': '22 min',
    },
    {
      'role': 'Flutter Developer',
      'date': 'Aug 02, 2026',
      'score': 88,
      'tone': PillTone.success,
      'status': 'Strong performance',
      'duration': '15 min',
    },
    {
      'role': 'Flutter Developer',
      'date': 'Jul 28, 2026',
      'score': 69,
      'tone': PillTone.muted,
      'status': 'Keep practicing',
      'duration': '20 min',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    var sorted = List<Map<String, dynamic>>.from(_interviews);
    if (_sortBy == 'Highest Score') {
      sorted.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    } else if (_sortBy == 'Lowest Score') {
      sorted.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'My Interviews',
            subtitle: 'Your full interview history',
            alignLeft: true,
            right: PopupMenuButton<String>(
              icon: Icon(FeatherIcons.sliders, size: 19, color: colors.foreground),
              onSelected: (val) => setState(() => _sortBy = val),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'Newest', child: Text('Sort by: Newest')),
                const PopupMenuItem(
                    value: 'Highest Score', child: Text('Sort by: Highest Score')),
                const PopupMenuItem(
                    value: 'Lowest Score', child: Text('Sort by: Lowest Score')),
              ],
            ),
          ),

          SectionTitle(
            title: '${sorted.length} sessions',
            action: 'Sorted by: $_sortBy',
          ),

          if (sorted.isEmpty) ...[
            EmptyStateWidget(
              icon: FeatherIcons.layers,
              title: 'No interviews yet',
              description:
                  'Start your first mock interview session to see your history here.',
              actionLabel: 'Start Interview',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const QuickInterviewSetupPage()),
                );
              },
            ),
          ] else ...[
            ...sorted.map((item) {
              final score = item['score'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const InterviewResultPage()),
                      );
                    },
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
                                  item['role'] as String,
                                  style: AppTypography.semiBold(
                                      14, color: colors.foreground),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item['date']} · ${item['duration']}',
                                  style: AppTypography.regular(
                                      10, color: colors.mutedForeground),
                                ),
                                const SizedBox(height: 8),
                                PillBadge(
                                  label: item['status'] as String,
                                  tone: item['tone'] as PillTone,
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
                                        20, color: colors.foreground),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
