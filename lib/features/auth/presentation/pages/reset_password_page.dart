import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool get hasMinLength => _newPasswordController.text.length >= 8;
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get hasSpecialChar => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_newPasswordController.text);
  bool get passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  void _submit() async {
    if (!hasMinLength || !passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please satisfy all password criteria and confirm.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully! Please sign in with your new password.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Set New Password',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),
          Text(
            'Create a strong password',
            style: AppTypography.bold(26, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            'Your new password must be different from previous passwords.',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.45),
          ),

          const SizedBox(height: 24),

          Text('New Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _newPasswordController,
            placeholder: 'Enter new password',
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 6),
          Text('Confirm New Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmPasswordController,
            placeholder: 'Re-enter new password',
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          // Criteria checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildCheckItem('At least 8 characters long', hasMinLength, colors),
                const SizedBox(height: 6),
                _buildCheckItem('Contains at least one number', hasNumber, colors),
                const SizedBox(height: 6),
                _buildCheckItem('Contains a special character', hasSpecialChar, colors),
                const SizedBox(height: 6),
                _buildCheckItem('Passwords match', passwordsMatch, colors),
              ],
            ),
          ),

          const SizedBox(height: 28),

          AppButton(
            label: _isLoading ? 'Updating password...' : 'Reset Password',
            icon: FeatherIcons.arrowRight,
            disabled: _isLoading || !hasMinLength || !passwordsMatch,
            onPress: _submit,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool satisfied, AppColorScheme colors) {
    return Row(
      children: [
        Icon(
          satisfied ? FeatherIcons.checkCircle : FeatherIcons.circle,
          size: 14,
          color: satisfied ? colors.success : colors.mutedForeground,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.regular(
            11,
            color: satisfied ? colors.foreground : colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
