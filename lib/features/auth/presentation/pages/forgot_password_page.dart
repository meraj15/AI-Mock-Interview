import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController(text: 'meraj.khan@email.com');
  bool _isLoading = false;

  void _sendReset() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: _emailController.text.trim()),
        ),
      );
    }
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
            style: AppTypography.bold(29, color: colors.foreground, height: 1.25),
          ),
          const SizedBox(height: 11),
          Text(
            'No problem. Enter the email you use for Interview Coach and we’ll send a secure reset link.',
            style: AppTypography.regular(14, color: colors.mutedForeground, height: 1.5),
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
          ),

          const SizedBox(height: 20),

          AppButton(
            label: _isLoading ? 'Sending link...' : 'Send reset link',
            icon: FeatherIcons.arrowRight,
            disabled: _isLoading,
            onPress: _sendReset,
          ),
        ],
      ),
    );
  }
}
