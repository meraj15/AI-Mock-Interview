import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/auth_controller.dart';
import 'reset_password_page.dart';

enum VerificationMode { emailVerify, passwordReset }

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final VerificationMode mode;

  const EmailVerificationPage({
    super.key,
    required this.email,
    this.mode = VerificationMode.passwordReset,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = 60;
  bool _resending = false;
  bool _resendError = false;
  String? _resendErrorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    setState(() => _countdown = 60);
    while (_countdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _countdown--);
      }
    }
  }

  void _resend() async {
    if (_resending) return;

    setState(() {
      _resending = true;
      _resendError = false;
      _resendErrorMessage = null;
    });

    final authCtrl = context.read<AuthController>();
    final success = await authCtrl.forgotPassword(widget.email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new 6-digit reset code was sent to your email.'),
        ),
      );
      _startTimer();
    } else {
      setState(() {
        _resendError = true;
        _resendErrorMessage = authCtrl.errorMessage ?? 'Failed to resend code. Please try again.';
      });
    }

    if (mounted) setState(() => _resending = false);
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
    final resetToken = await authCtrl.verifyResetOtp(widget.email, code);

    if (!mounted) return;

    if (resetToken != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            resetToken: resetToken,
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppHeader(
            title: widget.mode == VerificationMode.passwordReset
                ? 'Enter Reset Code'
                : 'Verify Email',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 12),

          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(FeatherIcons.mail, size: 28, color: colors.primary),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Check your inbox',
            style: AppTypography.bold(26, color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            widget.mode == VerificationMode.passwordReset
                ? 'We sent a 6-digit reset code to:\n${widget.email}'
                : 'We sent a 6-digit verification code to:\n${widget.email}',
            style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // 6-digit OTP Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                height: 60,
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
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Error message from auth controller
          if (auth.status == AuthStatus.error && auth.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5534B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                auth.errorMessage!,
                style: AppTypography.regular(12, color: const Color(0xFFE5534B)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Resend error message
          if (_resendError && _resendErrorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5534B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _resendErrorMessage!,
                style: AppTypography.regular(12, color: const Color(0xFFE5534B)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          AppButton(
            label: widget.mode == VerificationMode.passwordReset
                ? 'Verify Code'
                : (auth.isLoading ? 'Verifying...' : 'Verify and Continue'),
            icon: widget.mode == VerificationMode.passwordReset
                ? FeatherIcons.arrowRight
                : FeatherIcons.check,
            disabled: auth.isLoading,
            onPress: _verify,
          ),

          const SizedBox(height: 10),

          Center(
            child: _countdown > 0
                ? Text(
                    'Resend code in ${_countdown}s',
                    style: AppTypography.regular(12, color: colors.mutedForeground),
                  )
                : TextButton(
                    onPressed: _resending ? null : _resend,
                    child: _resending
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Text(
                            widget.mode == VerificationMode.passwordReset
                                ? 'Resend reset code'
                                : 'Resend verification code',
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
