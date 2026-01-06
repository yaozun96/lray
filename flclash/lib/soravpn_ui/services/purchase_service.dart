/// Purchase Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 XboardOrderService
///
/// 新代码请直接使用:
/// - XboardOrderService

import '../models/plan.dart';
import '../models/payment_method.dart';
import '../models/order.dart';
import '../models/xboard_models.dart' hide PlanPeriod;
import 'xboard_order_service.dart';

/// 购买订阅服务
/// 现已迁移到 Xboard API
class PurchaseService {
  /// 获取套餐列表 - 返回兼容的 Plan 类型
  static Future<List<Plan>> getPlans() async {
    try {
      final xboardPlans = await XboardOrderService.getPlans();

      return xboardPlans.map((p) {
        // 使用月价作为基准价格
        final basePrice = p.monthPrice ?? 0;

        // 构建折扣列表
        final discounts = <PlanDiscount>[];

        // 月付 - 100% (无折扣)
        if (p.monthPrice != null && p.monthPrice! > 0) {
          discounts.add(PlanDiscount(quantity: 1, discount: 100));
        }

        // 季付 - 计算折扣
        if (p.quarterPrice != null && p.quarterPrice! > 0 && basePrice > 0) {
          final monthlyEquivalent = p.quarterPrice! / 3;
          final discountPercent = (monthlyEquivalent / basePrice * 100).round();
          discounts.add(PlanDiscount(quantity: 3, discount: discountPercent));
        }

        // 半年付
        if (p.halfYearPrice != null && p.halfYearPrice! > 0 && basePrice > 0) {
          final monthlyEquivalent = p.halfYearPrice! / 6;
          final discountPercent = (monthlyEquivalent / basePrice * 100).round();
          discounts.add(PlanDiscount(quantity: 6, discount: discountPercent));
        }

        // 年付
        if (p.yearPrice != null && p.yearPrice! > 0 && basePrice > 0) {
          final monthlyEquivalent = p.yearPrice! / 12;
          final discountPercent = (monthlyEquivalent / basePrice * 100).round();
          discounts.add(PlanDiscount(quantity: 12, discount: discountPercent));
        }

        // 两年付
        if (p.twoYearPrice != null && p.twoYearPrice! > 0 && basePrice > 0) {
          final monthlyEquivalent = p.twoYearPrice! / 24;
          final discountPercent = (monthlyEquivalent / basePrice * 100).round();
          discounts.add(PlanDiscount(quantity: 24, discount: discountPercent));
        }

        // 三年付
        if (p.threeYearPrice != null && p.threeYearPrice! > 0 && basePrice > 0) {
          final monthlyEquivalent = p.threeYearPrice! / 36;
          final discountPercent = (monthlyEquivalent / basePrice * 100).round();
          discounts.add(PlanDiscount(quantity: 36, discount: discountPercent));
        }

        // Map periods from XboardPlan to PlanPeriod
        final periods = p.availablePeriods.map((ap) => PlanPeriod(
          key: ap.key,
          name: ap.name,
          price: ap.price,
          months: ap.months,
          isOnetime: ap.isOnetime,
        )).toList();

        return Plan(
          id: p.id,
          name: p.name,
          unitPrice: basePrice,
          traffic: (p.transferEnable ?? 0) * 1024 * 1024 * 1024, // GB to bytes
          speedLimit: (p.speedLimit ?? 0) * 1024 * 1024 ~/ 8, // Mbps to bytes/s
          deviceLimit: p.capacityLimit ?? 0,
          unitTime: 'Month',
          featured: false,
          description: p.content,
          discounts: discounts,
          sort: p.sort ?? 999,
          resetPrice: p.resetPrice,
          periods: periods,
        );
      }).toList();
    } catch (e) {
      throw Exception('Get plans error: $e');
    }
  }

  /// 创建订单 - 直接调用 XboardOrderService
  /// 注意：兼容旧接口，内部会自动获取订单详情
  static Future<XboardOrder> createOrder({
    required int planId,
    required String period,
    String? couponCode,
  }) async {
    final tradeNo = await XboardOrderService.createOrder(
      planId: planId,
      period: period,
      couponCode: couponCode,
    );
    return await XboardOrderService.getOrderDetail(tradeNo);
  }

  /// 获取支付方式列表 - 返回兼容的 PaymentMethod 类型
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final xboardMethods = await XboardOrderService.getPaymentMethods();

