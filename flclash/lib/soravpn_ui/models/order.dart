/// 订单预览
class OrderPreview {
  final int price; // 原价（分）
  final int productDiscount; // 商品折扣（分）
  final int couponDiscount; // 优惠码折扣（分）
  final int feeAmount; // 支付手续费（分）
  final int giftAmount; // 赠金抵扣（分）
  final int totalAmount; // 最终价格（分）

  OrderPreview({
    required this.price,
    required this.productDiscount,
    required this.couponDiscount,
    required this.feeAmount,
    required this.giftAmount,
    required this.totalAmount,
  });

  factory OrderPreview.fromJson(Map<String, dynamic> json) {
    return OrderPreview(
      price: json['price'] as int? ?? 0,
      productDiscount: (json['product_discount'] ?? json['discount']) as int? ?? 0,
      couponDiscount: json['coupon_discount'] as int? ?? 0,
      feeAmount: json['fee_amount'] as int? ?? 0,
      giftAmount: json['gift_amount'] as int? ?? 0,
      totalAmount: (json['total_amount'] ?? json['amount']) as int? ?? 0,
    );
  }

  /// 转换为元
  double get priceInYuan => price / 100.0;
  double get productDiscountInYuan => productDiscount / 100.0;
  double get couponDiscountInYuan => couponDiscount / 100.0;
  double get feeAmountInYuan => feeAmount / 100.0;
  double get giftAmountInYuan => giftAmount / 100.0;
  double get totalAmountInYuan => totalAmount / 100.0;
}

/// 订单状态
enum OrderStatus {
  pending(1, '待支付'),
  paid(2, '已支付'),
  closed(3, '已关闭'),
  cancelled(4, '已取消'),
  processing(5, '处理中');

  final int value;
  final String label;

  const OrderStatus(this.value, this.label);

  static OrderStatus fromValue(int value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// 订单
class Order {
  final String orderNo; // 订单号
  final OrderStatus status; // 订单状态
  final int amount; // 订单金额（分）
  final int createdAt; // 创建时间（时间戳，毫秒）
  final String? paymentUrl; // 支付链接（URL类型支付）
  final String? paymentQr; // 支付二维码数据（QR类型支付）
  final String? token; // 登录token（新用户注册后返回）
  final Map<String, dynamic>? subscribe; // 订阅信息
  final Map<String, dynamic>? payment; // 支付方式信息

  Order({
    required this.orderNo,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.paymentUrl,
    this.paymentQr,
    this.token,
    this.subscribe,
    this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNo: json['order_no'] as String,
      status: OrderStatus.fromValue(json['status'] as int? ?? 1),
      amount: json['amount'] as int? ?? 0,
      createdAt: json['created_at'] as int? ?? 0,
      paymentUrl: json['payment_url'] as String?,
      paymentQr: json['payment_qr'] as String?,
      token: json['token'] as String?,
      subscribe: json['subscribe'] as Map<String, dynamic>?,
      payment: json['payment'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_no': orderNo,
      'status': status.value,
      'amount': amount,
      'created_at': createdAt,
      'payment_url': paymentUrl,
      'payment_qr': paymentQr,
      'token': token,
      'subscribe': subscribe,
      'payment': payment,
    };
  }

  /// 转换为元
  double get amountInYuan => amount / 100.0;

  /// 是否已支付
  bool get isPaid => status == OrderStatus.paid || status == OrderStatus.processing;

  /// 是否待支付
  bool get isPending => status == OrderStatus.pending;

  /// 是否已关闭/取消
  bool get isClosed => status == OrderStatus.closed || status == OrderStatus.cancelled;

  /// 格式化创建时间
  DateTime get createdAtDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);
}
