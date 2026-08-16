import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _twoFactorEnabled = true;
  bool _updating = false;

  void _changePassword() async {
    if (_newPasswordController.text.length < 8 ||
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords must match and be at least 8 characters long.')),
      );
      return;
    }

    setState(() => _updating = true);
    final auth = context.read<AuthController>();
    await auth.changePassword(_currentPasswordController.text, _newPasswordController.text);

    if (mounted) {
      setState(() {
        _updating = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final auth = context.watch<AuthController>();

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Account & Security',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          // Two-Factor Authentication
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
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
                  child: Icon(FeatherIcons.shield, size: 20, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: AppTypography.semiBold(14, color: colors.foreground),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Require a 6-digit code upon login',
                        style: AppTypography.regular(10, color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _twoFactorEnabled,
                  activeThumbColor: colors.primary,
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Change Password',
            style: AppTypography.bold(16, color: colors.foreground),
          ),
          const SizedBox(height: 14),

          Text('Current Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _currentPasswordController,
            placeholder: 'Enter current password',
            obscureText: true,
          ),

          Text('New Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _newPasswordController,
            placeholder: 'At least 8 characters',
            obscureText: true,
          ),

          Text('Confirm New Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmPasswordController,
            placeholder: 'Re-enter new password',
            obscureText: true,
          ),

          const SizedBox(height: 12),

          AppButton(
            label: _updating ? 'Updating password...' : 'Update Password',
            icon: FeatherIcons.lock,
            disabled: _updating,
            onPress: _changePassword,
          ),

          const SizedBox(height: 32),

          // Danger Zone
          Text(
            'Danger Zone',
            style: AppTypography.bold(16, color: colors.destructive),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.destructive.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.destructive.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Account',
                  style: AppTypography.bold(14, color: colors.destructive),
                ),
                const SizedBox(height: 4),
                Text(
                  'Permanently delete your account, saved resumes, and completed interview reports.',
                  style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.45),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Delete Account',
                      message: 'Are you sure? This action cannot be undone and all your interview history will be lost.',
                      confirmLabel: 'Permanently Delete',
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.destructive,
                    side: BorderSide(color: colors.destructive),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Delete Account', style: AppTypography.semiBold(12, color: colors.destructive)),
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
