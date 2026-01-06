import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xboard_models.dart';
import 'xboard_services.dart';

/// Xboard API 兼容层
/// 提供与旧 PLray API 兼容的接口，方便逐步迁移
///
/// 使用方法:
/// 1. 将旧的 AuthService 替换为 XboardAuthAdapter
/// 2. 将旧的 SubscribeService 替换为 XboardSubscribeAdapter
/// 等等...
class XboardAuthAdapter {
  static const String _tokenKey = XboardConfig.tokenKey;
  static const String _userKey = XboardConfig.userDataKey;

  /// 登录 - 兼容旧的 AuthService.login
  static Future<bool> login(String email, String password) async {
    return await XboardAuthService.login(email: email, password: password);
  }

  /// 注册 - 兼容旧的 AuthService.register
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

  /// 发送验证码 - 兼容旧的 AuthService.sendEmailCode
  static Future<bool> sendEmailCode(String email, {int type = 1}) async {
    return await XboardAuthService.sendEmailVerify(
      email: email,
      isForgetPassword: type == 2,
    );
  }

  /// 重置密码 - 兼容旧的 AuthService.resetPassword
  static Future<bool> resetPassword(String email, String password, String code) async {
    return await XboardAuthService.resetPassword(
      email: email,
      password: password,
      emailCode: code,
    );
  }

  /// 登出 - 兼容旧的 AuthService.logout
  static Future<void> logout() async {
    await XboardAuthService.logout();
  }

  /// 检查是否已登录 - 兼容旧的 AuthService.isLoggedIn
  static Future<bool> isLoggedIn() async {
    return await XboardAuthService.isLoggedIn();
  }

  /// 获取 Token - 兼容旧的 AuthService.getToken
  static Future<String?> getToken() async {
    return await XboardAuthService.getToken();
  }

  /// 获取用户数据 - 兼容旧的 AuthService.getUserData
  static Future<Map<String, dynamic>?> getUserData() async {
    return await XboardAuthService.getStoredUserData();
  }

  /// 获取用户信息 - 兼容旧的 AuthService.getUserInfo
  static Future<Map<String, dynamic>> getUserInfo() async {
    final user = await XboardUserService.getUserInfo();
    return user.toJson();
  }
}

/// 订阅服务兼容层
class XboardSubscribeAdapter {
  /// 获取订阅列表 - 返回兼容格式
  static Future<List<Map<String, dynamic>>> getSubscriptionList() async {
    try {
      final user = await XboardUserService.getUserInfo();
      final subscribe = await XboardUserService.getSubscribe();

      // 构造兼容的订阅数据格式
      return [
        {
          'id': 1,
          'user_id': user.id,
          'subscribe_id': user.planId ?? 0,
          'upload': user.u ?? 0,
          'download': user.d ?? 0,
          'traffic': user.transferEnable ?? 0,
          'start_time': user.createdAt?.millisecondsSinceEpoch ?? 0,
          'expire_time': user.expiredAt?.millisecondsSinceEpoch ?? 0,
          'reset_time': 0,
          'token': user.token ?? '',
          'subscribe_url': subscribe.subscribeUrl,
        }
      ];
    } catch (e) {
      print('[XboardSubscribeAdapter] Error getting subscription list: $e');
      return [];
    }
  }

  /// 获取订阅 URL
  static Future<String?> getSubscribeUrl() async {
    return await XboardServerService.getSubscribeUrl();
  }

  /// 获取 Clash 配置
  static Future<String?> getClashConfig() async {
    final url = await getSubscribeUrl();
    if (url == null) return null;
    return await XboardServerService.getClashConfig(url);
  }

  /// 获取 Sing-box 配置
  static Future<Map<String, dynamic>?> getSingBoxConfig() async {
    final url = await getSubscribeUrl();
    if (url == null) return null;
    return await XboardServerService.getSingBoxConfig(url);
  }
}

