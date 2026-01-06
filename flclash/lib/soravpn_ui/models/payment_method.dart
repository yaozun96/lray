/// 支付方式
class PaymentMethod {
  final int id; // 支付方式ID（-1 = 账户余额）
  final String name; // 支付方式名称
  final String? platform; // 支付平台（alipay, wechat等）
  final String? icon; // 图标路径
  final String? type; // 支付类型（url = 跳转链接，qr = 二维码）
  final bool disabled; // 是否禁用
  final String? disabledReason; // 禁用原因

  PaymentMethod({
    required this.id,
    required this.name,
    this.platform,
    this.icon,
    this.type,
    this.disabled = false,
    this.disabledReason,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      platform: json['platform'] as String?,
      icon: json['icon'] as String?,
      type: json['type'] as String?,
      disabled: json['disabled'] as bool? ?? false,
      disabledReason: json['disabledReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'icon': icon,
      'type': type,
      'disabled': disabled,
      'disabledReason': disabledReason,
    };
  }

  /// 是否为余额支付
  bool get isBalance => id == -1;

  /// 是否为URL类型支付（需要跳转）
  bool get isUrlType => type == 'url';

  /// 是否为二维码支付
  bool get isQrType => type == 'qr';
}
