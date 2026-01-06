import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';

/// Xboard 认证服务
/// 处理登录、注册、密码重置等认证相关操作
class XboardAuthService {
  static const String _tokenKey = XboardConfig.tokenKey;
  static const String _userDataKey = XboardConfig.userDataKey;

  /// 发送邮箱验证码
  /// [email] 邮箱地址
  /// [isForgetPassword] 是否用于忘记密码
  static Future<bool> sendEmailVerify({
    required String email,
    bool isForgetPassword = false,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.sendEmailVerifyUrl,
      data: {
        'email': email,
        // Xboard API 使用不同的参数名
      },
      requiresAuth: false,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to send verification code');
    }

    return true;
  }

  /// 用户注册
  /// [email] 邮箱
  /// [password] 密码
  /// [emailCode] 邮箱验证码
  /// [inviteCode] 邀请码 (可选)
  static Future<bool> register({
    required String email,
    required String password,
    String? emailCode,
    String? inviteCode,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (emailCode != null && emailCode.isNotEmpty) {
      data['email_code'] = emailCode;
    }

    if (inviteCode != null && inviteCode.isNotEmpty) {
      data['invite_code'] = inviteCode;
    }

    final response = await xboardClient.post(
      XboardConfig.registerUrl,
      data: data,
      requiresAuth: false,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Registration failed');
    }

    // 注册成功后自动登录
    if (response.data != null && response.data is Map) {
      final authData = response.data as Map<String, dynamic>;
      final token = authData['auth_data'] ?? authData['token'];

      if (token != null) {
        await xboardClient.saveToken(token.toString());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode({'email': email}));
        return true;
      }
    }

    return true;
  }

  /// 用户登录
  /// [email] 邮箱
  /// [password] 密码
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.loginUrl,
      data: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    print('[XboardAuthService] Login response: success=${response.success}, data=${response.data}');

    if (!response.success) {
      throw Exception(response.message ?? 'Login failed');
    }

    // 保存 Token
    if (response.data != null && response.data is Map) {
      final authData = response.data as Map<String, dynamic>;
      // Xboard 返回 auth_data 作为 Token
      final token = authData['auth_data'] ?? authData['token'];

      if (token != null) {
        await xboardClient.saveToken(token.toString());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode({'email': email}));
        print('[XboardAuthService] Token saved successfully');
        return true;
      } else {
        print('[XboardAuthService] No token in response: $authData');
        throw Exception('Invalid response: no token received');
      }
    }

    throw Exception('Invalid response format');
  }

  /// 重置密码
  /// [email] 邮箱
  /// [password] 新密码
  /// [emailCode] 邮箱验证码
  static Future<bool> resetPassword({
    required String email,
    required String password,
    required String emailCode,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.forgotPasswordUrl,
      data: {
        'email': email,
        'password': password,
        'email_code': emailCode,
      },
      requiresAuth: false,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Password reset failed');
    }

    return true;
  }

  /// 登出
  static Future<void> logout() async {
    await xboardClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(XboardConfig.subscribeUrlKey);
    print('[XboardAuthService] Logged out');
  }

  /// 检查是否已登录
  static Future<bool> isLoggedIn() async {
    await xboardClient.loadToken();
    return xboardClient.token != null && xboardClient.token!.isNotEmpty;
  }

  /// 获取当前 Token
  static Future<String?> getToken() async {
    if (xboardClient.token != null && xboardClient.token!.isNotEmpty) {
      return xboardClient.token;
    }
    await xboardClient.loadToken();
    return xboardClient.token;
  }

  /// 获取存储的用户数据
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// 保存用户数据到本地
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// 获取公共配置 (无需登录)
  static Future<XboardGuestConfig?> getGuestConfig() async {
    final response = await xboardClient.get(
      XboardConfig.guestConfigUrl,
      requiresAuth: false,
      fromJson: (data) => XboardGuestConfig.fromJson(data as Map<String, dynamic>),
    );

    if (response.success) {
      return response.data;
    }

    return null;
  }
}
