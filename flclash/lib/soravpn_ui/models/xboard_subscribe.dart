/// Xboard 订阅信息模型
/// 对应 /api/v1/user/getSubscribe API 返回的数据
class XboardSubscribe {
  final String subscribeUrl; // 订阅链接
  final String? resetDay; // 重置日期
  final int? planId;
  final XboardSubscribePlan? plan; // 套餐信息

  // 用户流量和到期信息 (从 getSubscribe 返回)
  final int? transferEnable; // 总流量 (bytes)
  final int? u; // 上传流量 (bytes)
  final int? d; // 下载流量 (bytes)
  final int? expiredAt; // 到期时间 (秒级时间戳)

  XboardSubscribe({
    required this.subscribeUrl,
    this.resetDay,
    this.planId,
    this.plan,
    this.transferEnable,
    this.u,
    this.d,
    this.expiredAt,
  });

  factory XboardSubscribe.fromJson(Map<String, dynamic> json) {
    return XboardSubscribe(
      subscribeUrl: json['subscribe_url'] ?? '',
      resetDay: json['reset_day']?.toString(),
      planId: json['plan_id'],
      plan: json['plan'] != null
          ? XboardSubscribePlan.fromJson(json['plan'])
          : null,
      transferEnable: json['transfer_enable'],
      u: json['u'],
      d: json['d'],
      expiredAt: json['expired_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscribe_url': subscribeUrl,
      'reset_day': resetDay,
      'plan_id': planId,
      'plan': plan?.toJson(),
      'transfer_enable': transferEnable,
      'u': u,
      'd': d,
      'expired_at': expiredAt,
    };
  }

  /// 套餐名称
  String get planName => plan?.name ?? 'Unknown Plan';

  /// 已用流量 (bytes)
  int get usedTraffic => (u ?? 0) + (d ?? 0);

  /// 总流量 (bytes)
  int get totalTraffic => transferEnable ?? 0;

  /// 剩余天数
  int get remainingDays {
    if (expiredAt == null) return 0;
    if (expiredAt == 0) return 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = expiredAt! - now;
    if (diff <= 0) return 0;
    return (diff / 86400).floor(); // 86400 = 24*60*60 秒/天
  }

  /// 是否已过期
  bool get isExpired {
    if (expiredAt == null) return true;
    if (expiredAt == 0) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now > expiredAt!;
  }
}

/// 订阅中的套餐信息
class XboardSubscribePlan {
  final int id;
  final String name;
  final int? groupId;
  final int? transferEnable; // GB
  final int? speedLimit;
  final String? content;
  final int? resetDay; // 重置日 (1-31, null表示不重置)

  XboardSubscribePlan({
    required this.id,
    required this.name,
    this.groupId,
    this.transferEnable,
    this.speedLimit,
    this.content,
    this.resetDay,
  });

  factory XboardSubscribePlan.fromJson(Map<String, dynamic> json) {
    return XboardSubscribePlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      groupId: json['group_id'],
      transferEnable: json['transfer_enable'],
      speedLimit: json['speed_limit'],
      content: json['content'],
      resetDay: json['reset_traffic_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group_id': groupId,
      'transfer_enable': transferEnable,
      'speed_limit': speedLimit,
      'content': content,
      'reset_traffic_method': resetDay,
    };
  }

  /// 获取重置周期文本
  String get resetCycleText {
    if (resetDay == null) return '不重置';
    if (resetDay == 0) return '不重置';
    if (resetDay == 1) return '每月1日';
    return '每月$resetDay日';
  }
}

/// Xboard 用户统计信息模型
class XboardUserStat {
  final List<TrafficRecord>? trafficRecords;

  XboardUserStat({
    this.trafficRecords,
  });

  factory XboardUserStat.fromJson(dynamic json) {
    // API 可能返回数组或对象
    if (json is List) {
      return XboardUserStat(
        trafficRecords: json.map((e) => TrafficRecord.fromJson(e)).toList(),
      );
    }
    return XboardUserStat(trafficRecords: []);
  }
}

/// 流量记录
class TrafficRecord {
  final String recordAt; // 记录日期
  final int u; // 上传 (bytes)
  final int d; // 下载 (bytes)
  final int? serverId;
  final int? serverRate;

  TrafficRecord({
    required this.recordAt,
    required this.u,
    required this.d,
    this.serverId,
    this.serverRate,
  });

  factory TrafficRecord.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return TrafficRecord(
      recordAt: json['record_at']?.toString() ?? '',
      u: parseInt(json['u']),
      d: parseInt(json['d']),
      serverId: parseInt(json['server_id']),
      serverRate: parseInt(json['server_rate']),
    );
  }

  /// 总流量 (bytes)
  int get total => u + d;
}
