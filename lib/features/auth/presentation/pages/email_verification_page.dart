import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/auth_controller.dart';
import 'profile_setup_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 45;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (_countdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _countdown--);
      }
    }
  }

  void _resend() async {
    setState(() {
      _resending = true;
      _countdown = 45;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _resending = false);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new 6-digit verification code was sent to your email.')),
      );
    }
  }

  void _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code.')),
      );
      return;
    }

    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.verifyEmailOtp(code);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
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
            title: 'Verify Email',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.mail, size: 28, color: colors.primary),
          ),

          const SizedBox(height: 20),
          Text(
            'Check your inbox',
            style: AppTypography.bold(26, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit verification code to:\n${widget.email}',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
          ),

          const SizedBox(height: 32),

          // 6-digit OTP Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                height: 56,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: AppTypography.bold(22, color: colors.foreground),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: colors.card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_controllers.every((c) => c.text.isNotEmpty)) {
                      _verify();
                    }
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          AppButton(
            label: auth.isLoading ? 'Verifying...' : 'Verify and Continue',
            icon: FeatherIcons.check,
            disabled: auth.isLoading,
            onPress: _verify,
          ),

          const SizedBox(height: 20),

          Center(
            child: _countdown > 0
                ? Text(
                    'Resend code in ${_countdown}s',
                    style: AppTypography.regular(12, color: colors.mutedForeground),
                  )
                : TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(
                      'Resend verification code',
                      style: AppTypography.semiBold(13, color: colors.primary),
                    ),
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
