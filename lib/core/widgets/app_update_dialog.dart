import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo updateInfo;
  final UpdateDecision decision;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.decision,
  });

  static bool _isShowing = false;

  /// Display the appropriate update modal/dialog according to [decision].
  static Future<void> show({
    required BuildContext context,
    required AppVersionInfo updateInfo,
    required UpdateDecision decision,
  }) async {
    if (_isShowing || decision == UpdateDecision.none) return;

    _isShowing = true;
    final isForce = decision == UpdateDecision.force;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isForce,
        routeSettings: const RouteSettings(name: 'app_update_dialog'),
        builder: (ctx) => PopScope(
          canPop: !isForce,
          onPopInvokedWithResult: (didPop, _) {
            // Prevent popping when force update is active
          },
          child: AppUpdateDialog(
            updateInfo: updateInfo,
            decision: decision,
          ),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  Future<void> _handleUpdateNow(BuildContext context) async {
    final rawUrl = updateInfo.storeUrl.trim();
    if (rawUrl.isEmpty) {
      _showError(context, 'Store URL is not configured. Please check back later.');
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      _showError(context, 'Invalid store URL configuration.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showError(context, 'Could not open store link. Please search in the App Store / Play Store.');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Failed to launch store link. Please try again.');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final isForce = decision == UpdateDecision.force;

    final displayTitle = isForce
        ? (updateInfo.title.isNotEmpty ? updateInfo.title : 'Update Required')
        : (updateInfo.title.isNotEmpty ? updateInfo.title : 'New Update Available');

    final displayMessage = isForce
        ? (updateInfo.message.isNotEmpty
            ? updateInfo.message
            : 'A new version of AI Mock Interview is required to continue.')
        : (updateInfo.message.isNotEmpty
            ? updateInfo.message
            : 'A new version with performance improvements and new features is available.');

    final items = updateInfo.whatsNew.isNotEmpty
        ? updateInfo.whatsNew
        : const [
            'Faster AI interviews',
            'Better voice experience',
            'Improved follow-up questions',
            'Bug fixes',
          ];

    return Dialog(
      backgroundColor: colors.card,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isForce
              ? colors.destructive.withValues(alpha: 0.3)
              : colors.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon Badge ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isForce
                        ? colors.destructive.withValues(alpha: 0.12)
                        : colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isForce
                          ? colors.destructive.withValues(alpha: 0.28)
                          : colors.primary.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isForce ? FeatherIcons.alertCircle : FeatherIcons.downloadCloud,
                    color: isForce ? colors.destructive : colors.primary,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                displayTitle,
                textAlign: TextAlign.center,
                style: AppTypography.bold(
                  18,
                  color: colors.foreground,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 6),

              // ── Version Badge ─────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Version ${updateInfo.latestVersion}',
                    style: AppTypography.semiBold(
                      11,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Message ───────────────────────────────────────────────────
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: AppTypography.regular(
                  13,
                  color: colors.mutedForeground,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              // ── What's New Box ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's New:",
                      style: AppTypography.semiBold(
                        12,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✓ ',
                              style: TextStyle(
                                color: colors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTypography.regular(
                                  12,
                                  color: colors.foreground,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Action Buttons ────────────────────────────────────────────
              AppButton(
                label: 'Update Now',
                icon: FeatherIcons.arrowUpCircle,
                onPress: () => _handleUpdateNow(context),
              ),

              if (!isForce) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Later',
                  variant: ButtonVariant.secondary,
                  onPress: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
