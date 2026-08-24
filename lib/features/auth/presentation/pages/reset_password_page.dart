import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  /// In dev mode the backend returns the OTP directly so you can test
  /// without an email service. Pass it here to pre-fill the field.
  /// Will be empty string in production.
  final String devOtp;

  const ResetPasswordPage({
    super.key,
    required this.email,
    this.devOtp = '',
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController _otpController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // ── Criteria ──────────────────────────────────────────────────────────────
  bool get _otpValid => _otpController.text.trim().length == 6 &&
      RegExp(r'^\d{6}$').hasMatch(_otpController.text.trim());
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_newPasswordController.text);
  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;
  bool get _canSubmit =>
      _otpValid && _hasMinLength && _hasNumber && _passwordsMatch && !_isLoading;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.devOtp);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final success = await auth.resetPassword(
      email: widget.email,
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      setState(() =>
          _errorMessage = auth.errorMessage ?? 'Invalid or expired code. Please try again.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset successfully! Please sign in.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
            style: AppTypography.bold(24, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${widget.email} and choose a new password.',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.45),
          ),

          const SizedBox(height: 24),

          // ── OTP field ────────────────────────────────────────────────────
          Row(
            children: [
              Text('Reset code', style: AppTypography.semiBold(12, color: colors.foreground)),
              const SizedBox(width: 6),
              if (widget.devOtp.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEV — pre-filled',
                    style: AppTypography.bold(9, color: colors.mint),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _otpController,
            placeholder: '6-digit code',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _errorMessage = null),
          ),

          const SizedBox(height: 14),

          // ── New password ────────────────────────────────────────────────
          Text('New password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _newPasswordController,
            placeholder: 'Enter new password',
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          Text('Confirm password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmPasswordController,
            placeholder: 'Re-enter new password',
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // ── Criteria checklist ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildCheck('Valid 6-digit reset code', _otpValid, colors),
                const SizedBox(height: 6),
                _buildCheck('At least 8 characters', _hasMinLength, colors),
                const SizedBox(height: 6),
                _buildCheck('Contains at least one number', _hasNumber, colors),
                const SizedBox(height: 6),
                _buildCheck('Contains a special character', _hasSpecialChar, colors),
                const SizedBox(height: 6),
                _buildCheck('Passwords match', _passwordsMatch, colors),
              ],
            ),
          ),

          // ── Error banner ────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.coral.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(FeatherIcons.alertCircle, size: 14, color: colors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.regular(12, color: colors.coral),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          AppButton(
            label: _isLoading ? 'Resetting password...' : 'Reset Password',
            icon: FeatherIcons.check,
            disabled: !_canSubmit,
            onPress: _submit,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCheck(String label, bool satisfied, AppColorScheme colors) {
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