      return xboardMethods.map((m) => PaymentMethod(
        id: m.id,
        name: m.name,
        platform: m.payment ?? '',
        icon: m.icon ?? '',
      )).toList();
    } catch (e) {
      throw Exception('Get payment methods error: $e');
    }
  }

  /// 获取订单预览 - Xboard 可能不支持预览，直接返回计算值
  static Future<OrderPreview> getOrderPreview({
    required int subscribeId,
    required int payment,
    required int quantity, // Legacy: used for calculation if needed, but really we prefer periodKey
    String? coupon,
    String? identifier,
    String? period, // ADDED: period key
  }) async {
    try {
      // Xboard 没有专门的预览接口，我们直接构造一个预览对象
      final plans = await getPlans();
      final plan = plans.firstWhere(
        (p) => p.id == subscribeId,
        orElse: () => throw Exception('Plan not found'),
      );

      // Find price by period key if available, else fallback to quantity
      int price = 0;
      if (period != null) {
        final pp = plan.periods.firstWhere((p) => p.key == period, orElse: () => throw Exception('Period not found'));
        price = pp.price;
      } else {
        price = plan.calculatePrice(quantity);
      }
      
      int discount = 0;

      // 如果有优惠券，验证它
      if (coupon != null && coupon.isNotEmpty) {
        try {
          final couponInfo = await XboardOrderService.checkCoupon(
            code: coupon,
            planId: subscribeId,
          );
          discount = couponInfo.calculateDiscount(price);
        } catch (e) {
          // 优惠券无效，忽略
          print('[PurchaseService] Invalid coupon: $e');
        }
      }

      return OrderPreview(
        price: price,
        productDiscount: 0,
        couponDiscount: discount,
        feeAmount: 0,
        giftAmount: 0,
        totalAmount: price - discount,
      );
    } catch (e) {
      throw Exception('Get order preview error: $e');
    }
  }

  /// 创建订单（购买）- 返回兼容的 Order 类型
  static Future<Order> purchase({
    required int subscribeId,
    required int payment,
    required int quantity, // Legacy, kept for compatibility but ignored if period is present
    String? coupon,
    String? identifier,
    String? password,
    String? period, // ADDED: preferred way to specify duration
  }) async {
    try {
      // Prioritize explicit period, fallback to calculating from quantity
      String finalPeriod = period ?? '';
      
      if (finalPeriod.isEmpty) {
        switch (quantity) {
          case 1:
            finalPeriod = 'month_price';
            break;
          case 3:
            finalPeriod = 'quarter_price';
            break;
          case 6:
            finalPeriod = 'half_year_price';
            break;
          case 12:
            finalPeriod = 'year_price';
            break;
          case 24:
            finalPeriod = 'two_year_price';
            break;
          case 36:
            finalPeriod = 'three_year_price';
            break;
          default:
            finalPeriod = 'month_price';
        }
      }

      final tradeNo = await XboardOrderService.createOrder(
        planId: subscribeId,
        period: finalPeriod,
        couponCode: coupon,
      );
      
      // Fetch full order details
      final xboardOrder = await XboardOrderService.getOrderDetail(tradeNo);

      return Order(
        orderNo: xboardOrder.tradeNo,
        status: _convertStatus(xboardOrder.status),
        amount: xboardOrder.totalAmount,
        createdAt: xboardOrder.createdAt ?? 0,
      );
    } catch (e) {
      throw Exception('Purchase error: $e');
    }
  }

  /// 续费订阅 - 使用新购流程
  static Future<Order> renewSubscription({
    required int userSubscribeId,
    required int payment,
    required int quantity, // Legacy
    String? coupon,
    String? period, // ADDED
  }) async {
    // Xboard 续费使用同样的订单创建流程
    return await purchase(
      subscribeId: userSubscribeId,
      payment: payment,
      quantity: quantity,
      coupon: coupon,
      period: period,
    );
  }

  /// 查询订单状态 - 返回兼容的 Order 类型
  static Future<Order> getOrderStatus({
    required String orderNo,
    String? identifier,
  }) async {
    try {
      final xboardOrder = await XboardOrderService.getOrderDetail(orderNo);

      return Order(
        orderNo: xboardOrder.tradeNo,
        status: _convertStatus(xboardOrder.status),
        amount: xboardOrder.totalAmount,
        createdAt: xboardOrder.createdAt ?? 0,
      );
    } catch (e) {
      throw Exception('Get order status error: $e');
    }
  }

  /// 获取支付URL或二维码
  static Future<Map<String, dynamic>> getPaymentCheckout({
    required String orderNo,
    int? methodId,
  }) async {
    try {
      int paymentMethodId = methodId ?? 0;

      // 如果没有指定支付方式，获取第一个可用的
      if (paymentMethodId == 0) {
        final methods = await XboardOrderService.getPaymentMethods();
        if (methods.isEmpty) {
          throw Exception('No payment methods available');
        }
        paymentMethodId = methods.first.id;
      }

      final result = await XboardOrderService.checkoutOrder(
        tradeNo: orderNo,
        methodId: paymentMethodId,
      );

      return {
        'type': result.type,
        'data': result.data,
        'payment_url': result.isRedirectPay ? result.data : null,
        'qrcode': result.isQrcodePay ? result.data : null,
      };
    } catch (e) {
      throw Exception('Get payment checkout error: $e');
    }
  }

  /// 将 Xboard 订单状态转换为旧的 OrderStatus
  static OrderStatus _convertStatus(int xboardStatus) {
    // Xboard: 0=待支付, 1=开通中, 2=已取消, 3=已完成, 4=已折抵
    switch (xboardStatus) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.processing;
      case 2:
        return OrderStatus.cancelled;
      case 3:
        return OrderStatus.paid;
      case 4:
        return OrderStatus.paid;
      default:
        return OrderStatus.pending;
    }
  }
}
