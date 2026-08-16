import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../interview/presentation/pages/interview_result_page.dart';

class InterviewsPage extends StatefulWidget {
  const InterviewsPage({super.key});

  @override
  State<InterviewsPage> createState() => _InterviewsPageState();
}

class _InterviewsPageState extends State<InterviewsPage> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _interviews = [
    {
      'role': 'Flutter Developer',
      'type': 'Technical interview',
      'date': 'Aug 11, 2026',
      'score': '82',
      'tone': PillTone.success,
      'status': 'Strong performance',
      'icon': FeatherIcons.code,
    },
    {
      'role': 'Product Designer',
      'type': 'Portfolio review',
      'date': 'Aug 07, 2026',
      'score': '76',
      'tone': PillTone.violet,
      'status': 'Good progress',
      'icon': FeatherIcons.penTool,
    },
    {
      'role': 'Frontend Engineer',
      'type': 'Behavioral interview',
      'date': 'Aug 02, 2026',
      'score': '88',
      'tone': PillTone.coral,
      'status': 'Strong performance',
      'icon': FeatherIcons.layout,
    },
    {
      'role': 'Flutter Developer',
      'type': 'System design',
      'date': 'Jul 28, 2026',
      'score': '69',
      'tone': PillTone.muted,
      'status': 'Keep practicing',
      'icon': FeatherIcons.layers,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    final filtered = _selectedFilter == 'All'
        ? _interviews
        : _interviews.where((item) => (item['type'] as String).toLowerCase().contains(_selectedFilter.toLowerCase())).toList();

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'My interviews',
            subtitle: 'Your practice, over time',
            right: IconButton(
              icon: Icon(FeatherIcons.search, size: 20, color: colors.foreground),
              onPressed: () {},
            ),
          ),

          const SectionTitle(title: '12 completed', action: 'Newest'),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Technical', 'Behavioral', 'System'].map((filter) {
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

          // Cards
          ...filtered.map((item) {
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
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(item['icon'] as IconData, size: 18, color: colors.primary),
                        ),
                        const SizedBox(width: 11),
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
                                '${item['type']} · ${item['date']}',
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
                                  item['score'] as String,
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