/// 用户服务兼容层
class XboardUserAdapter {
  /// 修改密码 - 兼容旧的 UserService.updatePassword
  static Future<void> updatePassword(String password) async {
    // 注意: Xboard 需要旧密码，这里无法完全兼容
    // 如果 UI 需要修改，请使用 XboardUserService.changePassword
    throw UnimplementedError('Please use XboardUserService.changePassword with old password');
  }

  /// 获取站点配置
  static Future<Map<String, dynamic>> getSiteConfig() async {
    final config = await XboardAuthService.getGuestConfig();
    if (config == null) return {};
    return {
      'app_name': config.appName,
      'app_description': config.appDescription,
      'is_email_verify': config.isEmailVerify,
      'is_invite_force': config.isInviteForce,
    };
  }
}

/// 购买服务兼容层
class XboardPurchaseAdapter {
  /// 获取套餐列表 - 兼容旧的 PurchaseService.getPlans
  static Future<List<Map<String, dynamic>>> getPlans() async {
    final plans = await XboardOrderService.getPlans();
    return plans.map((plan) => {
      'id': plan.id,
      'name': plan.name,
      'description': plan.content ?? '',
      'traffic': plan.transferEnable ?? 0,
      'speed_limit': plan.speedLimit ?? 0,
      'month_price': plan.monthPrice ?? 0,
      'quarter_price': plan.quarterPrice ?? 0,
      'half_year_price': plan.halfYearPrice ?? 0,
      'year_price': plan.yearPrice ?? 0,
      'two_year_price': plan.twoYearPrice ?? 0,
      'three_year_price': plan.threeYearPrice ?? 0,
      'onetime_price': plan.onetimePrice ?? 0,
    }).toList();
  }

  /// 获取支付方式 - 兼容旧的 PurchaseService.getPaymentMethods
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final methods = await XboardOrderService.getPaymentMethods();
    return methods.map((method) => {
      'id': method.id,
      'name': method.name,
      'payment': method.payment ?? '',
      'icon': method.icon ?? '',
    }).toList();
  }

  /// 创建订单 - 兼容旧的 PurchaseService.purchase
  static Future<Map<String, dynamic>> purchase({
    required int subscribeId,
    required String period,
    String? coupon,
  }) async {
    final order = await XboardOrderService.createOrder(
      planId: subscribeId,
      period: period,
      couponCode: coupon,
    );

    return {
      'order_no': order.tradeNo,
      'trade_no': order.tradeNo,
      'total_amount': order.totalAmount,
      'status': order.status,
    };
  }

  /// 获取订单状态
  static Future<Map<String, dynamic>> getOrderStatus(String orderNo) async {
    final order = await XboardOrderService.getOrderDetail(orderNo);
    return {
      'order_no': order.tradeNo,
      'status': order.status,
      'total_amount': order.totalAmount,
    };
  }
}

/// 工单服务兼容层
class XboardTicketAdapter {
  /// 获取工单列表 - 兼容旧的 TicketService.getTickets
  static Future<List<Map<String, dynamic>>> getTickets() async {
    final tickets = await XboardTicketService.getTickets();
    return tickets.map((ticket) => {
      'id': ticket.id,
      'title': ticket.subject,
      'status': ticket.status,
      'level': ticket.level,
      'created_at': ticket.createdAt ?? 0,
      'updated_at': ticket.updatedAt ?? 0,
    }).toList();
  }

  /// 创建工单 - 兼容旧的 TicketService.createTicket
  static Future<void> createTicket(String title, String content, int priority) async {
    await XboardTicketService.createTicket(
      subject: title,
      message: content,
      level: priority,
    );
  }

  /// 回复工单 - 兼容旧的 TicketService.replyTicket
  static Future<void> replyTicket(int ticketId, String content, {int type = 1}) async {
    await XboardTicketService.replyTicket(
      ticketId: ticketId,
      message: content,
    );
  }

  /// 关闭工单 - 兼容旧的 TicketService.closeTicket
  static Future<void> closeTicket(int ticketId) async {
    await XboardTicketService.closeTicket(ticketId);
  }
}
