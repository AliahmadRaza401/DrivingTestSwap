import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const Duration _resendCooldown = Duration(seconds: 60);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  Timer? _cooldownTimer;
  bool _sending = false;
  int _secondsUntilResend = 0;
  String? _lastSentEmail;

  bool get _canSend => !_sending && _secondsUntilResend == 0;

  @override
  void initState() {
    super.initState();
    final initialEmail = Get.arguments is String ? Get.arguments as String : '';
    _emailController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_canSend) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    final email = _emailController.text.trim();
    final error = await AuthService.sendPasswordResetEmail(email: email);
    if (!mounted) return;

    setState(() => _sending = false);
    if (error != null) {
      ToastUtil.error(error);
      return;
    }

    ToastUtil.success(
      'Password reset email sent. Check your inbox to update your password.',
      title: 'Email sent',
      duration: const Duration(seconds: 4),
    );
    _startResendCooldown(email);
  }

  void _startResendCooldown(String email) {
    _cooldownTimer?.cancel();
    setState(() {
      _lastSentEmail = email;
      _secondsUntilResend = _resendCooldown.inSeconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsUntilResend <= 1) {
        timer.cancel();
        setState(() => _secondsUntilResend = 0);
        return;
      }

      setState(() => _secondsUntilResend--);
    });
  }

  String _formatCountdown() {
    final minutes = _secondsUntilResend ~/ 60;
    final seconds = _secondsUntilResend % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _buttonText() {
    if (_lastSentEmail == null) return 'Send reset link';
    if (_secondsUntilResend > 0) return 'Resend in ${_formatCountdown()}';
    return 'Resend link';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 36),
                _buildLabel('Email Address'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sending,
                  decoration: _inputDecoration(
                    hint: 'you@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your email';
                    }
                    if (!GetUtils.isEmail(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                if (_lastSentEmail != null) ...[
                  const SizedBox(height: 18),
                  _buildSentState(),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _canSend ? _sendResetLink : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _buttonText(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_lastSentEmail != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _secondsUntilResend > 0
                        ? 'You can request another link in ${_formatCountdown()}.'
                        : 'You can resend the link now.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _sending ? null : () => Get.back(),
                  child: const Text('Back to login'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Reset your password',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your account email and we will send a secure password reset link.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSentState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reset link sent to $_lastSentEmail. Check your inbox and spam folder.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixIcon,
    );
  }
}
