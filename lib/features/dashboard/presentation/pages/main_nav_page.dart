import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../interviews_history/presentation/pages/interviews_page.dart';
import '../../../practice/presentation/pages/practice_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

class MainNavPage extends StatefulWidget {
  final int initialTab;
  const MainNavPage({super.key, this.initialTab = 0});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabSelect(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    final pages = [
      HomePage(onTabSwitch: _onTabSelect),
      const PracticePage(),
      const InterviewsPage(),
      const AnalyticsPage(),
      const ProfilePage(),
    ];

    final tabs = [
      {'icon': FeatherIcons.home, 'label': 'Home'},
      {'icon': FeatherIcons.target, 'label': 'Practice'},
      {'icon': FeatherIcons.layers, 'label': 'Interviews'},
      {'icon': FeatherIcons.trendingUp, 'label': 'Analytics'},
      {'icon': FeatherIcons.user, 'label': 'Profile'},
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _currentIndex == index;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onTabSelect(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: isSelected ? colors.primary : colors.mutedForeground,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: AppTypography.semiBold(
                          10,
                          color: isSelected ? colors.primary : colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

          }).toList(),
        ),
      ),
    );
  }
}
