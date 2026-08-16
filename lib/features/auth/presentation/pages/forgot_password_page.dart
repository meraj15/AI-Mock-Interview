import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController(text: 'meraj.khan@email.com');
  bool _sent = false;

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

          if (_sent) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.mail, size: 28, color: colors.accentForeground),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Check your inbox',
                    style: AppTypography.bold(28, color: colors.foreground),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'We sent a reset link to ${_emailController.text}. It will be valid for 30 minutes.',
                      style: AppTypography.regular(14, color: colors.mutedForeground, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Back to sign in',
                    icon: FeatherIcons.arrowRight,
                    onPress: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ] else ...[
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
              label: 'Send reset link',
              icon: FeatherIcons.send,
              onPress: () {
                setState(() => _sent = true);
              },
            ),

            const SizedBox(height: 24),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Remembered your password? Sign in',
                  style: AppTypography.semiBold(12, color: colors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
