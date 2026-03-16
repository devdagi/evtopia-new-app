import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

/// Result of an OTP/password-reset operation.
class OtpResult {
  const OtpResult.success({this.verificationToken}) : errorMessage = null;
  const OtpResult.failure(this.errorMessage) : verificationToken = null;

  final String? verificationToken;
  final String? errorMessage;
  bool get isSuccess => errorMessage == null;
}

/// Detects if input looks like email or phone for API payload.
bool _isEmail(String value) {
  return value.trim().contains('@');
}

/// Handles send OTP, verify OTP, and reset password via API.
class OtpService {
  OtpService(this._api);

  final ApiClient _api;

  /// Send OTP to email or phone. Uses [email] or [phone] in request body.
  Future<OtpResult> sendOtp(String emailOrPhone) async {
    try {
      final data = _isEmail(emailOrPhone)
          ? <String, dynamic>{'email': emailOrPhone.trim()}
          : <String, dynamic>{'phone': emailOrPhone.trim()};

      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.sendOtpPath,
        data: data,
      );

      if (response.statusCode == 200) {
        return const OtpResult.success();
      }
      return OtpResult.failure(
        _extractMessage(response.data) ?? 'Failed to send OTP.',
      );
    } on DioException catch (e) {
      return OtpResult.failure(_handleDioError(e));
    }
  }

  /// Verify OTP. Backend returns data: { token, email_verified }; we need that token for reset.
  Future<OtpResult> verifyOtp(String emailOrPhone, String otp) async {
    try {
      final data = _isEmail(emailOrPhone)
          ? <String, dynamic>{'email': emailOrPhone.trim(), 'otp': otp.trim()}
          : <String, dynamic>{'phone': emailOrPhone.trim(), 'otp': otp.trim()};

      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.verifyOtpPath,
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _payload(response.data as Map<String, dynamic>);
        final token = payload['token'] as String?;
        return OtpResult.success(verificationToken: token ?? '');
      }
      return OtpResult.failure(
        _extractMessage(response.data) ?? 'Invalid or expired OTP.',
      );
    } on DioException catch (e) {
      return OtpResult.failure(_handleDioError(e));
    }
  }

  /// Reset password (evtopia-ecom: token from verify-otp, password, password_confirmation). Password min 6.
  Future<OtpResult> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.resetPasswordPath,
        data: {
          'token': token,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        return const OtpResult.success();
      }
      return OtpResult.failure(
        _extractMessage(response.data) ?? 'Failed to reset password.',
      );
    } on DioException catch (e) {
      return OtpResult.failure(_handleDioError(e));
    }
  }

  /// Backend wraps success in { message?, data: { ... } }.
  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }

  String _handleDioError(DioException e) {
    final message = _extractMessage(e.response?.data);
    if (message != null) return message;

    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>? ?? data;
        final parts = <String>[];
        for (final entry in errors.entries) {
          if (entry.value is List) {
            parts.add('${entry.key}: ${(entry.value as List).join(", ")}');
          } else {
            parts.add('${entry.key}: ${entry.value}');
          }
        }
        if (parts.isNotEmpty) return parts.join('\n');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection.';
    }

    return e.message ?? 'Something went wrong.';
  }
}
