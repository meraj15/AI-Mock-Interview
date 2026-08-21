import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/pages/main_nav_page.dart';
import '../controllers/auth_controller.dart';
import 'email_verification_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  // Live password strength state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _showStrengthHints = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final p = _passwordController.text;
    setState(() {
      _hasMinLength = p.length >= 8;
      _hasUppercase = p.contains(RegExp(r'[A-Z]'));
      _hasLowercase = p.contains(RegExp(r'[a-z]'));
      _hasNumber = p.contains(RegExp(r'[0-9]'));
    });
  }

  bool get _passwordStrong =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;

  void _submit() async {
    final auth = context.read<AuthController>();
    final success = await auth.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(email: _emailController.text),
        ),
      );
      return;
    }

    // Show each validation error as its own toast, or a single error toast
    if (!mounted) return;
    final errors = auth.validationErrors;
    if (errors.isNotEmpty) {
      // Fire one toast per error with a small delay between them
      for (int i = 0; i < errors.length; i++) {
        await Future.delayed(Duration(milliseconds: i * 400));
        _showErrorToast(errors[i]);
      }
    } else if (auth.errorMessage != null) {
      _showErrorToast(auth.errorMessage!);
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: const Color(0xFFE5534B),
      textColor: Colors.white,
      fontSize: 13.0,
    );
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


          Text(
            'Build your edge',
            style: AppTypography.bold(28, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            'A few details and we\'ll tailor every session to you.',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.4),
          ),

          const SizedBox(height: 20),

          // ── Name ────────────────────────────────────────────────────────
          Text('Full name', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            placeholder: 'e.g. Alex Johnson',
          ),

          const SizedBox(height: 7),

          // ── Email ────────────────────────────────────────────────────────
          Text('Email address', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            placeholder: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 7),

          // ── Password ─────────────────────────────────────────────────────
          Text('Password', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              AppTextField(
                controller: _passwordController,
                placeholder: 'Min 8 chars, upper, lower, number',
                obscureText: !_passwordVisible,
                onChanged: (_) => setState(() => _showStrengthHints = true),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                  child: Icon(
                    _passwordVisible ? FeatherIcons.eyeOff : FeatherIcons.eye,
                    size: 17,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          // ── Password strength hints ─────────────────────────────────────
          if (_showStrengthHints && !_passwordStrong) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password requirements',
                    style: AppTypography.semiBold(11, color: colors.foreground),
                  ),
                  const SizedBox(height: 8),
                  _PasswordRule(
                    met: _hasMinLength,
                    label: 'At least 8 characters',
                    colors: colors,
                  ),
                  _PasswordRule(
                    met: _hasUppercase,
                    label: 'One uppercase letter (A–Z)',
                    colors: colors,
                  ),
                  _PasswordRule(
                    met: _hasLowercase,
                    label: 'One lowercase letter (a–z)',
                    colors: colors,
                  ),
                  _PasswordRule(
                    met: _hasNumber,
                    label: 'One number (0–9)',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(
            height:20,
          ),
          // ── Submit ───────────────────────────────────────────────────────
          AppButton(
            label: 'Create my account',
            icon: FeatherIcons.arrowRight,
            isLoading: auth.isLoading,
            onPress: _submit,
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22.0),
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

          // ── Social ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  icon: FeatherIcons.chrome,
                  label: 'Google',
                  colors: colors,
                  onTap: () async {
                    final success = await auth.signInWithGoogle();
                    if (success && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavPage()),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialButton(
                  icon: FeatherIcons.smartphone,
                  label: 'Apple',
                  colors: colors,
                  onTap: () async {
                    final success = await auth.signInWithApple();
                    if (success && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavPage()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PasswordRule extends StatelessWidget {  final bool met;
  final String label;
  final AppColorScheme colors;

  const _PasswordRule({
    required this.met,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            met ? FeatherIcons.checkCircle : FeatherIcons.circle,
            size: 13,
            color: met ? colors.mint : colors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.regular(
              11,
              color: met ? colors.mint : colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Icon(icon, size: 17, color: colors.foreground),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.semiBold(13, color: colors.foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
