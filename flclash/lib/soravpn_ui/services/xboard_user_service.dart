import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';
import 'xboard_auth_service.dart';

/// Xboard 用户服务
/// 处理用户信息、订阅、统计等操作
class XboardUserService {
  /// 获取用户信息
  static Future<XboardUser> getUserInfo() async {
    print('[XboardUserService] Getting user info from: ${XboardConfig.userInfoUrl}');

    final response = await xboardClient.get(
      XboardConfig.userInfoUrl,
      fromJson: (data) {
        print('[XboardUserService] User info raw data: $data');
        return XboardUser.fromJson(data as Map<String, dynamic>);
      },
    );

    print('[XboardUserService] Response success: ${response.success}, message: ${response.message}');

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get user info');
    }

    if (response.data == null) {
      throw Exception('No user data received');
    }

    print('[XboardUserService] User: id=${response.data!.id}, planId=${response.data!.planId}, expiredAt=${response.data!.expiredAt}');

    // 保存用户数据到本地
    await XboardAuthService.saveUserData(response.data!.toJson());

    return response.data!;
  }

  /// 获取订阅信息
  static Future<XboardSubscribe> getSubscribe() async {
    final response = await xboardClient.get(
      XboardConfig.userSubscribeUrl,
      fromJson: (data) => XboardSubscribe.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get subscribe info');
    }

    if (response.data == null) {
      throw Exception('No subscribe data received');
    }

    // 保存订阅 URL 到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(XboardConfig.subscribeUrlKey, response.data!.subscribeUrl);

    return response.data!;
  }

  /// 获取用户统计信息 (流量日志)
  static Future<XboardUserStat> getUserStat() async {
    final response = await xboardClient.get(
      XboardConfig.userStatUrl,
      fromJson: (data) => XboardUserStat.fromJson(data),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get user stat');
    }

    return response.data ?? XboardUserStat();
  }

  /// 获取流量日志
  static Future<List<TrafficRecord>> getTrafficLog({int page = 1, int pageSize = 10}) async {
    final response = await xboardClient.get<List<dynamic>>(
      '${XboardConfig.trafficLogUrl}?page=$page&limit=$pageSize',
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get traffic log');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => TrafficRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 重置订阅 (重置订阅链接的安全密钥)
  static Future<String> resetSubscribeSecurity() async {
    final response = await xboardClient.get(
      XboardConfig.resetSubscribeUrl,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to reset subscribe');
    }

    // 重新获取订阅信息以更新 URL
    final subscribe = await getSubscribe();
    return subscribe.subscribeUrl;
  }

  /// 修改密码
  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.changePasswordUrl,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to change password');
    }

    return true;
  }

  /// 获取用户配置
  static Future<Map<String, dynamic>> getUserConfig() async {
    final response = await xboardClient.get(
      XboardConfig.userConfigUrl,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get user config');
    }

    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {};
  }

  /// 获取公告列表
  static Future<List<XboardNotice>> getNotices() async {
    final response = await xboardClient.get(
      XboardConfig.noticeFetchUrl,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get notices');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => XboardNotice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取知识库列表
  static Future<List<XboardKnowledge>> getKnowledge() async {
    final response = await xboardClient.get(
      XboardConfig.knowledgeFetchUrl,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get knowledge');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => XboardKnowledge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取存储的订阅 URL
  static Future<String?> getStoredSubscribeUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(XboardConfig.subscribeUrlKey);
  }

  /// 刷新用户所有信息
  /// 返回包含用户信息和订阅信息的 Map
  static Future<Map<String, dynamic>> refreshAllUserInfo() async {
    try {
      // 并行获取用户信息和订阅信息
      final results = await Future.wait([
        getUserInfo(),
        getSubscribe(),
      ]);

      return {
        'user': results[0] as XboardUser,
        'subscribe': results[1] as XboardSubscribe,
      };
    } catch (e) {
      throw Exception('Failed to refresh user info: $e');
    }
  }
}
