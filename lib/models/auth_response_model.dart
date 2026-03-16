import 'user_model.dart';

/// Response model for login/register (evtopia-ecom: data.user + data.access.token + data.refresh_token).
class AuthResponseModel {
  const AuthResponseModel({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  final UserModel user;
  final String token;
  final String? refreshToken;

  /// Backend returns { message?, data: { user, access: { token }, refresh_token? } }.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];
    final access = json['access'];
    final token = access is Map
        ? (access['token'] as String? ?? '')
        : (json['token'] as String? ?? json['access_token'] as String? ?? '');
    final refreshToken = json['refresh_token'] as String?;
    return AuthResponseModel(
      user: UserModel.fromJson(
        Map<String, dynamic>.from(userMap as Map),
      ),
      token: token,
      refreshToken: refreshToken,
    );
  }
}
