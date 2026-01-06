import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';
import 'package:flutter/foundation.dart';

/// Xboard 订单服务
/// 处理套餐购买、订单管理、支付等操作
class XboardOrderService {
  /// 全局订单更新通知 (用于刷新待支付提醒等)
  static final ValueNotifier<int> orderUpdateNotifier = ValueNotifier(0);

  /// 获取套餐列表
  static Future<List<XboardPlan>> getPlans() async {
    final response = await xboardClient.get(
      XboardConfig.planFetchUrl,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get plans');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => XboardPlan.fromJson(e as Map<String, dynamic>))
        .where((plan) => plan.show) // 只返回显示的套餐
        .toList();
  }

  /// 创建订单
  /// [planId] 套餐 ID
  /// [period] 周期 (month_price, quarter_price, half_year_price, year_price, two_year_price, three_year_price, onetime_price)
  /// [couponCode] 优惠券代码 (可选)
  static Future<String> createOrder({
    required int planId,
    required String period,
    String? couponCode,
  }) async {
    final data = <String, dynamic>{
      'plan_id': planId,
      'period': period,
    };

    if (couponCode != null && couponCode.isNotEmpty) {
      data['coupon_code'] = couponCode;
    }

    final response = await xboardClient.post(
      XboardConfig.orderSaveUrl,
      data: data,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to create order');
    }

    if (response.data == null) {
      throw Exception('No order data received');
    }

    if (response.data is String) {
      orderUpdateNotifier.value++; // Notify listeners
      return response.data as String;
    } else if (response.data is Map) {
      final map = response.data as Map<String, dynamic>;
      if (map.containsKey('trade_no')) {
        orderUpdateNotifier.value++; // Notify listeners
        return map['trade_no'].toString();
      }
    }

    orderUpdateNotifier.value++; // Notify listeners
    return response.data.toString();
  }

  /// 获取订单列表
  static Future<List<XboardOrder>> getOrders({int page = 1, int pageSize = 10}) async {
    final response = await xboardClient.get(
      '${XboardConfig.orderFetchUrl}?page=$page&limit=$pageSize',
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get orders');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => XboardOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取订单详情
  static Future<XboardOrder> getOrderDetail(String tradeNo) async {
    final response = await xboardClient.get(
      XboardConfig.orderDetailUrl,
      params: {'trade_no': tradeNo},
      fromJson: (data) => XboardOrder.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get order detail');
    }

    if (response.data == null) {
      throw Exception('No order data received');
    }

    return response.data!;
  }

  /// 验证优惠券
  static Future<XboardCoupon> checkCoupon({
    required String code,
    required int planId,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.couponCheckUrl,
      data: {
        'code': code,
        'plan_id': planId,
      },
      fromJson: (data) => XboardCoupon.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Invalid coupon');
    }

    if (response.data == null) {
      throw Exception('No coupon data received');
    }

    return response.data!;
  }

  /// 获取支付方式列表
  static Future<List<XboardPaymentMethod>> getPaymentMethods() async {
    print('[XboardOrderService] Fetching payment methods...');
    final response = await xboardClient.get(
      XboardConfig.paymentMethodUrl,
    );

    if (!response.success) {
      print('[XboardOrderService] Failed to get payment methods: ${response.message}');
      throw Exception(response.message ?? 'Failed to get payment methods');
    }

    if (response.data == null || response.data is! List) {
      print('[XboardOrderService] Payment methods data is null or not a list: ${response.data}');
      return [];
    }

    final list = response.data as List;
    print('[XboardOrderService] Raw payment methods count: ${list.length}');
    print('[XboardOrderService] Raw data: $list');

    final methods = list
        .map((e) => XboardPaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
    
    print('[XboardOrderService] Parsed methods count: ${methods.length}');
    methods.forEach((m) => print('  - ${m.name} (id: ${m.id}, enable: ${m.enable}, payment: ${m.payment})'));

    // Fix: Do not filter by enable, let the UI handle it or show all available options
    // final enabledMethods = methods.where((method) => method.enable).toList();
    // print('[XboardOrderService] Enabled methods count: ${enabledMethods.length}');

    return methods;
  }

  /// 结算订单 (获取支付链接)
  /// [tradeNo] 订单号
  /// [methodId] 支付方式 ID
  static Future<XboardPaymentResult> checkoutOrder({
    required String tradeNo,
    required int methodId,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.orderCheckoutUrl,
      data: {
        'trade_no': tradeNo,
        'method': methodId,
      },
      fromJson: (data) => XboardPaymentResult.fromJson(data as Map<String, dynamic>),
      useRawData: true,
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to checkout order');
    }

    if (response.data == null) {
      throw Exception('No payment data received');
    }

    return response.data!;
  }

  /// 取消订单
  static Future<String> cancelOrder(String tradeNo) async {
    final response = await xboardClient.post(
      XboardConfig.orderCancelUrl,
      data: {'trade_no': tradeNo},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to cancel order');
    }

    orderUpdateNotifier.value++;
    return response.message ?? '操作成功'; // Return API message
  }

  /// 检查订单状态 (用于轮询)
  static Future<bool> checkOrderStatus(String tradeNo) async {
    try {
      final order = await getOrderDetail(tradeNo);
      return order.isCompleted;
    } catch (e) {
      return false;
    }
  }

  /// 获取钱包充值方式
  static Future<List<Map<String, dynamic>>> getWalletPaymentMethods() async {
    final response = await xboardClient.get(
      XboardConfig.walletFetchUrl,
    );

    if (!response.success) {
      return [];
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// 创建充值订单
  /// [amount] 金额 (单位：分)
  static Future<String> createRechargeOrder(int amount) async {
    final response = await xboardClient.post(
      XboardConfig.rechargeCreateUrl,
      data: {'amount': amount},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to create recharge order');
    }

    if (response.data == null) {
      throw Exception('No recharge order data received');
    }

    if (response.data is Map && response.data['trade_no'] != null) {
      return response.data['trade_no'].toString();
    }

    return response.data.toString();
  }

  /// 获取充值奖励配置
  static Future<List<Map<String, dynamic>>> getRechargeBonusConfig() async {
    final response = await xboardClient.get(
      XboardConfig.rechargeBonusConfigUrl,
    );

    if (!response.success) {
      return [];
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
