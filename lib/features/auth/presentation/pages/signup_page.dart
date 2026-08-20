import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../onboarding/presentation/pages/profile_setup_page.dart';
import '../controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController(text: 'Meraj Khan');
  final _emailController = TextEditingController(text: 'meraj.khan@email.com');
  final _passwordController = TextEditingController(text: 'Password123');

  void _submit() async {
    final auth = context.read<AuthController>();
    final success = await auth.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupPage(),
        ),
      );
    } else if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
            title: 'Create account',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 30),

          Text(
            'Build your edge',
            style: AppTypography.bold(31, color: colors.foreground),
          ),
          const SizedBox(height: 9),
          Text(
            'A few details and we’ll tailor every practice session to you.',
            style: AppTypography.regular(14, color: colors.mutedForeground, height: 1.4),
          ),

          const SizedBox(height: 32),

          Text(
            'Your name',
            style: AppTypography.semiBold(12, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            placeholder: 'Full name',
          ),

          const SizedBox(height: 6),
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

          const SizedBox(height: 6),
          Text(
            'Password',
            style: AppTypography.semiBold(12, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _passwordController,
            placeholder: 'Create a password',
            obscureText: true,
          ),

          if (auth.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.coral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.coral.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(FeatherIcons.alertCircle, size: 16, color: colors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: AppTypography.semiBold(11, color: colors.coral),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 12),

          AppButton(
            label: 'Create my account',
            icon: FeatherIcons.arrowRight,
            isLoading: auth.isLoading,
            onPress: _submit,
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: colors.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'or sign up with',
                    style: AppTypography.regular(11, color: colors.mutedForeground),
                  ),
                ),
                Expanded(child: Divider(color: colors.border, thickness: 1)),
              ],
            ),
          ),

          // Social Row
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final success = await auth.signInWithGoogle();
                      if (success && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Ink(
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FeatherIcons.chrome, size: 17, color: colors.foreground),
                          const SizedBox(width: 8),
                          Text(
                            'Google',
                            style: AppTypography.semiBold(13, color: colors.foreground),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final success = await auth.signInWithApple();
                      if (success && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Ink(
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FeatherIcons.smartphone, size: 17, color: colors.foreground),
                          const SizedBox(width: 8),
                          Text(
                            'Apple',
                            style: AppTypography.semiBold(13, color: colors.foreground),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
