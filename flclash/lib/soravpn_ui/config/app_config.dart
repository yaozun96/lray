import 'xboard_config.dart';

/// 应用配置
/// 现已适配 Xboard 后端 API
class AppConfig {
  /// API 基础 URL - 从 XboardConfig 获取
  static String get apiBaseUrl => XboardConfig.apiBaseUrl;

  /// 网站基础 URL - 与 API 基础 URL 相同
  static String get websiteBaseUrl => XboardConfig.apiBaseUrl;

  /// 购买页面路径
  static const String purchasePath = '/#/plan';
  static const String orderPaymentPath = '/#/order';

  /// 用户中心路径
  static const String userCenterPath = '/#/dashboard';

  /// 设置 API 基础 URL
  static void setApiBaseUrl(String url) {
    XboardConfig.setApiBaseUrl(url);
  }

  /// 获取完整的购买页面 URL
  static String getPurchaseUrl() {
    return '$websiteBaseUrl$purchasePath';
  }

  /// 获取完整的用户中心 URL
  static String getUserCenterUrl() {
    return '$websiteBaseUrl$userCenterPath';
  }

  /// 获取网站端订单支付页面 URL
  static String getOrderPaymentUrl(String orderNo) {
    final encodedOrderNo = Uri.encodeComponent(orderNo);
    return '$websiteBaseUrl$orderPaymentPath/$encodedOrderNo';
  }

  /// 获取邀请注册链接
  static String getInviteUrl(String inviteCode) {
    if (inviteCode.isEmpty) return websiteBaseUrl;
    final code = Uri.encodeComponent(inviteCode);
    return '$websiteBaseUrl/#/register?code=$code';
  }

  /// 获取订阅链接页面
  static String getSubscribePageUrl() {
    return '$websiteBaseUrl/#/subscribe';
  }

  /// 获取工单页面
  static String getTicketPageUrl() {
    return '$websiteBaseUrl/#/ticket';
  }

  /// 获取充值页面
  static String getRechargePageUrl() {
    return '$websiteBaseUrl/#/wallet';
  }
}
