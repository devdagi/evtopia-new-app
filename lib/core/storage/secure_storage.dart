import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// Secure storage for tokens (uses platform keychain/Keystore).
/// Prefer this over SharedPreferences for sensitive data.
class SecureStorage {
  SecureStorage._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _storage = FlutterSecureStorage(aOptions: _androidOptions);

  static Future<String?> getToken() => _storage.read(key: ApiConstants.tokenKey);
  static Future<String?> getRefreshToken() =>
      _storage.read(key: ApiConstants.refreshTokenKey);

  static Future<void> setToken(String? value) async {
    if (value != null && value.isNotEmpty) {
      await _storage.write(key: ApiConstants.tokenKey, value: value);
    } else {
      await _storage.delete(key: ApiConstants.tokenKey);
    }
  }

  static Future<void> setRefreshToken(String? value) async {
    if (value != null && value.isNotEmpty) {
      await _storage.write(key: ApiConstants.refreshTokenKey, value: value);
    } else {
      await _storage.delete(key: ApiConstants.refreshTokenKey);
    }
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
  }
}
