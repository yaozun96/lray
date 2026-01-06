/// 全局配置服务 - 已迁移到 Xboard API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/xboard_config.dart';
import 'xboard_auth_service.dart';

/// 全局配置服务
class ConfigService {
  static String _currencySymbol = '¥'; // 默认货币符号
  static String _currencyUnit = 'CNY'; // 默认货币单位

  static Map<String, dynamic> _authConfig = {};
  static Map<String, dynamic> _verifyConfig = {};
  static Map<String, dynamic> _guestConfig = {};
  static Map<String, dynamic> _userConfig = {};

  /// 获取货币符号
  static String get currencySymbol => _currencySymbol;

  /// 获取货币单位代码
  static String get currencyUnit => _currencyUnit;

  /// 获取验证配置
  static Map<String, dynamic> get verifyConfig => _verifyConfig;

  /// 获取认证配置
  static Map<String, dynamic> get authConfig => _authConfig;

  /// 获取邮箱配置
  static Map<String, dynamic> get emailConfig => _authConfig['email'] ?? {};

  /// 检查是否启用注册验证
  static bool get enableRegisterVerify => _guestConfig['is_email_verify'] == 1 || _guestConfig['is_email_verify'] == true;

  /// 检查是否启用邮箱验证
  static bool get enableEmailVerify => _guestConfig['is_email_verify'] == 1 || _guestConfig['is_email_verify'] == true;

  /// 检查是否强制邀请码
  static bool get enableInviteForce => _guestConfig['is_invite_force'] == 1 || _guestConfig['is_invite_force'] == true;

  /// 检查是否启用域名白名单
  // 如果有白名单列表，且不为空，则认为开启
  static bool get enableDomainSuffix => domainSuffixList.isNotEmpty;

  /// 获取域名白名单列表
  static List<String> get domainSuffixList {
    final list = _guestConfig['email_whitelist_suffix'];
    if (list is List) {
      return List<String>.from(list);
    }
    if (list is String) {
      return list.split('\n').where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  /// 获取验证码过期时间(秒)
  static int get codeExpire => _verifyConfig['code_expire'] ?? 60;

  /// 获取 OAuth 登录方式列表 - Xboard 不支持 OAuth
  static List<String> get oauthMethods => [];

  /// 获取提现方式列表
  static List<String> get withdrawMethods {
    var methods = _guestConfig['withdraw_methods'] ?? 
                 _guestConfig['withdraw_method'] ??
                 _guestConfig['commission_withdraw_method'] ??
                 _guestConfig['commission_withdraw_methods'];
                 
    // 尝试从用户配置中获取
    if (_userConfig.isNotEmpty) {
       final userMethods = _userConfig['withdraw_methods'] ?? 
                          _userConfig['withdraw_method'] ??
                          _userConfig['commission_withdraw_method'] ??
                          _userConfig['commission_withdraw_methods'];
       if (userMethods != null) {
         methods = userMethods;
       }
    }

    if (methods is List) {
      return methods.map((e) => e.toString()).toList();
    }
    if (methods is String && methods.isNotEmpty) {
      return methods.split(',').map((e) => e.trim()).toList();
    }
    return []; // 仅从后台获取，无默认值
  }

  /// 加载全局配置
  static Future<void> loadGlobalConfig() async {
    try {
      // 1. 初始化 Xboard/Remote 配置 (加载 OSS)
      await XboardConfig.init();

      // 使用 Xboard guest config API
      final url = XboardConfig.guestConfigUrl;
      print('[ConfigService] Loading config from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ConfigService] Global config response: $data');

        if (data['status'] == 'success' && data['data'] != null) {
          _guestConfig = data['data'] as Map<String, dynamic>;
        }
      } else {
        print('[ConfigService] Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      print('[ConfigService] Error loading global config: $e');
    }
  }

  /// 加载用户配置 (需要认证)
  static Future<void> loadUserConfig() async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null || token.isEmpty) {
        print('[ConfigService] loadUserConfig skipped: No token found');
        return;
      }

      final url = XboardConfig.userConfigUrl;
      print('[ConfigService] Loading user config from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      
      print('[ConfigService] User config response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final userConfig = data['data'] as Map<String, dynamic>;
          // 合并用户配置到 _guestConfig，优先使用用户配置
          // 这样 withdrawMethods 会读取用户配置中的值
          _guestConfig.addAll(userConfig);
          // 同时也保存到 _userConfig 备用
          _userConfig = userConfig;
          print('[ConfigService] User config loaded and merged: ${userConfig.keys.toList()}');
        }
      } else {
        print('[ConfigService] Failed to load user config: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ConfigService] Error loading user config: $e');
    }
  }
}
