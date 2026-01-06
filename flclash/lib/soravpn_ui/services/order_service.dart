/// Order Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 XboardOrderService
///
/// 新代码请直接使用:
/// - XboardOrderService

import '../models/xboard_models.dart';
import 'xboard_order_service.dart';
import 'xboard_auth_service.dart';

/// Order service for handling recharge and order operations
/// 现已迁移到 Xboard API
class OrderService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await XboardAuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token ?? '',
    };
  }

  /// Get payment methods for a specific scene
  static Future<List<Map<String, dynamic>>> getPaymentMethods({String scene = 'recharge'}) async {
    try {
      final methods = await XboardOrderService.getPaymentMethods();

      // 过滤余额支付
      return methods
          .where((m) => m.payment?.toLowerCase() != 'balance')
          .map((m) => {
            'id': m.id,
            'name': m.name,
            'payment': m.payment ?? '',
            'icon': m.icon ?? '',
          })
          .toList();
    } catch (e) {
      print('Failed to get payment methods: $e');
      return [];
    }
  }

  /// Create a recharge order - Xboard 使用不同的流程
  /// amount: amount in yuan (will be converted to cents)
  /// paymentId: selected payment method ID
  @Deprecated('Xboard may use different recharge flow')
  static Future<String?> createRechargeOrder({
    required double amount,
    required int paymentId,
  }) async {
    // Xboard 可能不支持直接充值，需要通过网页进行
    throw Exception('Direct recharge is not supported. Please use web interface.');
  }

  /// Get order detail by order number
  static Future<Map<String, dynamic>?> getOrderDetail(String orderNo) async {
    try {
      final order = await XboardOrderService.getOrderDetail(orderNo);
      return {
        'id': order.id,
        'trade_no': order.tradeNo,
        'user_id': order.userId,
        'plan_id': order.planId,
        'type': order.type,
        'total_amount': order.totalAmount,
        'discount_amount': order.discountAmount,
        'status': order.status,
        'created_at': order.createdAt,
        'paid_at': order.paidAt,
      };
    } catch (e) {
      print('Failed to get order detail: $e');
      return null;
    }
  }

  /// Get payment checkout info (payment URL, QR code, etc.)
  static Future<Map<String, dynamic>> getPaymentCheckout(String orderNo) async {
    try {
      final methods = await XboardOrderService.getPaymentMethods();
      if (methods.isEmpty) {
        return {'error': 'No payment methods available'};
      }

      final result = await XboardOrderService.checkoutOrder(
        tradeNo: orderNo,
        methodId: methods.first.id,
      );

      return {
        'type': result.type,
        'data': result.data,
        'payment_url': result.isRedirectPay ? result.data : null,
        'qrcode': result.isQrcodePay ? result.data : null,
      };
    } catch (e) {
      print('Failed to get payment checkout: $e');
      return {'error': e.toString()};
    }
  }

  /// 获取订单列表
  static Future<List<XboardOrder>> getOrders() async {
    return await XboardOrderService.getOrders();
  }

  /// 取消订单
  static Future<String> cancelOrder(String tradeNo) async {
    return await XboardOrderService.cancelOrder(tradeNo);
  }

  /// 检查订单状态
  static Future<bool> checkOrderStatus(String tradeNo) async {
    return await XboardOrderService.checkOrderStatus(tradeNo);
  }
}
