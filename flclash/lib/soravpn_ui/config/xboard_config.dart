import '../../common/remote_config_service.dart';

/// Xboard API 配置
/// 基于 Xboard 后端 API 的配置
class XboardConfig {
  /// API 基础 URL - 默认值，会被 RemoteConfigService 覆盖
  static String _apiBaseUrl = 'https://api.cwtgo.com';

  /// 是否已初始化
  static bool _initialized = false;

  /// 获取 API 基础 URL
  /// 优先使用 RemoteConfigService 中的配置 (从 OSS 加载)
  static String get apiBaseUrl {
    // 优先从 RemoteConfigService 获取 (OSS 远程配置)
    final remoteConfig = RemoteConfigService.config;
    if (remoteConfig != null && remoteConfig.domain.isNotEmpty) {
      return remoteConfig.domain.first;
    }
    return _apiBaseUrl;
  }

  static String get currencySymbol => '¥';

  /// 设置 API 基础 URL (手动配置)
  static void setApiBaseUrl(String url) {
    _apiBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// 初始化配置 (自动从 RemoteConfigService 加载)
  /// 通常不需要手动调用，RemoteConfigService.init() 会在应用启动时调用
  static Future<void> init() async {
    if (_initialized) return;

    // 确保 RemoteConfigService 已初始化
    if (RemoteConfigService.config == null) {
      await RemoteConfigService.init();
    }

    // 如果成功获取到配置，打印日志
    final config = RemoteConfigService.config;
    if (config != null && config.domain.isNotEmpty) {
      print('[XboardConfig] Loaded API URL from OSS: ${config.domain.first}');
    } else {
      print('[XboardConfig] Using default API URL: $_apiBaseUrl');
    }

    _initialized = true;
  }

  /// API 版本前缀
  static const String apiVersion = '/api/v1';

  /// 获取完整的 API URL
  static String getApiUrl(String path) {
    return '$apiBaseUrl$apiVersion$path';
  }

  /// 获取完整的 Guest API URL (无需认证)
  static String getGuestApiUrl(String path) {
    return '$apiBaseUrl$apiVersion/guest$path';
  }

  /// 获取完整的 Passport API URL (认证相关)
  static String getPassportApiUrl(String path) {
    return '$apiBaseUrl$apiVersion/passport$path';
  }

  /// 获取完整的 User API URL (需要认证)
  static String getUserApiUrl(String path) {
    return '$apiBaseUrl$apiVersion/user$path';
  }

  // ==================== API 端点 ====================

  // 认证相关
  static String get loginUrl => getPassportApiUrl('/auth/login');
  static String get registerUrl => getPassportApiUrl('/auth/register');
  static String get forgotPasswordUrl => getPassportApiUrl('/auth/forget');
  static String get sendEmailVerifyUrl => getPassportApiUrl('/comm/sendEmailVerify');
  static String get guestConfigUrl => getGuestApiUrl('/comm/config');

  // 用户信息
  static String get userInfoUrl => getUserApiUrl('/info');
  static String get userConfigUrl => getUserApiUrl('/comm/config');
  static String get changePasswordUrl => getUserApiUrl('/changePassword');
  static String get userStatUrl => getUserApiUrl('/getStat');
  static String get userSubscribeUrl => getUserApiUrl('/getSubscribe');
  static String get resetSubscribeUrl => getUserApiUrl('/resetSecurity');

  // 套餐和订单
  static String get planFetchUrl => getUserApiUrl('/plan/fetch');
  static String get orderSaveUrl => getUserApiUrl('/order/save');
  static String get orderFetchUrl => getUserApiUrl('/order/fetch');
  static String get orderDetailUrl => getUserApiUrl('/order/detail');
  static String get orderCheckoutUrl => getUserApiUrl('/order/checkout');
  static String get orderCancelUrl => getUserApiUrl('/order/cancel');
  static String get couponCheckUrl => getUserApiUrl('/coupon/check');
  static String get paymentMethodUrl => getUserApiUrl('/order/getPaymentMethod');

  // 服务器节点
  static String get serverFetchUrl => getUserApiUrl('/server/fetch');

  // 工单系统
  static String get ticketSaveUrl => getUserApiUrl('/ticket/save');
  static String get ticketFetchUrl => getUserApiUrl('/ticket/fetch');
  static String get ticketReplyUrl => getUserApiUrl('/ticket/reply');
  static String get ticketCloseUrl => getUserApiUrl('/ticket/close');
  static String get ticketWithdrawUrl => getUserApiUrl('/ticket/withdraw');

  // 邀请系统
  static String get inviteFetchUrl => getUserApiUrl('/invite/fetch');
  static String get inviteSaveUrl => getUserApiUrl('/invite/save');
  static String get inviteDetailsUrl => getUserApiUrl('/invite/details');
  static String get inviteWithdrawUrl => getUserApiUrl('/invite/withdraw');
  static String get transferUrl => getUserApiUrl('/transfer');

  // 公告和知识库
  static String get noticeFetchUrl => getUserApiUrl('/notice/fetch');
  static String get knowledgeFetchUrl => getUserApiUrl('/knowledge/fetch');

  // 流量日志
  static String get trafficLogUrl => getUserApiUrl('/stat/getTrafficLog');

  // 钱包充值
  static String get walletFetchUrl => getUserApiUrl('/wallet/fetch');
  static String get rechargeCreateUrl => getUserApiUrl('/recharge/create');
  static String get rechargeBonusConfigUrl => getUserApiUrl('/recharge/bonus-config');

  // ==================== 配置常量 ====================

  /// 请求超时时间 (毫秒)
  static const int requestTimeout = 30000;

  /// 连接超时时间 (毫秒)
  static const int connectTimeout = 15000;

  /// Token 存储 key
  static const String tokenKey = 'xboard_auth_token';

  /// 用户数据存储 key
  static const String userDataKey = 'xboard_user_data';

  /// 订阅 URL 存储 key
  static const String subscribeUrlKey = 'xboard_subscribe_url';
}
