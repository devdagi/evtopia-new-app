import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';

/// Result of an auth operation (success with user + token, or error message).
class AuthResult {
  const AuthResult.success(this.user, this.token, {this.emailVerified = true})
      : errorMessage = null,
        validationErrors = null,
        unverifiedEmail = null;
  AuthResult._failure(
    this.errorMessage,
    this.validationErrors,
    String? unverifiedEmailParam,
  )  : user = null,
        token = null,
        emailVerified = true,
        unverifiedEmail = unverifiedEmailParam;

  factory AuthResult.failure(
    String errorMessage, [
    Map<String, List<String>>? validationErrors,
    String? unverifiedEmail,
  ]) =>
      AuthResult._failure(errorMessage, validationErrors, unverifiedEmail);

  final UserModel? user;
  final String? token;
  /// From backend registration: false when user must verify email with OTP.
  final bool emailVerified;
  final String? errorMessage;
  final Map<String, List<String>>? validationErrors;
  /// When login returns 403 (email not verified), backend sends OTP and returns this email.
  final String? unverifiedEmail;

  bool get isSuccess => user != null && token != null;
}

/// Handles registration, login, and token persistence via API.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Register a new user.
  /// Returns [AuthResult] with user + token on 200, or error/validation on failure.
  Future<AuthResult> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.registerPath,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _payload(response.data!);
        final auth = _parseAuthResponse(payload);
        if (auth != null) {
          await _api.setToken(auth.token);
          if (auth.refreshToken != null) await _api.setRefreshToken(auth.refreshToken);
          final emailVerified = _parseEmailVerified(payload['email_verified']);
          return AuthResult.success(auth.user, auth.token, emailVerified: emailVerified);
        }
      }
      return AuthResult.failure('Registration failed. Please try again.');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Log in with email or phone and password (evtopia-ecom accepts either).
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final trimmed = emailOrPhone.trim();
      if (trimmed.isEmpty) {
        return AuthResult.failure('Please enter your email or phone number.');
      }
      
      // CRITICAL: Trim password to match web behavior
      final cleanPassword = password.trim();
      if (cleanPassword.isEmpty) {
        return AuthResult.failure('Please enter your password.');
      }
      
      final isEmail = trimmed.contains('@');
      
      // Normalize email to lowercase for consistency with backend
      final identifier = isEmail ? trimmed.toLowerCase() : trimmed;
      
      final requestData = {
        if (isEmail) 'email': identifier,
        if (!isEmail) 'phone': identifier,
        'password': cleanPassword, // Use trimmed password
      };
      
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.loginPath,
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _payload(response.data!);
        final auth = _parseAuthResponse(payload);
        if (auth != null) {
          await _api.setToken(auth.token);
          if (auth.refreshToken != null) await _api.setRefreshToken(auth.refreshToken);
          final emailVerified = _parseEmailVerified(payload['email_verified']);
          return AuthResult.success(auth.user, auth.token, emailVerified: emailVerified);
        }
      }
      return AuthResult.failure('Login failed. Please try again.');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Clear token and notify backend (POST /api/logout with optional refresh_token to revoke it).
  Future<void> logout() async {
    try {
      await _api.dio.post(
        ApiConstants.logoutPath,
        data: _api.refreshToken != null ? {'refresh_token': _api.refreshToken} : null,
      );
    } on Object {
      // Ignore errors; clear token locally anyway
    }
    await _api.clearToken();
  }

  /// Check if user is logged in (has stored token).
  Future<bool> isLoggedIn() async {
    final token = _api.token;
    return token != null && token.isNotEmpty;
  }

  /// Fetch current user from /api/me (validates token, returns user or null if invalid/expired).
  Future<UserModel?> fetchCurrentUser() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.mePath);
      if (response.statusCode == 200 && response.data != null) {
        final payload = _payload(response.data!);
        final userJson = payload['user'];
        final access = payload['access'];
        if (userJson != null) {
          final user = UserModel.fromJson(userJson as Map<String, dynamic>);
          final newToken = access is Map ? (access['token'] as String?) : null;
          if (newToken != null && newToken.isNotEmpty) {
            await _api.setToken(newToken.startsWith('Bearer ') ? newToken.replaceFirst('Bearer ', '') : newToken);
          }
          return user;
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _api.clearToken();
      }
    }
    return null;
  }

  /// Backend wraps success in { message, data: { ... } }.
  /// Update user profile. If [profileImage] is provided, sends multipart/form-data with profile_photo.
  Future<AuthResult> updateProfile({
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
    try {
      final bool hasFile = profileImage != null && await profileImage.exists();

      if (hasFile) {
        final formData = FormData.fromMap({
          'name': name,
          if (email?.isNotEmpty == true) 'email': email ?? '',
          if (phone?.isNotEmpty == true) 'phone': phone ?? '',
          if (phoneCode?.isNotEmpty == true) 'phone_code': phoneCode ?? '',
          if (gender?.isNotEmpty == true) 'gender': gender!.toLowerCase(),
          if (dateOfBirth?.isNotEmpty == true) 'date_of_birth': dateOfBirth ?? '',
          if (country?.isNotEmpty == true) 'country': country ?? '',
          if (make?.isNotEmpty == true) 'make': make ?? '',
          if (model?.isNotEmpty == true) 'model': model ?? '',
          if (year?.isNotEmpty == true) 'year': year ?? '',
          if (serviceDate?.isNotEmpty == true) 'service_date': serviceDate ?? '',
          'profile_photo': await MultipartFile.fromFile(
            profileImage!.path,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });

        final response = await _api.dio.post<Map<String, dynamic>>(
          ApiConstants.updateProfilePath,
          data: formData,
        );

        if (response.statusCode == 200 && response.data != null) {
          final payload = _payload(response.data!);
          final userJson = payload['user'];
          if (userJson != null) {
            final user = UserModel.fromJson(userJson as Map<String, dynamic>);
            return AuthResult.success(user, _api.token ?? '');
          }
        }
        return AuthResult.failure('Profile update failed.');
      }

      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.updateProfilePath,
        data: {
          'name': name,
          if (email?.isNotEmpty == true) 'email': email,
          if (phone?.isNotEmpty == true) 'phone': phone,
          if (phoneCode?.isNotEmpty == true) 'phone_code': phoneCode,
          if (gender?.isNotEmpty == true) 'gender': gender!.toLowerCase(),
          if (dateOfBirth?.isNotEmpty == true) 'date_of_birth': dateOfBirth,
          if (country?.isNotEmpty == true) 'country': country,
          if (make?.isNotEmpty == true) 'make': make,
          if (model?.isNotEmpty == true) 'model': model,
          if (year?.isNotEmpty == true) 'year': year,
          if (serviceDate?.isNotEmpty == true) 'service_date': serviceDate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = _payload(response.data!);
        final userJson = payload['user'];
        if (userJson != null) {
          final user = UserModel.fromJson(userJson as Map<String, dynamic>);
          return AuthResult.success(user, _api.token ?? '');
        }
      }
      return AuthResult.failure('Profile update failed.');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Change password.
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.changePasswordPath,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        // Success typically returns a message, we can return success with current user/token
        // Ideally reload user, but for now just success indicator
        return const AuthResult.success(null, ''); 
      }
      return AuthResult.failure(_message(response.data!) ?? 'Failed to change password.');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }

  /// Parse email_verified from backend (bool, 0/1, or "true"/"false"). After register, default to false so OTP screen shows.
  bool _parseEmailVerified(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  String? _message(Map<String, dynamic> data) {
    return data['message'] as String? ?? data['error'] as String?;
  }

  AuthResponseModel? _parseAuthResponse(Map<String, dynamic> data) {
    try {
      return AuthResponseModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  AuthResult _handleDioError(DioException e) {
    final data = e.response?.data;
    final msg = data is Map
        ? _message(data as Map<String, dynamic>)
        : null;
    // 400 Bad Request (invalid credentials) or 401/403 auth errors: show server message
    final status = e.response?.statusCode;
    if (msg != null && (status == 403 || status == 401 || status == 400)) {
      final payload = data is Map ? _payload(data as Map<String, dynamic>) : null;
      final email = payload?['email'] as String?;
      final unverified = email?.trim().isNotEmpty == true ? email : null;
      return AuthResult.failure(msg, null, unverified);
    }
    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = <String, List<String>>{};
        final errorsMap = data['errors'] as Map<String, dynamic>? ?? data;
        for (final entry in errorsMap.entries) {
          if (entry.value is List) {
            errors[entry.key] =
                (entry.value as List).map((e) => e.toString()).toList();
          } else {
            errors[entry.key] = [entry.value.toString()];
          }
        }
        final message = errors.isEmpty
            ? (data['message'] as String?) ?? 'Validation failed.'
            : errors.entries
                .map((e) => '${e.key}: ${e.value.join(", ")}')
                .join('\n');
        return AuthResult.failure(message, errors.isEmpty ? null : errors);
      }
    }

    if (msg != null) return AuthResult.failure(msg);

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AuthResult.failure('Network error. Check your connection.');
    }

    return AuthResult.failure(e.message ?? 'Something went wrong.');
  }
}
