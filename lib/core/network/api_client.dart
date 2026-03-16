import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'ssl_pinning.dart';

/// Reusable Dio-based API client with token interceptor.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.httpClientAdapter = createHttpClientAdapter();
    _dio.interceptors.add(_RefreshInterceptor());
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ApiLogInterceptor());
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  static Future<void> init() async {
    await _instance._migrateTokensFromSharedPrefs();
    await _instance._loadTokens();
  }

  /// One-time migration: move tokens from SharedPreferences to SecureStorage.
  Future<void> _migrateTokensFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(ApiConstants.tokenKey);
    final oldRefresh = prefs.getString(ApiConstants.refreshTokenKey);
    if (oldToken != null || oldRefresh != null) {
      if (oldToken != null) await SecureStorage.setToken(oldToken);
      if (oldRefresh != null) await SecureStorage.setRefreshToken(oldRefresh);
      await prefs.remove(ApiConstants.tokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
    }
  }

  String? _storedToken;
  String? get token => _storedToken;

  String? _storedRefreshToken;
  String? get refreshToken => _storedRefreshToken;

  Future<void> _loadTokens() async {
    _storedToken = await SecureStorage.getToken();
    _storedRefreshToken = await SecureStorage.getRefreshToken();
  }

  Future<void> setToken(String? token) async {
    _storedToken = token;
    await SecureStorage.setToken(token);
  }

  Future<void> setRefreshToken(String? refreshToken) async {
    _storedRefreshToken = refreshToken;
    await SecureStorage.setRefreshToken(refreshToken);
  }

  Future<void> clearToken() async {
    _storedToken = null;
    _storedRefreshToken = null;
    await SecureStorage.clearTokens();
  }
}

/// On 401: try refresh token, then retry request. If refresh fails, forward error.
class _RefreshInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _handle401(err, handler);
  }

  Future<void> _handle401(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final client = ApiClient();
    final refreshToken = client.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }
    final options = err.requestOptions;
    if (options.extra['_retried'] == true) {
      handler.next(err);
      return;
    }
    try {
      final response = await client.dio.post<Map<String, dynamic>>(
        ApiConstants.refreshPath,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {...?options.headers}..remove('Authorization'),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'];
        if (data is Map<String, dynamic>) {
          final access = data['access'];
          final newToken = access is Map ? access['token'] as String? : null;
          final newRefresh = data['refresh_token'] as String?;
          if (newToken != null && newToken.isNotEmpty) {
            await client.setToken(
              newToken.startsWith('Bearer ') ? newToken.replaceFirst('Bearer ', '') : newToken,
            );
            if (newRefresh != null) await client.setRefreshToken(newRefresh);
            options.extra['_retried'] = true;
            options.headers['Authorization'] = 'Bearer ${client.token}';
            final res = await client.dio.fetch(options);
            return handler.resolve(res);
          }
        }
      }
    } catch (_) {}
    handler.next(err);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = ApiClient().token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Logs API requests/responses only in debug; never logs Authorization or tokens.
class _ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final uri = options.uri.toString();
      final q = options.queryParameters.isNotEmpty ? '?${options.queryParameters}' : '';
      debugPrint('[API] → ${options.method} $uri$q');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final uri = response.requestOptions.uri.toString();
      debugPrint('[API] ← ${response.statusCode} $uri');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final status = err.response?.statusCode;
      final uri = err.requestOptions.uri.toString();
      // 401 on login is expected (invalid credentials), don't log as ERROR
      if (status == 401 && uri.contains('/api/login')) {
        debugPrint('[API] ← 401 $uri (invalid credentials)');
      } else {
        debugPrint('[API] ✗ ERROR $uri');
        debugPrint('[API]    ${err.type} ${err.message}');
      }
    }
    handler.next(err);
  }
}
