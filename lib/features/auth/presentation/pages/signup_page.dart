import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/auth_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController(text: 'Meraj Khan');
  final _emailController = TextEditingController(text: 'meraj.khan@email.com');
  final _passwordController = TextEditingController(text: 'password');

  void _submit() async {
    final auth = context.read<AuthController>();
    final success = await auth.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
        (route) => false,
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

          const SizedBox(height: 28),

          AppButton(
            label: 'Create my account',
            icon: FeatherIcons.arrowRight,
            isLoading: auth.isLoading,
            onPress: _submit,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
