/// Authentication Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 XboardAuthService
///
/// 新代码请直接使用:
/// - XboardAuthService (认证)
/// - XboardUserService (用户信息)

import '../config/xboard_config.dart';
import 'xboard_auth_service.dart';
import 'xboard_user_service.dart';

/// Authentication service for SoraVPN
/// 现已迁移到 Xboard API
class AuthService {
  static String get _baseUrl => XboardConfig.apiBaseUrl;

  /// Login with email and password
  /// Returns true if successful, throws exception on error
  static Future<bool> login(String email, String password) async {
    return await XboardAuthService.login(email: email, password: password);
  }

  /// Register new user
  /// Returns true if successful, throws exception on error
  static Future<bool> register({
    required String email,
    required String password,
    String? emailCode,
    String? inviteCode,
  }) async {
    return await XboardAuthService.register(
      email: email,
      password: password,
      emailCode: emailCode,
      inviteCode: inviteCode,
    );
  }

  /// Send email verification code
  /// [type]: 1=Register, 2=ResetPassword, 3=Bind
  static Future<bool> sendEmailCode(String email, {int type = 1}) async {
    return await XboardAuthService.sendEmailVerify(
      email: email,
      isForgetPassword: type == 2,
    );
  }

  /// Reset password
  /// Returns true if successful, throws exception on error
  static Future<bool> resetPassword(String email, String password, String code) async {
    return await XboardAuthService.resetPassword(
      email: email,
      password: password,
      emailCode: code,
    );
  }

  /// Logout user
  static Future<void> logout() async {
    await XboardAuthService.logout();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await XboardAuthService.isLoggedIn();
  }

  /// Get stored auth token
  static Future<String?> getToken() async {
    return await XboardAuthService.getToken();
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    return await XboardAuthService.getStoredUserData();
  }

  /// Get user info from server
  static Future<Map<String, dynamic>> getUserInfo() async {
    final user = await XboardUserService.getUserInfo();
    return user.toJson();
  }

  /// Get OAuth login URL - Xboard 可能不支持 OAuth
  @Deprecated('Xboard may not support OAuth login')
  static Future<String?> getOAuthLoginUrl(String method) async {
    // Xboard 标准版不支持 OAuth，返回 null
    return null;
  }

  /// Login with OAuth code - Xboard 可能不支持 OAuth
  @Deprecated('Xboard may not support OAuth login')
  static Future<bool> loginWithOAuthCode(String code, String state) async {
    // Xboard 标准版不支持 OAuth
    throw Exception('OAuth login is not supported');
  }
}
