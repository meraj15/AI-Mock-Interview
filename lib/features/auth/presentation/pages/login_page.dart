import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'meraj.khan@email.com');
  final _passwordController = TextEditingController(text: 'password');

  void _submit() async {
    final auth = context.read<AuthController>();
    final success = await auth.signIn(_emailController.text, _passwordController.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final auth = context.watch<AuthController>();

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Brand
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colors.primary,
                    child: const Icon(FeatherIcons.award, color: Colors.white, size: 20),
                  ),

                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Interview Coach',
                style: AppTypography.bold(16, color: colors.foreground),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Copy
          Text(
            'Welcome back',
            style: AppTypography.bold(32, color: colors.foreground),
          ),
          const SizedBox(height: 9),
          Text(
            'Your next great interview starts with one good answer.',
            style: AppTypography.regular(14, color: colors.mutedForeground, height: 1.4),
          ),

          const SizedBox(height: 32),

          // Form
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
            placeholder: 'Your password',
            obscureText: true,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: AppTypography.semiBold(12, color: colors.primary),
              ),
            ),
          ),

          const SizedBox(height: 22),

          AppButton(
            label: 'Sign in',
            icon: FeatherIcons.arrowRight,
            isLoading: auth.isLoading,
            onPress: _submit,
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: colors.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'or continue with',
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
                    onTap: _submit,
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
                    onTap: _submit,
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

          const SizedBox(height: 40),

          // Bottom switch
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New here?',
                  style: AppTypography.regular(13, color: colors.mutedForeground),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: Text(
                    ' Create an account',
                    style: AppTypography.semiBold(13, color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
