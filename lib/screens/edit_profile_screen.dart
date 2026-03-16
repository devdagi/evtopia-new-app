import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/countries.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/image_url.dart';
import '../utils/validation.dart';
import '../widgets/auth_ui_common.dart';
import '../widgets/skeleton_loader.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isInitializing = true;

  late TextEditingController _nameController;
  late TextEditingController _phoneCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _emailController;

  String? _country;
  String? _gender;

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  /// Returns a value that matches one of [_genders], or null. Handles API lowercase (e.g. "male").
  static String? _genderDropdownValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    for (final g in _genders) {
      if (g.toLowerCase() == lower) return g;
    }
    return null;
  }

  static Widget _profilePhotoPlaceholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 60,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });

    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneCodeController = TextEditingController(text: user?.phoneCode ?? '+251');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _dateOfBirthController = TextEditingController(
      text: _formatDisplayDate(user?.dateOfBirth),
    );
    _emailController = TextEditingController(text: user?.email ?? '');
    _country = user?.country;
    _gender = user?.gender;

    // Delay showing the heavy form to allow smooth transition
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  static String? _formatDisplayDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      final y = parts[0].length == 4 ? parts[0] : parts[2];
      final m = parts[1].padLeft(2, '0');
      final d = (parts[0].length == 4 ? parts[2] : parts[0]).padLeft(2, '0');
      return '$m/$d/$y';
    }
    return iso;
  }

  static String? _toIsoDate(String? display) {
    if (display == null || display.isEmpty) return null;
    final parts = display.split(RegExp(r'[/]'));
    if (parts.length >= 3) {
      final m = parts[0].padLeft(2, '0');
      final d = parts[1].padLeft(2, '0');
      final y = parts[2];
      return '$y-$m-$d';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneCodeController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    final phoneCode = _phoneCodeController.text.trim();
    final number = _phoneController.text.trim();
    final phone = number.isNotEmpty ? number : null;

    final success = await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: phone,
          phoneCode: phoneCode.isNotEmpty ? phoneCode : null,
          gender: _gender,
          dateOfBirth: _toIsoDate(_dateOfBirthController.text.trim()),
          country: _country,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _onChangePhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    if (!await file.exists() || !mounted) return;

    final success = await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text.trim().isEmpty ? (ref.read(authProvider).user?.name ?? '') : _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          phoneCode: _phoneCodeController.text.trim().isEmpty ? null : _phoneCodeController.text.trim(),
          gender: _gender,
          dateOfBirth: _toIsoDate(_dateOfBirthController.text.trim()),
          country: _country,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          profileImage: file,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo updated'),
          backgroundColor: AuthUiCommon.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).errorMessage ?? 'Failed to update photo'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = authState.user;
    final profilePhotoUrl = user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty ? imageUrl(user.profilePhoto) : '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AuthUiCommon.primaryGreen,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isInitializing
            ? const SkeletonEditProfile()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authState.errorMessage != null) _ErrorBanner(message: authState.errorMessage!),

                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AuthUiCommon.primaryGreen, AuthUiCommon.primaryGreen.withValues(alpha: 0.3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: profilePhotoUrl.isNotEmpty
                                ? Image.network(
                                    profilePhotoUrl,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (_, __, ___) => _profilePhotoPlaceholder(theme),
                                  )
                                : _profilePhotoPlaceholder(theme),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _onChangePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AuthUiCommon.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Grouped Form Fields
                _buildFormSection(
                  theme,
                  title: 'IDENTITY',
                  children: [
                    _buildField(
                      label: 'Full Name',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(theme, 'Enter your name', Icons.person_outline_rounded),
                        validator: (v) => Validation.required(v, 'Name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Gender',
                      child: DropdownButtonFormField<String>(
                        value: _genderDropdownValue(_gender),
                        decoration: _inputDecoration(theme, 'Select Gender', Icons.wc_rounded),
                        items: [
                          ..._genders.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ],
                ),

                _buildFormSection(
                  theme,
                  title: 'CONTACT INFO',
                  children: [
                    _buildField(
                      label: 'Email Address',
                      child: TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: _inputDecoration(theme, 'Email', Icons.email_outlined).copyWith(
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Phone Number',
                      child: Row(
                        children: [
                          SizedBox(
                            width: 85,
                            child: TextFormField(
                              controller: _phoneCodeController,
                              decoration: _inputDecoration(theme, '+251', null),
                              keyboardType: TextInputType.phone,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: _inputDecoration(theme, '912345678', Icons.phone_android_rounded),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildFormSection(
                  theme,
                  title: 'ADDITIONAL DETAILS',
                  children: [
                    _buildField(
                      label: 'Date of Birth',
                      child: TextFormField(
                        controller: _dateOfBirthController,
                        readOnly: true,
                        decoration: _inputDecoration(theme, 'MM/DD/YYYY', Icons.calendar_month_rounded),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            _dateOfBirthController.text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Country',
                      child: DropdownButtonFormField<String>(
                        value: _country != null && _country!.isNotEmpty ? _country : null,
                        decoration: _inputDecoration(theme, 'Select Country', Icons.public_rounded),
                        items: Countries.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _country = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                FilledButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthUiCommon.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(ThemeData theme, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return child; // Labels are now hinted or separate as per design
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint, IconData? prefixIcon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AuthUiCommon.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
        ],
      ),
    );
  }
}
