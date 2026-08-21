import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onTabSwitch;

  const HomePage({super.key, this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final auth = context.watch<AuthController>();
    final profileCtrl = context.watch<ProfileController>();

    // Prefer real profile name, fallback to email username, then generic 'User'
    final fullName = profileCtrl.fullName.isNotEmpty
        ? profileCtrl.fullName
        : auth.user?.email.split('@').first ?? 'User';
    final firstName = fullName.split(' ').first;
    final initials = profileCtrl.initials.isNotEmpty
        ? profileCtrl.initials
        : firstName.isNotEmpty
            ? firstName[0].toUpperCase()
            : 'U';

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, $firstName',
                    style: AppTypography.bold(24, color: colors.foreground),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Ready for your next interview?',
                    style: AppTypography.regular(13, color: colors.mutedForeground),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage(showHeader: true)),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: colors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTypography.bold(13, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Start Banner
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuickInterviewSetupPage()),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR NEXT REP',
                            style: AppTypography.bold(10, color: colors.mint, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start a new interview',
                            style: AppTypography.bold(25, color: Colors.white, height: 1.16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Practice with feedback that moves you forward.',
                            style: AppTypography.regular(12, color: const Color(0xFFBFCBE5), height: 1.4),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.mint,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start now',
                                  style: AppTypography.bold(11, color: colors.navy),
                                ),
                                const SizedBox(width: 6),
                                Icon(FeatherIcons.arrowUpRight, size: 16, color: colors.navy),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.mint.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(FeatherIcons.mic, size: 28, color: colors.mint),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Performance Section
          SectionTitle(
            title: 'Your performance',
            action: 'View analytics',
            onAction: () => onTabSwitch?.call(3),
          ),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Avg. score',
                  value: '78%',
                  change: '+8% this month',
                  icon: FeatherIcons.trendingUp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Interviews',
                  value: '12',
                  change: '+3 this week',
                  icon: FeatherIcons.layers,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Best score',
                  value: '91%',
                  icon: FeatherIcons.award,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Current streak',
                  value: '4 days',
                  icon: FeatherIcons.zap,
                ),
              ),
            ],
          ),

          // Recent Interviews Section
          SectionTitle(
            title: 'Recent interviews',
            action: 'See all',
            onAction: () => onTabSwitch?.call(2),
          ),

          Container(
            padding: const EdgeInsets.all(14),
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
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.code, size: 19, color: colors.accentForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flutter Developer',
                        style: AppTypography.semiBold(14, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Technical · 2 days ago · 18 min',
                        style: AppTypography.regular(10, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '82',
                      style: AppTypography.bold(20, color: colors.success),
                    ),
                    Text(
                      '/100',
                      style: AppTypography.medium(10, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recommended for you
          const SectionTitle(title: 'Recommended for you'),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: colors.coral,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.compass, size: 18, color: colors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strengthen system design',
                        style: AppTypography.bold(14, color: colors.foreground),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Your answers are strong. Go one level deeper on trade-offs.',
                        style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => onTabSwitch?.call(1),
                        child: Text(
                          'Explore practice →',
                          style: AppTypography.semiBold(11, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
