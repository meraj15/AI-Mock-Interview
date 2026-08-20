import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/pages/interview_result_page.dart';
import '../../../interview/presentation/pages/interview_setup_page.dart';

class InterviewsPage extends StatefulWidget {
  const InterviewsPage({super.key});

  @override
  State<InterviewsPage> createState() => _InterviewsPageState();
}

class _InterviewsPageState extends State<InterviewsPage> {
  String _selectedFilter = 'All';
  String _sortBy = 'Newest';

  final List<Map<String, dynamic>> _interviews = [
    {
      'role': 'Flutter Developer',
      'type': 'Technical interview',
      'date': 'Aug 11, 2026',
      'score': 82,
      'tone': PillTone.success,
      'status': 'Strong performance',
      'icon': FeatherIcons.code,
      'duration': '18 min',
    },
    {
      'role': 'Product Designer',
      'type': 'Portfolio review',
      'date': 'Aug 07, 2026',
      'score': 76,
      'tone': PillTone.violet,
      'status': 'Good progress',
      'icon': FeatherIcons.penTool,
      'duration': '22 min',
    },
    {
      'role': 'Frontend Engineer',
      'type': 'Behavioral interview',
      'date': 'Aug 02, 2026',
      'score': 88,
      'tone': PillTone.coral,
      'status': 'Strong performance',
      'icon': FeatherIcons.layout,
      'duration': '15 min',
    },
    {
      'role': 'Flutter Developer',
      'type': 'System design',
      'date': 'Jul 28, 2026',
      'score': 69,
      'tone': PillTone.muted,
      'status': 'Keep practicing',
      'icon': FeatherIcons.layers,
      'duration': '20 min',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    var filtered = _selectedFilter == 'All'
        ? List<Map<String, dynamic>>.from(_interviews)
        : _interviews.where((item) => (item['type'] as String).toLowerCase().contains(_selectedFilter.toLowerCase())).toList();

    if (_sortBy == 'Highest Score') {
      filtered.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    } else if (_sortBy == 'Lowest Score') {
      filtered.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'My Interviews',
            subtitle: 'Track your practice history over time',
            right: PopupMenuButton<String>(
              icon: Icon(FeatherIcons.sliders, size: 19, color: colors.foreground),
              onSelected: (val) => setState(() => _sortBy = val),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'Newest', child: Text('Sort by: Newest')),
                const PopupMenuItem(value: 'Highest Score', child: Text('Sort by: Highest Score')),
                const PopupMenuItem(value: 'Lowest Score', child: Text('Sort by: Lowest Score')),
              ],
            ),
          ),

          SectionTitle(
            title: '${filtered.length} completed',
            action: 'Sorted: $_sortBy',
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Technical', 'Behavioral', 'System', 'Portfolio'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          filter,
                          style: AppTypography.semiBold(
                            11,
                            color: isSelected ? colors.primaryForeground : colors.secondaryForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (filtered.isEmpty) ...[
            EmptyStateWidget(
              icon: FeatherIcons.layers,
              title: 'No interviews in this category',
              description: 'Try choosing another filter or start a fresh mock interview session.',
              actionLabel: 'Start New Interview',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InterviewSetupPage()),
                );
              },
            ),
          ] else ...[
            // Cards
            ...filtered.map((item) {
              final score = item['score'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InterviewResultPage()),
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
                            child: Icon(item['icon'] as IconData, size: 19, color: colors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['role'] as String,
                                  style: AppTypography.semiBold(14, color: colors.foreground),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item['type']} · ${item['date']} · ${item['duration']}',
                                  style: AppTypography.regular(10, color: colors.mutedForeground),
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
                                    style: AppTypography.bold(20, color: colors.foreground),
                                  ),
                                  Text(
                                    '/100',
                                    style: AppTypography.regular(9, color: colors.mutedForeground),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Icon(FeatherIcons.chevronRight, size: 16, color: colors.mutedForeground),
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
          const SizedBox(height: 16),
          // Practice Again CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InterviewSetupPage()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.mint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(FeatherIcons.refreshCw,
                          size: 20, color: colors.mint),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Again',
                            style: AppTypography.bold(15,
                                color: Colors.white),
                          ),
                          Text(
                            'Start a new mock interview session',
                            style: AppTypography.regular(11,
                                color: const Color(0xFFBFCBE5)),
                          ),
                        ],
                      ),
                    ),
                    Icon(FeatherIcons.arrowRight,
                        size: 18, color: colors.mint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
