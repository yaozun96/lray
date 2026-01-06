/// User Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 Xboard 服务
///
/// 新代码请直接使用:
/// - XboardUserService
/// - XboardInviteService

import '../models/xboard_models.dart';
import 'xboard_user_service.dart';
import 'xboard_auth_service.dart';
import 'xboard_invite_service.dart';

/// User service for SoraVPN
/// 现已迁移到 Xboard API
class UserService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await XboardAuthService.getToken();
    if (token == null) {
      throw Exception('Not logged in');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  /// Get supported OAuth methods - Xboard 可能不支持
  @Deprecated('Xboard may not support OAuth methods')
  static Future<List<String>> getOAuthMethods() async {
    // Xboard 标准版不支持 OAuth
    return [];
  }

  /// Get Site Config
  static Future<Map<String, dynamic>> getSiteConfig() async {
    try {
      final config = await XboardAuthService.getGuestConfig();
      if (config == null) return {};

      return {
        'app_name': config.appName,
        'app_description': config.appDescription,
        'app_url': config.appUrl,
        'logo': config.logo,
        'is_email_verify': config.isEmailVerify,
        'is_invite_force': config.isInviteForce,
        'is_recaptcha': config.isRecaptcha,
      };
    } catch (e) {
      print('Get site config failed: $e');
      return {};
    }
  }

  /// Bind OAuth Account - Xboard 可能不支持
  @Deprecated('Xboard may not support OAuth binding')
  static Future<String> bindOAuth(String method) async {
    throw Exception('OAuth binding is not supported');
  }

  /// Unbind OAuth Account - Xboard 可能不支持
  @Deprecated('Xboard may not support OAuth unbinding')
  static Future<void> unbindOAuth(String method) async {
    throw Exception('OAuth unbinding is not supported');
  }

  /// Update user password
  static Future<void> updatePassword(String password) async {
    // Xboard 需要旧密码，这里无法完全兼容
    // 如果需要修改密码，请使用 XboardUserService.changePassword
    throw Exception('Please use XboardUserService.changePassword with old password');
  }

  /// Bind email - Xboard 使用不同的流程
  @Deprecated('Xboard may not support email binding')
  static Future<void> bindEmail(String email) async {
    throw Exception('Email binding is not supported');
  }

  /// Update notification settings - Xboard 可能不支持
  @Deprecated('Xboard may not support notification settings')
  static Future<void> updateNotify({
    required bool enableBalanceNotify,
    required bool enableLoginNotify,
    required bool enableSubscribeNotify,
    required bool enableTradeNotify,
  }) async {
    // Xboard 标准版可能不支持这些设置
    print('Warning: Notification settings may not be supported by Xboard');
  }

  /// 获取用户信息
  static Future<XboardUser> getUserInfo() async {
    return await XboardUserService.getUserInfo();
  }

  /// 获取订阅信息
  static Future<XboardSubscribe> getSubscribe() async {
    return await XboardUserService.getSubscribe();
  }

  /// 获取公告列表
  static Future<List<XboardNotice>> getNotices() async {
    return await XboardUserService.getNotices();
  }

  /// 获取知识库
  static Future<List<XboardKnowledge>> getKnowledge() async {
    return await XboardUserService.getKnowledge();
  }

  /// 获取邀请信息
  static Future<XboardInvite> getInviteInfo() async {
    return await XboardInviteService.getInviteInfo();
  }

  /// 生成邀请码
  static Future<XboardInviteCode> generateInviteCode() async {
    return await XboardInviteService.generateInviteCode();
  }

  /// 佣金转账
  static Future<bool> transferCommission(int amount) async {
    return await XboardInviteService.transferCommission(amount);
  }
}
