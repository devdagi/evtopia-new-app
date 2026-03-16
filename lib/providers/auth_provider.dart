import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state: authenticated user or null, loading, error, email verification, and skip (guest).
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = false,
    this.errorMessage,
    this.needsEmailVerification = false,
    this.pendingVerificationEmail,
    this.isSkipped = false,
  });

  final UserModel? user;
  final bool isLoading;
  /// True only during initial session restore (_checkAuth). Full-screen loader uses this.
  /// Login/register use [isLoading] so the form stays visible and shows button spinner.
  final bool isInitializing;
  final String? errorMessage;
  /// True after registration when backend returns email_verified: false (OTP sent to email).
  final bool needsEmailVerification;
  /// Email to verify when login returned 403 (unverified). Show OTP screen with this email.
  final String? pendingVerificationEmail;
  /// True when user tapped "Skip" on login — show main app as guest (no auth).
  /// Null-safe for hot reload / existing state that may not have had this field.
  final bool? isSkipped;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitializing,
    String? errorMessage,
    bool? needsEmailVerification,
    String? pendingVerificationEmail,
    bool? isSkipped,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: errorMessage,
      needsEmailVerification: needsEmailVerification ?? this.needsEmailVerification,
      pendingVerificationEmail: pendingVerificationEmail ?? this.pendingVerificationEmail,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  /// Logged in (has user + token). Unverified email users can still use the app.
  bool get isAuthenticated => user != null;

  /// Show main shell when logged in or when user skipped login (guest).
  bool get canShowMainApp => isAuthenticated || (isSkipped == true);

  /// True when user is logged in but email is not verified (show drop-down notice).
  bool get shouldShowVerifyEmailBanner =>
      user != null && !(user!.emailVerified);
}

/// Provides [ApiClient] (initialized in main).
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provides [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

/// Auth state notifier: register, login, logout, loading & error.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState(isInitializing: true)) {
    _checkAuth();
  }

  final AuthService _authService;

  Future<void> _checkAuth() async {
    state = state.copyWith(isInitializing: true, errorMessage: null);
    final hasToken = await _authService.isLoggedIn();
    if (!hasToken) {
      state = state.copyWith(user: null, isInitializing: false, errorMessage: null);
      return;
    }
    // Token exists: restore session by fetching current user from /api/me
    final user = await _authService.fetchCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user, isInitializing: false, errorMessage: null);
    } else {
      state = state.copyWith(user: null, isInitializing: false, errorMessage: null);
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authService.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
    state = state.copyWith(isLoading: false);
    if (result.isSuccess && result.user != null && result.token != null) {
      state = state.copyWith(
        user: result.user,
        errorMessage: null,
        needsEmailVerification: !result.emailVerified,
      );
    } else {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
  }

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authService.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
    state = state.copyWith(isLoading: false);
    if (result.isSuccess && result.user != null && result.token != null) {
      // Allow unverified users in (same as signup); they can verify from profile tab.
      state = state.copyWith(
        user: result.user,
        errorMessage: null,
        needsEmailVerification: false,
        pendingVerificationEmail: null,
      );
    } else {
      state = state.copyWith(errorMessage: result.errorMessage);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  /// Skip sign-in and show main app as guest (pages that don't require auth).
  void skipLogin() {
    state = state.copyWith(isSkipped: true, errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Call after user verifies email via OTP (verify-otp API success).
  void markEmailVerified() {
    final u = state.user;
    state = state.copyWith(
      needsEmailVerification: false,
      user: u != null ? u.copyWith(emailVerified: true) : null,
    );
  }

  /// Clear email pending verification (after verify from login flow; user can log in again).
  void clearPendingVerificationEmail() {
    state = AuthState(
      user: state.user,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      needsEmailVerification: state.needsEmailVerification,
      pendingVerificationEmail: null,
    );
  }
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? phoneCode,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? make,
    String? model,
    String? year,
    String? serviceDate,
    String? email,
    File? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authService.updateProfile(
      name: name,
      phone: phone,
      phoneCode: phoneCode,
      gender: gender,
      dateOfBirth: dateOfBirth,
      country: country,
      make: make,
      model: model,
      year: year,
      serviceDate: serviceDate,
      email: email,
      profileImage: profileImage,
    );
    state = state.copyWith(isLoading: false);

    if (result.isSuccess && result.user != null) {
      state = state.copyWith(
        user: result.user,
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: result.errorMessage);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    state = state.copyWith(isLoading: false);

    if (result.errorMessage == null) {
      return true;
    } else {
      state = state.copyWith(errorMessage: result.errorMessage);
      return false;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// When true, the "Verify your email" drop banner is hidden (user dismissed it).
final verifyBannerDismissedProvider = StateProvider<bool>((ref) => false);
