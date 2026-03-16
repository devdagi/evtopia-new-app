import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/otp_provider.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/modern_background.dart';

/// Verify email via OTP. Opened from profile ("Verify my email") or after register.
/// When opened from profile, OTP is sent on load so user can enter the code.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _sentOtpFromProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSendOtpFromProfile());
  }

  Future<void> _maybeSendOtpFromProfile() async {
    final authState = ref.read(authProvider);
    final email = authState.user?.email;
    if (email == null || email.isEmpty || authState.pendingVerificationEmail != null) return;
    if (_sentOtpFromProfile) return;
    _sentOtpFromProfile = true;
    await ref.read(otpProvider.notifier).sendOtp(email);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(otpProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final email = ref.read(authProvider).pendingVerificationEmail ??
        ref.read(authProvider).user?.email;
    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email not found. Please log in again.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    final success = await ref.read(otpProvider.notifier).verifyOtp(
          email,
          _otpController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      final hadPendingEmail =
          ref.read(authProvider).pendingVerificationEmail != null;
      if (hadPendingEmail) {
        ref.read(authProvider.notifier).clearPendingVerificationEmail();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verified. You can now log in.'),
            backgroundColor: AuthUiCommon.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ref.read(authProvider.notifier).markEmailVerified();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verified. Welcome!'),
              backgroundColor: AuthUiCommon.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _resendOtp() async {
    final email = ref.read(authProvider).pendingVerificationEmail ??
        ref.read(authProvider).user?.email;
    if (email == null || email.isEmpty) return;

    ref.read(otpProvider.notifier).clearError();
    final success = await ref.read(otpProvider.notifier).sendOtp(email);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent. Check your email.'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ref.read(otpProvider).errorMessage ?? 'Failed to resend OTP'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final otpState = ref.watch(otpProvider);
    final email =
        authState.pendingVerificationEmail ?? authState.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ModernBackground(
        child: Form(
          key: _formKey,
          child: AuthScaffold(
            title: 'Verify Email',
            subtitle: 'We sent a verification code to $email. Enter it below.',
            children: [
              if (otpState.errorMessage != null) ...[
                AuthErrorBanner(message: otpState.errorMessage!),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                onFieldSubmitted: (_) => _submit(),
                decoration: AuthUiCommon.inputDecoration(
                  labelText: 'Verification code',
                  hintText: 'e.g. 123456',
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.pin_outlined,
                    color: AuthUiCommon.primaryGreen,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
                validator: Validation.otp,
                enabled: !otpState.isLoading,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: otpState.isLoading ? null : _submit,
                style: AuthUiCommon.primaryButtonStyle(),
                child: otpState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify Account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: otpState.isLoading ? null : _resendOtp,
                style: TextButton.styleFrom(
                  foregroundColor: AuthUiCommon.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Didn't receive a code? Resend",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
