import 'xboard_plan.dart';

/// Xboard 订单模型
class XboardOrder {
  final int? id;
  final int? inviteUserId;
  final int userId;
  final int planId;
  final String? couponId;
  final String? paymentId;
  final int type; // 1: 新购, 2: 续费, 3: 升级
  final String? period; // 周期
  final String tradeNo; // 订单号
  final String? callbackNo; // 回调单号
  final int totalAmount; // 总金额 (分)
  final int? discountAmount; // 折扣金额 (分)
  final int? surplusAmount; // 剩余金额 (分)
  final int? refundAmount; // 退款金额 (分)
  final int? balance; // 使用余额 (分)
  final String? surplusOrder; // 剩余订单
  final int status; // 0: 待支付, 1: 开通中, 2: 已取消, 3: 已完成, 4: 已折抵
  final int? commissionStatus; // 0: 待确认, 1: 发放中, 2: 已发放, 3: 作废
  final int? commissionBalance; // 佣金 (分)
  final int? paidAt; // 支付时间 (时间戳)
  final int? createdAt;
  final int? updatedAt;
  final XboardPlan? plan; // 关联套餐

  XboardOrder({
    this.id,
    this.inviteUserId,
    required this.userId,
    required this.planId,
    this.couponId,
    this.paymentId,
    required this.type,
    this.period,
    required this.tradeNo,
    this.callbackNo,
    required this.totalAmount,
    this.discountAmount,
    this.surplusAmount,
    this.refundAmount,
    this.balance,
    this.surplusOrder,
    required this.status,
    this.commissionStatus,
    this.commissionBalance,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
  });

  factory XboardOrder.fromJson(Map<String, dynamic> json) {
    return XboardOrder(
      id: json['id'],
      inviteUserId: json['invite_user_id'],
      userId: json['user_id'] ?? 0,
      planId: json['plan_id'] ?? 0,
      couponId: json['coupon_id']?.toString(),
      paymentId: json['payment_id']?.toString(),
      type: json['type'] ?? 1,
      period: json['period'],
      tradeNo: json['trade_no'] ?? '',
      callbackNo: json['callback_no'],
      totalAmount: json['total_amount'] ?? 0,
      discountAmount: json['discount_amount'],
      surplusAmount: json['surplus_amount'],
      refundAmount: json['refund_amount'],
      balance: json['balance_amount'], // Fix: map from balance_amount
      surplusOrder: json['surplus_order'],
      status: json['status'] ?? 0,
      commissionStatus: json['commission_status'],
      commissionBalance: json['commission_balance'],
      paidAt: json['paid_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      plan: json['plan'] != null ? XboardPlan.fromJson(json['plan']) : null,
    );
  }

  /// 订单类型名称
  String get typeName {
    switch (type) {
      case 1:
        return '新购';
      case 2:
        return '续费';
      case 3:
        return '升级';
      default:
        return '未知';
    }
  }

  /// 订单状态名称
  String get statusName {
    switch (status) {
      case 0:
        return '待支付';
      case 1:
        return '开通中';
      case 2:
        return '已取消';
      case 3:
        return '已完成';
      case 4:
        return '已折抵';
      default:
        return '未知';
    }
  }

  /// 是否待支付
  bool get isPending => status == 0;

  /// 是否已支付/已完成
  bool get isPaid => status == 1 || status == 3 || status == 4;

  /// 是否已完成
  bool get isCompleted => status == 3;

  /// 是否已取消
  bool get isCancelled => status == 2;

  /// 总金额 (元)
  double get totalAmountYuan => totalAmount / 100;

  /// 折扣金额 (元)
  double? get discountAmountYuan =>
      discountAmount != null ? discountAmount! / 100 : null;

  /// 实付金额 (元)
  /// 实付金额 (元)
  double get actualAmountYuan {
    // totalAmount from API is the Final Payable Amount (Net).
    // Previous logic (total - discount - balance) was double-counting deductions.
    return totalAmountYuan; 
  }

  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;

  /// 支付时间
  DateTime? get paidTime =>
      paidAt != null ? DateTime.fromMillisecondsSinceEpoch(paidAt! * 1000) : null;

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invite_user_id': inviteUserId,
      'user_id': userId,
      'plan_id': planId,
      'coupon_id': couponId,
      'payment_id': paymentId,
      'type': type,
      'period': period,
      'trade_no': tradeNo,
      'callback_no': callbackNo,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'surplus_amount': surplusAmount,
      'refund_amount': refundAmount,
      'balance': balance,
      'surplus_order': surplusOrder,
      'status': status,
      'commission_status': commissionStatus,
      'commission_balance': commissionBalance,
      'paid_at': paidAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// 优惠券模型
class XboardCoupon {
  final int? id;
  final String code;
  final String? name;
  final int type; // 1: 金额, 2: 比例
  final int value; // type=1时为分, type=2时为百分比
  final int? limitUse; // 限制使用次数
  final int? limitUseWithUser; // 每用户限制使用次数
  final int? limitPlanIds; // 限制套餐
  final int? limitPeriod; // 限制周期
  final DateTime? startedAt;
  final DateTime? endedAt;

  XboardCoupon({
    this.id,
    required this.code,
    this.name,
    required this.type,
    required this.value,
    this.limitUse,
    this.limitUseWithUser,
    this.limitPlanIds,
    this.limitPeriod,
    this.startedAt,
    this.endedAt,
  });

  factory XboardCoupon.fromJson(Map<String, dynamic> json) {
    return XboardCoupon(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'],
      type: json['type'] ?? 1,
      value: json['value'] ?? 0,
      limitUse: json['limit_use'],
      limitUseWithUser: json['limit_use_with_user'],
      limitPlanIds: json['limit_plan_ids'],
      limitPeriod: json['limit_period'],
      startedAt: json['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['started_at'] * 1000)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['ended_at'] * 1000)
          : null,
    );
  }

  /// 折扣描述
  String get discountDesc {
    if (type == 1) {
      return '减 ¥${(value / 100).toStringAsFixed(2)}';
    } else {
      return '$value% 折扣';
    }
  }

  /// 计算折扣金额
  int calculateDiscount(int originalPrice) {
    if (type == 1) {
      return value > originalPrice ? originalPrice : value;
    } else {
      return (originalPrice * value / 100).round();
    }
  }
}

/// 支付方式模型
class XboardPaymentMethod {
  final int id;
  final String name;
  final String? payment; // 支付类型标识
  final String? icon;
  final int? sort;
  final bool enable;

  XboardPaymentMethod({
    required this.id,
    required this.name,
    this.payment,
    this.icon,
    this.sort,
    this.enable = true,
  });

  factory XboardPaymentMethod.fromJson(Map<String, dynamic> json) {
    return XboardPaymentMethod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      payment: json['payment'],
      icon: json['icon'],
      sort: json['sort'],
      enable: json['enable'] == null || json['enable'] == 1 || json['enable'] == true,
    );
  }
}

/// 支付结果模型
class XboardPaymentResult {
  final String? type; // -1: 余额支付成功, 0: 跳转, 1: 二维码
  final String? data; // 支付URL或二维码内容

  XboardPaymentResult({
    this.type,
    this.data,
  });

  factory XboardPaymentResult.fromJson(Map<String, dynamic> json) {
    return XboardPaymentResult(
      type: json['type']?.toString(),
      data: json['data']?.toString(),
    );
  }

  /// 是否余额支付成功
  bool get isBalancePaySuccess => type == '-1';

  /// 是否需要跳转支付
  bool get isRedirectPay => type == '0';

  /// 是否二维码支付
  bool get isQrcodePay => type == '1';
}
