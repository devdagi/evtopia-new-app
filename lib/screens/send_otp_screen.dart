import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/otp_provider.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/modern_background.dart';

class SendOtpScreen extends ConsumerStatefulWidget {
  const SendOtpScreen({super.key});

  @override
  ConsumerState<SendOtpScreen> createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends ConsumerState<SendOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider.notifier).clearError();
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(otpProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(otpProvider.notifier).sendOtp(
          _emailController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent. Check your email or phone.'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/verify-otp');
    }
  }

  static String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    return Validation.email(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: AuthScaffold(
              title: 'Forgot password',
              subtitle: 'Enter your email and we’ll send you a verification code.',
              children: [
                if (otpState.errorMessage != null) ...[
                  AuthErrorBanner(message: otpState.errorMessage!),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AuthUiCommon.primaryGreen,
                    ),
                  ),
                  validator: _emailValidator,
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
                          'Send code',
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
                          ref.read(authProvider.notifier).clearError();
                          Navigator.of(context).pop();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AuthUiCommon.primaryGreen,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

