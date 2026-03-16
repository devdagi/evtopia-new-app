import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/modern_background.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.user != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: AuthScaffold(
              title: 'Create account',
              subtitle: 'Join Evtopia with your details',
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                if (authState.errorMessage != null) ...[
                  AuthErrorBanner(message: authState.errorMessage!),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Name',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AuthUiCommon.primaryGreen,
                    ),
                  ),
                  validator: (v) => Validation.required(v, 'Name'),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Phone',
                    hintText: '+2519...',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AuthUiCommon.primaryGreen,
                    ),
                  ),
                  validator: Validation.phone,
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AuthUiCommon.primaryGreen,
                    ),
                  ),
                  validator: Validation.email,
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: AuthUiCommon.inputDecoration(
                    labelText: 'Password',
                    hintText: '8+ chars, letter, number, symbol',
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
                  validator: Validation.registrationPassword,
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: AuthUiCommon.primaryButtonStyle(),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref.read(authProvider.notifier).clearError();
                              Navigator.of(context).pop();
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AuthUiCommon.primaryGreen,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

