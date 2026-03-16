import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/otp_provider.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/modern_background.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(otpProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final emailOrPhone = ref.read(otpProvider).pendingEmailOrPhone;
    if (emailOrPhone == null || emailOrPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expired. Please request a new code.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/forgot-password',
          (route) => false,
        );
      }
      return;
    }

    final success = await ref.read(otpProvider.notifier).verifyOtp(
          emailOrPhone,
          _otpController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code verified. Set your new password.'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);
    final emailOrPhone = otpState.pendingEmailOrPhone ?? '';

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: AuthScaffold(
              title: 'Enter code',
              subtitle: 'We sent a verification code to $emailOrPhone',
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
                  validator: Validation.otp,
                  enabled: !otpState.isLoading,
                ),
                const SizedBox(height: 32),
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
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: otpState.isLoading
                      ? null
                      : () {
                          ref.read(otpProvider.notifier).clearError();
                          Navigator.of(context).pop();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AuthUiCommon.primaryGreen,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

