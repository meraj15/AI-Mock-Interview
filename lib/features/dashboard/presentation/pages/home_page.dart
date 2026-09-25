import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../interview/data/datasources/interview_remote_data_source.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../controllers/dashboard_controller.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onTabSwitch;

  const HomePage({super.key, this.onTabSwitch});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load stats and sync profile data when the home tab is first shown.
    // Use addPostFrameCallback so the context is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final profileCtrl = context.read<ProfileController>();
      if (auth.user != null) {
        profileCtrl.applyAuthUserData(
          name: auth.user!.name,
          email: auth.user!.email,
        );
      }
      profileCtrl.loadProfile();
      context.read<DashboardController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors       = AppColorScheme.of(context);
    final auth         = context.watch<AuthController>();
    final profileCtrl  = context.watch<ProfileController>();
    final dashboard    = context.watch<DashboardController>();

    // ── Name / initials ──────────────────────────────────────────────────────
    final fullName  = profileCtrl.fullName.isNotEmpty
        ? profileCtrl.fullName
        : (auth.user?.name.isNotEmpty == true
            ? auth.user!.name
            : (auth.user?.email.split('@').first ?? 'User'));
    final firstName = fullName.split(' ').first;
    final initials  = profileCtrl.initials.isNotEmpty
        ? profileCtrl.initials.toUpperCase()
        : firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    if (dashboard.isLoading) {
      return AppScaffold(
        body: _HomeShimmerLoadingView(colors: colors),
      );
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Header ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $firstName',
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfilePage(showHeader: true)),
                  ),
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

          // ── Quick Start Banner ───────────────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const QuickInterviewSetupPage()),
              ),
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
                            style: AppTypography.bold(10, color: colors.mint,
                                letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start a new interview',
                            style: AppTypography.bold(25, color: Colors.white,
                                height: 1.16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Practice with feedback that moves you forward.',
                            style: AppTypography.regular(12,
                                color: const Color(0xFFBFCBE5), height: 1.4),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.mint,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start now',
                                  style: AppTypography.bold(11,
                                      color: colors.navy),
                                ),
                                const SizedBox(width: 6),
                                Icon(FeatherIcons.arrowUpRight,
                                    size: 16, color: colors.navy),
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
                      child: Icon(FeatherIcons.mic,
                          size: 28, color: colors.mint),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Performance Section ──────────────────────────────────────────
          SectionTitle(
            title: 'Your performance',
            action: 'View analytics',
            onAction: () => widget.onTabSwitch?.call(2),
          ),

          // Loading shimmer / error / data
          if (dashboard.isLoading)
            _StatsLoadingShimmer(colors: colors)
          else if (dashboard.loadState == DashboardLoadState.error)
            _StatsErrorRow(
              colors: colors,
              onRetry: () => context.read<DashboardController>().load(),
            )
          else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Avg. score',
                      value: dashboard.avgScoreLabel,
                      change: dashboard.avgScoreChange,
                      icon: FeatherIcons.trendingUp,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Interviews',
                      value: dashboard.totalInterviewsLabel,
                      change: dashboard.thisWeekChange,
                      icon: FeatherIcons.layers,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Best score',
                      value: dashboard.bestScoreLabel,
                      icon: FeatherIcons.award,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Current streak',
                      value: dashboard.streakLabel,
                      icon: FeatherIcons.zap,
                    ),
                  ),
                ],
              ),
            ),
        
          ],

          // ── Recent Interview (Only 1 most recent) ───────────────────────
          SectionTitle(
            title: 'Recent interview',
            action: 'See all',
            onAction: () => widget.onTabSwitch?.call(1),
          ),

          if (dashboard.isLoading)
            _RecentLoadingShimmer(colors: colors)
          else if (dashboard.recentSessions.isEmpty)
            _EmptyRecentInterviews(colors: colors)
          else
            _RecentSessionCard(
              session: dashboard.recentSessions.first,
              colors: colors,
              onTap: () => widget.onTabSwitch?.call(1),
            ),

          // ── Recommended ──────────────────────────────────────────────────
          // const SectionTitle(title: 'Recommended for you'),

          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: colors.secondary,
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Container(
          //         width: 39,
          //         height: 39,
          //         decoration: BoxDecoration(
          //           color: colors.coral,
          //           borderRadius: BorderRadius.circular(13),
          //         ),
          //         alignment: Alignment.center,
          //         child: Icon(FeatherIcons.compass,
          //             size: 18, color: colors.ink),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Strengthen system design',
          //               style: AppTypography.bold(14,
          //                   color: colors.foreground),
          //             ),
          //             const SizedBox(height: 5),
          //             Text(
          //               'Your answers are strong. Go one level deeper on trade-offs.',
          //               style: AppTypography.regular(11,
          //                   color: colors.mutedForeground, height: 1.45),
          //             ),
          //             const SizedBox(height: 8),
          //             GestureDetector(
          //               onTap: () => widget.onTabSwitch?.call(1),
          //               child: Text(
          //                 'Explore practice →',
          //                 style: AppTypography.semiBold(11,
          //                     color: colors.primary),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

// ── Recent session card ───────────────────────────────────────────────────────

class _RecentSessionCard extends StatelessWidget {
  final InterviewSessionSummary session;
  final AppColorScheme colors;
  final VoidCallback? onTap;

  const _RecentSessionCard({
    required this.session,
    required this.colors,
    this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Yesterday';
    if (diff.inDays < 7)     return '${diff.inDays} days ago';
    return '${diff.inDays ~/ 7} weeks ago';
  }

  String _duration(int secs) {
    if (secs == 0) return '';
    final m = secs ~/ 60;
    return ' · ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = session.score >= 80
        ? colors.success
        : session.score >= 60
            ? colors.primary
            : colors.coral;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.code,
                      size: 19, color: colors.accentForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.role,
                        style:
                            AppTypography.semiBold(14, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_timeAgo(session.createdAt)}'
                        '${_duration(session.durationSecs)}',
                        style: AppTypography.regular(
                            10, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${session.score}',
                      style: AppTypography.bold(20, color: scoreColor),
                    ),
                    Text(
                      '/100',
                      style:
                          AppTypography.medium(10, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyRecentInterviews extends StatelessWidget {
  final AppColorScheme colors;
  const _EmptyRecentInterviews({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(FeatherIcons.mic, size: 28, color: colors.mutedForeground),
          const SizedBox(height: 10),
          Text(
            'No interviews yet',
            style: AppTypography.semiBold(14, color: colors.foreground),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete your first session to see results here.',
            style: AppTypography.regular(12,
                color: colors.mutedForeground, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Full-screen loading shimmer for Home Page (zero text) ─────────────────────

class _HomeShimmerLoadingView extends StatelessWidget {
  final AppColorScheme colors;
  const _HomeShimmerLoadingView({required this.colors});

  Widget _buildStatCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          ShimmerBox(
            width: 32,
            height: 32,
            borderRadius: 10,
          ),
          SizedBox(height: 12),
          ShimmerBox(
            width: 54,
            height: 22,
            borderRadius: 6,
          ),
          SizedBox(height: 6),
          ShimmerBox(
            width: 76,
            height: 12,
            borderRadius: 4,
          ),
          SizedBox(height: 6),
          ShimmerBox(
            width: 46,
            height: 10,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Header: Greeting line 1, Greeting line 2, and Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 170, height: 24, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 220, height: 13, borderRadius: 5),
                ],
              ),
              const ShimmerBox(width: 45, height: 45, borderRadius: 16),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Start Banner Skeleton (same size & shape, no text)
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 90, height: 10, borderRadius: 4),
                      SizedBox(height: 12),
                      ShimmerBox(width: 180, height: 24, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: 220, height: 12, borderRadius: 4),
                      SizedBox(height: 15),
                      ShimmerBox(width: 95, height: 30, borderRadius: 13),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const ShimmerBox(width: 80, height: 80, borderRadius: 40),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Section Title 1 Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 130, height: 16, borderRadius: 5),
              ShimmerBox(width: 80, height: 13, borderRadius: 4),
            ],
          ),

          const SizedBox(height: 12),

          // Stat Cards Grid Skeleton (2x2)
          Row(
            children: [
              Expanded(child: _buildStatCardSkeleton()),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCardSkeleton()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCardSkeleton()),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCardSkeleton()),
            ],
          ),

          const SizedBox(height: 22),

          // Section Title 2 Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 120, height: 16, borderRadius: 5),
              ShimmerBox(width: 50, height: 13, borderRadius: 4),
            ],
          ),

          const SizedBox(height: 12),

          // Recent Session Card Skeleton
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const ShimmerBox(width: 44, height: 44, borderRadius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      ShimmerBox(width: 140, height: 14, borderRadius: 5),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 10, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 70, height: 18, borderRadius: 6),
                    ],
                  ),
                ),
                const ShimmerBox(width: 40, height: 22, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Loading shimmer for stats row ─────────────────────────────────────────────

class _StatsLoadingShimmer extends StatelessWidget {
  final AppColorScheme colors;
  const _StatsLoadingShimmer({required this.colors});

  Widget _buildStatCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ShimmerBox(
              width: 32,
              height: 32,
              borderRadius: 10,
            ),
            const SizedBox(height: 12),
            const ShimmerBox(
              width: 54,
              height: 22,
              borderRadius: 6,
            ),
            const SizedBox(height: 6),
            const ShimmerBox(
              width: 76,
              height: 12,
              borderRadius: 4,
            ),
            const SizedBox(height: 6),
            const ShimmerBox(
              width: 46,
              height: 10,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCardSkeleton()),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCardSkeleton()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCardSkeleton()),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCardSkeleton()),
          ],
        ),
      ],
    );
  }
}

// ── Loading shimmer for recent interviews ─────────────────────────────────────

class _RecentLoadingShimmer extends StatelessWidget {
  final AppColorScheme colors;
  const _RecentLoadingShimmer({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: const AppShimmer(
        child: Row(
          children: [
            ShimmerBox(
              width: 42,
              height: 42,
              borderRadius: 14,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(
                    width: 130,
                    height: 14,
                    borderRadius: 5,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(
                    width: 80,
                    height: 10,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            ShimmerBox(
              width: 44,
              height: 22,
              borderRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error row with retry ──────────────────────────────────────────────────────

class _StatsErrorRow extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onRetry;

  const _StatsErrorRow({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.wifiOff, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load stats. Check your connection.',
              style: AppTypography.regular(12, color: colors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: AppTypography.semiBold(12, color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
