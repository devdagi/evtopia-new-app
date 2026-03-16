import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../services/otp_service.dart';

/// OTP / reset-password flow state.
class OtpState {
  const OtpState({
    this.pendingEmailOrPhone,
    this.verificationToken,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Set after send OTP success; used for verify and reset.
  final String? pendingEmailOrPhone;
  /// Backend token from verify-otp response; required for reset-password.
  final String? verificationToken;
  final bool isLoading;
  final String? errorMessage;

  OtpState copyWith({
    String? pendingEmailOrPhone,
    String? verificationToken,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OtpState(
      pendingEmailOrPhone: pendingEmailOrPhone ?? this.pendingEmailOrPhone,
      verificationToken: verificationToken ?? this.verificationToken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final otpServiceProvider = Provider<OtpService>((ref) {
  return OtpService(ref.watch(apiClientProvider));
});

class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier(this._service) : super(const OtpState());

  final OtpService _service;

  Future<bool> sendOtp(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.sendOtp(emailOrPhone);
    state = state.copyWith(isLoading: false);
    if (result.isSuccess) {
      state = state.copyWith(
        pendingEmailOrPhone: emailOrPhone.trim(),
        errorMessage: null,
      );
      return true;
    }
    state = state.copyWith(errorMessage: result.errorMessage);
    return false;
  }

  Future<bool> verifyOtp(String emailOrPhone, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.verifyOtp(emailOrPhone, otp);
    state = state.copyWith(isLoading: false);
    if (result.isSuccess) {
      state = state.copyWith(
        verificationToken: result.verificationToken ?? '',
        errorMessage: null,
      );
      return true;
    }
    state = state.copyWith(errorMessage: result.errorMessage);
    return false;
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.resetPassword(
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    state = state.copyWith(isLoading: false);
    if (result.isSuccess) {
      state = const OtpState(); // clear pending + verifiedOtp
      return true;
    }
    state = state.copyWith(errorMessage: result.errorMessage);
    return false;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Current identifier for verify/reset (from last successful send OTP).
  String? get pendingEmailOrPhone => state.pendingEmailOrPhone;
}

final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>((ref) {
  return OtpNotifier(ref.watch(otpServiceProvider));
});
