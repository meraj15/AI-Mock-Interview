import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../interview/presentation/pages/quick_interview_setup_page.dart';
import '../../domain/entities/plan_entity.dart';
import '../controllers/subscription_controller.dart';

extension _PlanEntityX on PlanEntity {
  int get amountInRupees => (priceInPaise / 100).round();

  int get monthlyEquivalentRupees {
    if (isYearly) {
      return (amountInRupees / 12).round();
    }
    return amountInRupees;
  }
}

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubscriptionController>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final ctrl = context.watch<SubscriptionController>();

    final isBusy = ctrl.paymentState == PaymentState.creatingSubscription ||
        ctrl.paymentState == PaymentState.verifying;

    return PopScope(
      canPop: !isBusy,
      child: AppScaffold(
        scrollable: false,
        padding: EdgeInsets.zero,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with Close '✕' Icon
              _TopCloseBar(
                colors: colors,
                onClose: () => Navigator.of(context).pop(),
              ),

              // Main Body Content
              Expanded(
                child: _buildBody(context, colors, ctrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppColorScheme colors, SubscriptionController ctrl) {
    // ── Overlays: Success, Verifying, Network Error ──────────────────────────
    if (ctrl.paymentState == PaymentState.success) {
      return _SuccessOverlay(
        colors: colors,
        onDone: () => Navigator.of(context).pop(),
        onStartPractice: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QuickInterviewSetupPage(),
            ),
          );
        },
      );
    }

    if (ctrl.paymentState == PaymentState.verifying ||
        ctrl.paymentState == PaymentState.creatingSubscription) {
      return _ProcessingOverlay(
        colors: colors,
        message: ctrl.paymentState == PaymentState.creatingSubscription
            ? 'Opening secure checkout…'
            : 'Verifying payment…',
      );
    }

    if (ctrl.paymentState == PaymentState.networkError) {
      return _NetworkErrorOverlay(
        colors: colors,
        message: ctrl.errorMessage ??
            'Payment might be completed. Check subscription status.',
        onRefresh: () async {
          await ctrl.refreshSubscription();
          if (mounted) ctrl.resetPaymentState();
        },
      );
    }

    // ── Loading ────────────────────────────────────────────────────────────
    if (ctrl.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    // ── Load Error ─────────────────────────────────────────────────────────
    if (ctrl.loadStatus == SubscriptionLoadStatus.error) {
      return _ErrorState(
        colors: colors,
        message: ctrl.errorMessage ?? 'Unable to load plans.',
        onRetry: ctrl.loadAll,
      );
    }

    // ── Active Member View (If already subscribed) ─────────────────────────
    if (ctrl.isPremium) {
      return _ActiveSubscriberView(colors: colors, ctrl: ctrl);
    }

    // ── Non-Premium Subscription Page (Matches Reference Image) ────────────
    final monthlyPlan = ctrl.monthlyPlan;
    final yearlyPlan = ctrl.yearlyPlan;

    final selectedPlan = ctrl.selectedPlan ?? yearlyPlan ?? monthlyPlan;
    final isYearlySelected =
        selectedPlan?.isYearly ?? (ctrl.selectedPlanCode == yearlyPlan?.code);

    final monthlyPrice = monthlyPlan?.amountInRupees ?? 199;
    final yearlyTotal = yearlyPlan?.amountInRupees ?? 1999;
    final yearlyPerMonth = yearlyPlan?.monthlyEquivalentRupees ?? 166;

    final buttonLabel = isYearlySelected
        ? 'Start annual plan — ₹$yearlyTotal/yr'
        : 'Start monthly plan — ₹$monthlyPrice/mo';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Crown Icon Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: _CrownIcon(
              size: 28,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),

          // Main Headline
          Text(
            'Go Pro. Nail every interview.',
            style: AppTypography.bold(23, color: colors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Unlimited AI coaching, real-time feedback,\nand company-specific question banks.',
            style: AppTypography.regular(
              13.5,
              color: colors.mutedForeground,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),

          // 4 Feature Items
          const _FeatureItem(
            icon: FeatherIcons.zap,
            title: 'Unlimited mock interviews',
            subtitle: 'Coding, system design, behavioral — no daily cap',
          ),
          const SizedBox(height: 16),
          const _FeatureItem(
            icon: FeatherIcons.barChart2,
            title: 'Full evaluation rubric',
            subtitle:
                'Scored on clarity, depth, correctness, and communication',
          ),
          const SizedBox(height: 16),
          const _FeatureItem(
            icon: FeatherIcons.target,
            title: 'Target company calibration',
            subtitle: 'Questions modeled on Google, Amazon, Meta, and more',
          ),
          const SizedBox(height: 16),
          const _FeatureItem(
            icon: FeatherIcons.mic,
            title: 'Voice AI with follow-ups',
            subtitle: 'Realistic interviewer pressure and pushbacks',
          ),
          const SizedBox(height: 28),

          // Side-by-side Plan Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Card
              Expanded(
                child: _PlanOptionCard(
                  colors: colors,
                  title: 'Monthly',
                  mainPrice: '₹$monthlyPrice',
                  perPeriod: '/mo',
                  subtitle: 'Cancel anytime',
                  isSelected: !isYearlySelected,
                  onTap: () {
                    if (monthlyPlan != null) {
                      ctrl.selectPlan(monthlyPlan.code);
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Annual Card with Badge
              Expanded(
                child: _PlanOptionCard(
                  colors: colors,
                  title: 'Annual',
                  mainPrice: '₹$yearlyPerMonth',
                  perPeriod: '/mo',
                  subtitle: '₹$yearlyTotal billed yearly',
                  badgeText: 'Best value — save 16%',
                  isSelected: isYearlySelected,
                  onTap: () {
                    if (yearlyPlan != null) {
                      ctrl.selectPlan(yearlyPlan.code);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: ctrl.isSubscribing ? null : ctrl.subscribe,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ctrl.isSubscribing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.foreground,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FeatherIcons.zap,
                                size: 16,
                                color: colors.foreground,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                buttonLabel,
                                style: AppTypography.bold(14.5,
                                    color: colors.foreground),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Footer links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(
                text: 'Restore purchase',
                onTap: () async {
                  await ctrl.refreshSubscription();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ctrl.isPremium
                              ? 'Subscription restored!'
                              : 'Status checked. No active plan found.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                colors: colors,
              ),
              const SizedBox(width: 20),
              _FooterLink(
                text: 'Terms',
                onTap: () => _showTextModal(context, 'Terms of Service',
                    'By subscribing, you gain full access to all AI interview features. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the billing period.'),
                colors: colors,
              ),
              const SizedBox(width: 20),
              _FooterLink(
                text: 'Privacy',
                onTap: () => _showTextModal(context, 'Privacy Policy',
                    'Your interview responses and resumes are strictly private and used exclusively to generate your personalized practice questions and feedback.'),
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showTextModal(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTypography.bold(16)),
        content: Text(body,
            style: AppTypography.regular(13, color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Top Close Bar ──────────────────────────────────────────────────────────────

class _TopCloseBar extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onClose;

  const _TopCloseBar({required this.colors, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, right: 18, bottom: 4),
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.border.withValues(alpha: 0.8),
                width: 1.1,
              ),
              color: colors.card,
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: colors.foreground.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Crown Icon Painter ─────────────────────────────────────────────────────────

class _CrownIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _CrownIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.72),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.22)
      ..lineTo(size.width * 0.25, size.height * 0.62)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.75, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.22)
      ..lineTo(size.width * 0.86, size.height)
      ..lineTo(size.width * 0.14, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Feature Row ────────────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: colors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bold(14.5, color: colors.foreground),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.regular(
                  12.5,
                  color: colors.mutedForeground,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Plan Option Card (Side-by-side) ────────────────────────────────────────────

class _PlanOptionCard extends StatelessWidget {
  final AppColorScheme colors;
  final String title;
  final String mainPrice;
  final String perPeriod;
  final String subtitle;
  final String? badgeText;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOptionCard({
    required this.colors,
    required this.title,
    required this.mainPrice,
    required this.perPeriod,
    required this.subtitle,
    this.badgeText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.1)
                  : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.border.withValues(alpha: 0.8),
                width: isSelected ? 2.0 : 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.semiBold(
                    14,
                    color: isSelected ? colors.primary : colors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      mainPrice,
                      style: AppTypography.bold(
                        22,
                        color: isSelected ? colors.primary : colors.foreground,
                      ),
                    ),
                    Text(
                      perPeriod,
                      style: AppTypography.regular(
                        12.5,
                        color: isSelected
                            ? colors.primary
                            : colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.regular(
                    11.5,
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.85)
                        : colors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Hanging Badge on top
        if (badgeText != null)
          Positioned(
            top: -10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText!,
                style: AppTypography.bold(9.5, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Footer Link ────────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final AppColorScheme colors;

  const _FooterLink({
    required this.text,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTypography.medium(
          12,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

// ── Active Subscriber View ─────────────────────────────────────────────────────

class _ActiveSubscriberView extends StatelessWidget {
  final AppColorScheme colors;
  final SubscriptionController ctrl;

  const _ActiveSubscriberView({
    required this.colors,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final sub = ctrl.subscription;
    final renewDate = sub.periodEndFormatted ?? 'Ongoing';
    final isAutoRenew = sub.autoRenew && !sub.isCancelled;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(FeatherIcons.checkCircle,
                size: 36, color: colors.success),
          ),
          const SizedBox(height: 18),
          Text(
            'Pro Member Active',
            style: AppTypography.bold(22, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            isAutoRenew
                ? 'Your ${sub.isYearly ? 'Annual' : 'Monthly'} plan renews on $renewDate.'
                : 'Access active through $renewDate.',
            style: AppTypography.regular(13.5,
                color: colors.mutedForeground, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuickInterviewSetupPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text('Start Mock Interview',
                  style: AppTypography.bold(14.5, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          if (sub.autoRenew && !sub.isCancelled)
            TextButton(
              onPressed: ctrl.isCancelling
                  ? null
                  : () => _confirmCancel(context, ctrl),
              child: Text(
                'Cancel Subscription',
                style: AppTypography.medium(13, color: colors.destructive),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, SubscriptionController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel subscription?'),
        content: const Text(
          'Your Pro access will remain active until the end of your billing cycle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Pro'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ctrl.cancelSubscription(cancelAtCycleEnd: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Overlays: Success, Processing, Network Error, Error ────────────────────────

class _SuccessOverlay extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onDone;
  final VoidCallback onStartPractice;

  const _SuccessOverlay({
    required this.colors,
    required this.onDone,
    required this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(FeatherIcons.check, color: colors.success, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Pro! 🎉',
              style: AppTypography.bold(22, color: colors.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlimited mock interviews unlocked.',
              style: AppTypography.regular(13.5, color: colors.mutedForeground),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onStartPractice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Start First Interview',
                    style: AppTypography.bold(14, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDone,
              child: Text('Done', style: AppTypography.medium(13, color: colors.mutedForeground)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final AppColorScheme colors;
  final String message;

  const _ProcessingOverlay({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary, strokeWidth: 2.8),
          const SizedBox(height: 20),
          Text(message, style: AppTypography.semiBold(15, color: colors.foreground)),
          const SizedBox(height: 6),
          Text('Please do not close this screen',
              style: AppTypography.regular(12.5, color: colors.mutedForeground)),
        ],
      ),
    );
  }
}

class _NetworkErrorOverlay extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  final VoidCallback onRefresh;

  const _NetworkErrorOverlay({
    required this.colors,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.wifi, size: 40, color: colors.yellow),
            const SizedBox(height: 16),
            Text('Checking Status',
                style: AppTypography.semiBold(16, color: colors.foreground)),
            const SizedBox(height: 8),
            Text(message,
                style: AppTypography.regular(13, color: colors.mutedForeground),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRefresh,
              child: const Text('Check Status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.alertCircle, size: 36, color: colors.destructive),
            const SizedBox(height: 14),
            Text(message,
                style: AppTypography.regular(13, color: colors.mutedForeground),
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
