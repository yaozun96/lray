/// Xboard 邀请信息模型
class XboardInvite {
  final List<XboardInviteCode>? codes; // 邀请码列表
  final XboardInviteStat? stat; // 邀请统计
  final List<String>? withdrawMethods; // 提现方式

  XboardInvite({
    this.codes,
    this.stat,
    this.withdrawMethods,
  });

  factory XboardInvite.fromJson(Map<String, dynamic> json) {
    final methods = json['withdraw_methods'] ?? json['commission_withdraw_method'];
    
    return XboardInvite(
      codes: json['codes'] != null
          ? (json['codes'] as List)
              .map((e) => XboardInviteCode.fromJson(e))
              .toList()
          : null,
      stat: json['stat'] != null
          ? XboardInviteStat.fromList(json['stat'] as List)
          : null,
      withdrawMethods: methods != null
          ? (methods is String
              ? (methods as String).split(',').map((e) => e.trim()).toList()
              : (methods as List).map((e) => e.toString()).toList())
          : null,
    );
  }
}

/// Xboard 邀请码模型
class XboardInviteCode {
  final int id;
  final int userId;
  final String code;
  final int? createdAt;
  final int? updatedAt;

  XboardInviteCode({
    required this.id,
    required this.userId,
    required this.code,
    this.createdAt,
    this.updatedAt,
  });

  factory XboardInviteCode.fromJson(Map<String, dynamic> json) {
    // API sometimes returns list of objects or just objects.
    // The Vue code: maps (codeObj) => { code: codeObj.code || codeObj }
    // This implies it might be a simple string or an object.
    
    if (json['code'] != null) {
        return XboardInviteCode(
          id: json['id'] ?? 0,
          userId: json['user_id'] ?? 0,
          code: json['code'] ?? '',
          createdAt: json['created_at'],
          updatedAt: json['updated_at'],
        );
    } 
    // Fallback if the list item is just the code string (unlikely for Xboard but possible based on Vue logic)
    // Actually the Vue logic `code: codeObj.code || codeObj` suggests it handles both.
    // But since this factory takes a Map, we assume it's the object form.
    return XboardInviteCode(
          id: 0,
          userId: 0,
          code: '',
    );
  }
  
  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;
}

/// Xboard 邀请统计模型
class XboardInviteStat {
  final int registeredCount; // [0] 已注册人数
  final int totalCommissionBalance; // [1] 累计佣金 (分)
  final int pendingCommissionBalance; // [2] 确认中佣金 (分)
  final num commissionRate; // [3] 佣金比例 (%)
  final int availableBalance; // [4] 可用余额/提现余额? (分)

  XboardInviteStat({
    this.registeredCount = 0,
    this.totalCommissionBalance = 0,
    this.pendingCommissionBalance = 0,
    this.commissionRate = 0,
    this.availableBalance = 0,
  });

  factory XboardInviteStat.fromList(List<dynamic> list) {
    if (list.length < 5) return XboardInviteStat();
    return XboardInviteStat(
      registeredCount: int.tryParse(list[0].toString()) ?? 0,
      totalCommissionBalance: int.tryParse(list[1].toString()) ?? 0,
      pendingCommissionBalance: int.tryParse(list[2].toString()) ?? 0,
      commissionRate: num.tryParse(list[3].toString()) ?? 0,
      availableBalance: int.tryParse(list[4].toString()) ?? 0,
    );
  }

  /// 累计佣金 (元)
  double get totalCommissionYuan => totalCommissionBalance / 100;

  /// 确认中佣金 (元)
  double get pendingCommissionYuan => pendingCommissionBalance / 100;
  
  /// 可用余额 (元)
  double get availableBalanceYuan => availableBalance / 100;
}

/// Xboard 邀请详情模型
class XboardInviteDetail {
  final int id;
  final int orderId;
  final int userId;
  final int commissionStatus; // 0: 待确认, 1: 发放中, 2: 有效, 3: 无效
  final int commissionBalance; // 佣金金额 (分)
  final int orderAmount; // 订单金额 (分)
  final int getAmount; // 获得佣金 (分)
  final int createdAt;
  final int updatedAt;

  XboardInviteDetail({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.commissionStatus,
    required this.commissionBalance,
    required this.orderAmount,
    required this.getAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory XboardInviteDetail.fromJson(Map<String, dynamic> json) {
    return XboardInviteDetail(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      commissionStatus: json['commission_status'] ?? 0,
      commissionBalance: json['commission_balance'] ?? 0,
      orderAmount: json['order_amount'] ?? 0,
      getAmount: json['get_amount'] ?? json['commission_balance'] ?? 0,
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }

  /// 佣金金额 (元) - 优先使用 getAmount
  double get commissionAmountYuan => getAmount / 100;

  /// 订单金额 (元)
  double get orderAmountYuan => orderAmount / 100;


  /// 创建时间
  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  
  /// 状态描述
  String get statusText {
    switch (commissionStatus) {
      case 0: return '待确认';
      case 1: return '发放中';
      case 2: return '有效';
      case 3: return '无效';
      default: return '未知';
    }
  }
}
