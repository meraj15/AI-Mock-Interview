import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/subscription_controller.dart';
import '../../domain/entities/plan_entity.dart';

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

    return PopScope(
      canPop: ctrl.paymentState != PaymentState.creatingSubscription &&
          ctrl.paymentState != PaymentState.verifying,
      child: AppScaffold(
        body: Column(
          children: [
            AppHeader(
              title: 'Premium',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _buildBody(context, colors, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppColorScheme colors, SubscriptionController ctrl) {
    // ── Overlay states ───────────────────────────────────────────────────────
    if (ctrl.paymentState == PaymentState.success) {
      return _SuccessOverlay(
          colors: colors, onDone: () => Navigator.of(context).pop());
    }

    if (ctrl.paymentState == PaymentState.verifying ||
        ctrl.paymentState == PaymentState.creatingSubscription) {
      return _ProcessingOverlay(
        colors: colors,
        message: ctrl.paymentState == PaymentState.creatingSubscription
            ? 'Opening secure checkout…'
            : 'Verifying your payment…',
      );
    }

    if (ctrl.paymentState == PaymentState.networkError) {
      return _NetworkErrorOverlay(
        colors: colors,
        message: ctrl.errorMessage ??
            'Your payment may have been completed. We\'re checking your subscription status.',
        onRefresh: () async {
          await ctrl.refreshSubscription();
          if (mounted) ctrl.resetPaymentState();
        },
      );
    }

    // ── Loading ──────────────────────────────────────────────────────────────
    if (ctrl.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    // ── Load error ───────────────────────────────────────────────────────────
    if (ctrl.loadStatus == SubscriptionLoadStatus.error) {
      return _ErrorState(
          colors: colors,
          message: ctrl.errorMessage ?? 'Unable to load subscription details.',
          onRetry: ctrl.loadAll);
    }

    // ── Main content ─────────────────────────────────────────────────────────
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: ctrl.refreshSubscription,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (ctrl.isPremium) ...[
            _ActiveBanner(colors: colors, subscription: ctrl.subscription),
            const SizedBox(height: 24),
          ] else ...[
            _HeroBanner(colors: colors),
            const SizedBox(height: 28),
          ],

          // Plan selector (non-premium users only)
          if (!ctrl.isPremium && ctrl.plans.isNotEmpty) ...[
            Text('Choose your plan',
                style: AppTypography.semiBold(15, color: colors.foreground)),
            const SizedBox(height: 12),
            _PlanSelector(colors: colors, ctrl: ctrl),
            const SizedBox(height: 24),
          ],

          // Benefits list
          _BenefitsList(colors: colors),
          const SizedBox(height: 28),

          // Error banners
          if (ctrl.paymentState == PaymentState.failed &&
              ctrl.errorMessage != null) ...[
            _ErrorBanner(colors: colors, message: ctrl.errorMessage!),
            const SizedBox(height: 16),
          ],
          if (ctrl.paymentState == PaymentState.cancelled) ...[
            _InfoBanner(
                colors: colors,
                message: 'Payment was cancelled. You can try again anytime.'),
            const SizedBox(height: 16),
          ],

          // CTA
          if (!ctrl.isPremium)
            _SubscribeButton(colors: colors, ctrl: ctrl)
          else
            _ManageSection(colors: colors, ctrl: ctrl),
        ],
      ),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final AppColorScheme colors;
  const _HeroBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.85),
            colors.violet.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✦ PREMIUM',
              style:
                  AppTypography.bold(11, color: Colors.white, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ace every interview\nwith AI coaching',
            style: AppTypography.bold(22, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlimited mock interviews, deep feedback,\nand performance analytics.',
            style: AppTypography.regular(13,
                color: Colors.white.withOpacity(0.85), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Active Premium Banner ──────────────────────────────────────────────────────

class _ActiveBanner extends StatelessWidget {
  final AppColorScheme colors;
  final dynamic subscription;
  const _ActiveBanner({required this.colors, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: colors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(FeatherIcons.star, color: colors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Active',
                    style: AppTypography.bold(14,
                        color: colors.accentForeground)),
                if (subscription.periodEndFormatted != null)
                  Text(
                    subscription.autoRenew
                        ? 'Renews ${subscription.periodEndFormatted}'
                        : 'Active until ${subscription.periodEndFormatted}',
                    style: AppTypography.regular(12,
                        color: colors.accentForeground.withOpacity(0.75)),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subscription.isMonthly ? 'Monthly' : 'Yearly',
              style: AppTypography.semiBold(11, color: colors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Selector ──────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final AppColorScheme colors;
  final SubscriptionController ctrl;
  const _PlanSelector({required this.colors, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ctrl.plans
          .map((plan) => _PlanCard(
                plan: plan,
                colors: colors,
                isSelected: ctrl.selectedPlanCode == plan.code,
                onTap: () => ctrl.selectPlan(plan.code),
                showBadge: plan.isYearly,
              ))
          .toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanEntity plan;
  final AppColorScheme colors;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.colors,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.08) : colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                    width: 2),
                color: isSelected ? colors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.name,
                          style: AppTypography.semiBold(14,
                              color: colors.foreground)),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.yellow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Best Value',
                              style: AppTypography.bold(10,
                                  color: colors.yellow)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.description,
                    style: AppTypography.regular(12,
                        color: colors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              plan.formattedPrice,
              style: AppTypography.bold(14,
                  color: isSelected ? colors.primary : colors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Benefits List ──────────────────────────────────────────────────────────────

class _BenefitsList extends StatelessWidget {
  final AppColorScheme colors;
  const _BenefitsList({required this.colors});

  static const _benefits = [
    (FeatherIcons.zap, 'Unlimited AI mock interviews'),
    (FeatherIcons.barChart2, 'Detailed performance analytics'),
    (FeatherIcons.messageSquare, 'In-depth question-by-question feedback'),
    (FeatherIcons.target, 'Role-specific interview preparation'),
    (FeatherIcons.trendingUp, 'Progress tracking over time'),
    (FeatherIcons.shield, 'Priority access to new features'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's included",
            style: AppTypography.semiBold(15, color: colors.foreground)),
        const SizedBox(height: 12),
        ..._benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(b.$1, size: 16, color: colors.accentForeground),
                  ),
                  const SizedBox(width: 12),
                  Text(b.$2,
                      style: AppTypography.regular(13,
                          color: colors.foreground)),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Subscribe Button ───────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final AppColorScheme colors;
  final SubscriptionController ctrl;
  const _SubscribeButton({required this.colors, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final plan = ctrl.selectedPlan;
    final isLoading = ctrl.isSubscribing;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : ctrl.subscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primaryForeground,
              disabledBackgroundColor: colors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    plan != null
                        ? 'Subscribe — ${plan.formattedPrice}'
                        : 'Subscribe',
                    style: AppTypography.bold(15, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure payment via Razorpay. Cancel anytime.',
          style: AppTypography.regular(12, color: colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Manage Section (for existing subscribers) ──────────────────────────────────

class _ManageSection extends StatelessWidget {
  final AppColorScheme colors;
  final SubscriptionController ctrl;
  const _ManageSection({required this.colors, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: ctrl.refreshSubscription,
          icon: const Icon(FeatherIcons.refreshCw, size: 16),
          label: const Text('Refresh Status'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 12),
        if (ctrl.subscription.autoRenew && !ctrl.subscription.isCancelled)
          TextButton(
            onPressed: ctrl.isCancelling
                ? null
                : () => _showCancelConfirm(context, ctrl),
            style: TextButton.styleFrom(
              foregroundColor: colors.destructive,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: ctrl.isCancelling
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.destructive),
                  )
                : const Text('Cancel Subscription'),
          ),
        if (ctrl.subscription.isCancelled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.info,
                    size: 16, color: colors.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your subscription has been cancelled. '
                    'Access continues until '
                    '${ctrl.subscription.periodEndFormatted ?? 'period end'}.',
                    style: AppTypography.regular(12,
                        color: colors.mutedForeground, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelConfirm(
      BuildContext context, SubscriptionController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel subscription?'),
        content: const Text(
          'Your Premium access will remain active until the end of the '
          'current billing cycle, then your plan will revert to Free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Premium'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ctrl.cancelSubscription(cancelAtCycleEnd: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel at cycle end'),
          ),
        ],
      ),
    );
  }
}

// ── Overlays ───────────────────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  const _ProcessingOverlay({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(message,
                style:
                    AppTypography.semiBold(16, color: colors.foreground),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Please do not close this screen.',
              style:
                  AppTypography.regular(13, color: colors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onDone;
  const _SuccessOverlay({required this.colors, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(color: colors.accent, shape: BoxShape.circle),
              child:
                  Icon(FeatherIcons.star, color: colors.success, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Premium Activated! 🎉',
                style: AppTypography.bold(22, color: colors.foreground),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'You now have unlimited access to all AI interview features.',
              style: AppTypography.regular(14,
                  color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Start Practicing',
                    style: AppTypography.bold(15, color: Colors.white)),
              ),
            ),
          ],
        ),
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
            Icon(FeatherIcons.wifi, size: 48, color: colors.yellow),
            const SizedBox(height: 20),
            Text('Checking Payment Status',
                style: AppTypography.semiBold(16, color: colors.foreground),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.regular(13,
                  color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(FeatherIcons.refreshCw, size: 16),
              label: const Text('Check Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(200, 48),
              ),
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
  const _ErrorState(
      {required this.colors, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.alertCircle,
                size: 40, color: colors.destructive),
            const SizedBox(height: 16),
            Text(message,
                style: AppTypography.regular(13,
                    color: colors.mutedForeground, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  const _ErrorBanner({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.destructive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.destructive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.alertCircle,
              size: 16, color: colors.destructive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    AppTypography.regular(12, color: colors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final AppColorScheme colors;
  final String message;
  const _InfoBanner({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(FeatherIcons.info, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.regular(12,
                    color: colors.mutedForeground)),
          ),
        ],
      ),
    );
  }
}
