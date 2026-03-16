import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/otp_provider.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/modern_background.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(otpProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final token = ref.read(otpProvider).verificationToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Session expired. Please start again from Forgot Password.'),
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

    final success = await ref.read(otpProvider.notifier).resetPassword(
          token: token,
          newPassword: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset. You can sign in now.'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: AuthScaffold(
              title: 'Set new password',
              subtitle: 'Use at least 6 characters for a secure password.',
              children: [
                if (otpState.errorMessage != null) ...[
                  AuthErrorBanner(message: otpState.errorMessage!),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'New password',
                    hintText: '6+ characters',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AuthUiCommon.primaryGreen,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validation.resetPassword,
                  enabled: !otpState.isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AuthUiCommon.primaryGreen,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (v) => Validation.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
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
                          'Reset password',
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

