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
import 'email_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEmailValid =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());

  void _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isEmailValid) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final otp = await auth.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (otp == null) {
      // Controller set an errorMessage
      setState(() => _errorMessage = auth.errorMessage ?? 'Something went wrong. Try again.');
      return;
    }

    // Navigate to reset page — pass the email and the dev-mode OTP
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailVerificationPage(
          email: email,
          mode: VerificationMode.passwordReset,
          devOtp: otp,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            title: 'Reset password',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 30),
          Text(
            'Forgot your password?',
            style: AppTypography.bold(25, color: colors.foreground, height: 1.25),
          ),
          const SizedBox(height: 11),
          Text(
            'Enter the email you use for Interview Coach and we\'ll send a secure reset code.',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
          ),

          const SizedBox(height: 32),

          Text(
            'Email address',
            style: AppTypography.semiBold(12, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            placeholder: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _errorMessage = null),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
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

          const SizedBox(height: 20),

          AppButton(
            label: _isLoading ? 'Sending code...' : 'Send reset code',
            icon: FeatherIcons.arrowRight,
            disabled: _isLoading,
            onPress: _sendReset,
          ),
        ],
      ),
    );
  }
}
