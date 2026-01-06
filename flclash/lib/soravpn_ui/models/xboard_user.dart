/// Xboard 用户模型
class XboardUser {
  final int id;
  final String email;
  final int? transferEnable; // 总流量 (bytes)
  final int? u; // 上传流量 (bytes)
  final int? d; // 下载流量 (bytes)
  final int balance; // 余额 (分)
  final int commissionBalance; // 佣金余额 (分)
  final int? planId;
  final int? discount;
  final int? commissionType; // 0: 按次, 1: 循环
  final int? commissionRate; // 佣金比例
  final DateTime? expiredAt; // 到期时间
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? uuid; // 用于订阅的 UUID
  final String? token; // 订阅 Token
  final bool isAdmin;
  final bool isStaff;
  final String? avatarUrl;
  final String? inviteCode; // 我的邀请码
  final int? inviteUserId; // 邀请我的人
  final String? telegramId;
  final String? remarks;
  final bool remindExpire; // 到期提醒
  final bool remindTraffic; // 流量提醒
  final bool banned; // 是否被封禁

  XboardUser({
    required this.id,
    required this.email,
    this.transferEnable,
    this.u,
    this.d,
    this.balance = 0,
    this.commissionBalance = 0,
    this.planId,
    this.discount,
    this.commissionType,
    this.commissionRate,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
    this.uuid,
    this.token,
    this.isAdmin = false,
    this.isStaff = false,
    this.avatarUrl,
    this.inviteCode,
    this.inviteUserId,
    this.telegramId,
    this.remarks,
    this.remindExpire = true,
    this.remindTraffic = true,
    this.banned = false,
  });

  factory XboardUser.fromJson(Map<String, dynamic> json) {
    return XboardUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      transferEnable: json['transfer_enable'],
      u: json['u'],
      d: json['d'],
      balance: json['balance'] ?? 0,
      commissionBalance: json['commission_balance'] ?? 0,
      planId: json['plan_id'],
      discount: json['discount'],
      commissionType: json['commission_type'],
      commissionRate: json['commission_rate'],
      expiredAt: json['expired_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expired_at'] * 1000)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] * 1000)
          : null,
      uuid: json['uuid'],
      token: json['token'],
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
      isStaff: json['is_staff'] == 1 || json['is_staff'] == true,
      avatarUrl: json['avatar_url'],
      inviteCode: json['invite_user_id']?.toString(),
      inviteUserId: json['invite_user_id'],
      telegramId: json['telegram_id']?.toString(),
      remarks: json['remarks'],
      remindExpire: json['remind_expire'] == 1 || json['remind_expire'] == true,
      remindTraffic: json['remind_traffic'] == 1 || json['remind_traffic'] == true,
      banned: json['banned'] == 1 || json['banned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'transfer_enable': transferEnable,
      'u': u,
      'd': d,
      'balance': balance,
      'commission_balance': commissionBalance,
      'plan_id': planId,
      'discount': discount,
      'commission_type': commissionType,
      'commission_rate': commissionRate,
      'expired_at': expiredAt?.millisecondsSinceEpoch,
      'uuid': uuid,
      'token': token,
      'is_admin': isAdmin,
      'is_staff': isStaff,
    };
  }

  /// 已用流量 (bytes)
  int get usedTraffic => (u ?? 0) + (d ?? 0);

  /// 总流量 (bytes)
  int get totalTraffic => transferEnable ?? 0;

  /// 剩余流量 (bytes)
  int get remainingTraffic => totalTraffic - usedTraffic;

  /// 流量使用百分比
  double get trafficUsagePercent {
    if (totalTraffic == 0) return 0;
    return (usedTraffic / totalTraffic * 100).clamp(0, 100);
  }

  /// 余额 (元)
  double get balanceYuan => balance / 100;

  /// 佣金余额 (元)
  double get commissionBalanceYuan => commissionBalance / 100;

  /// 是否已过期
  bool get isExpired {
    if (expiredAt == null) return true;
    return DateTime.now().isAfter(expiredAt!);
  }

  /// 剩余天数
  int get remainingDays {
    if (expiredAt == null) return 0;
    final diff = expiredAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// 格式化流量
  static String formatTraffic(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
  }
}
