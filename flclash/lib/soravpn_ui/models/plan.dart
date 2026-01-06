import 'dart:convert';

/// 套餐折扣
class PlanDiscount {
  final int quantity; // 购买数量（月数）
  final int discount; // 折扣百分比（如 85 = 打85折）

  PlanDiscount({
    required this.quantity,
    required this.discount,
  });

  factory PlanDiscount.fromJson(Map<String, dynamic> json) {
    return PlanDiscount(
      quantity: json['quantity'] as int,
      discount: json['discount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'discount': discount,
    };
  }
}

/// 套餐功能特性
class PlanFeature {
  final String label;
  final String type;
  final List<dynamic>? details;

  PlanFeature({
    required this.label,
    required this.type,
    this.details,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      label: json['label'] as String,
      type: json['type'] as String? ?? 'success',
      details: json['details'] as List<dynamic>?,
    );
  }

  String getDescription() {
    if (details != null && details!.isNotEmpty) {
      final detail = details![0] as Map<String, dynamic>;
      return detail['description'] as String? ?? label;
    }
    return label;
  }
}

/// 购买套餐
class Plan {
  final int id; // 套餐ID
  final String name; // 套餐名称
  final int unitPrice; // 单位价格（分）
  final int traffic; // 每月流量（字节）
  final int speedLimit; // 连接速度限制（字节/秒，0表示无限制）
  final int deviceLimit; // 同时连接设备数
  final String unitTime; // 计费周期（Month, Year等）
  final bool featured; // 是否为推荐套餐
  final String? description; // 套餐描述（JSON格式）
  final List<PlanDiscount> discounts; // 折扣列表
  final int sort; // 排序优先级（越小越靠前）
  final int? resetPrice; // 重置包价格（分）
  final List<PlanPeriod> periods; // 可用周期列表

  Plan({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.traffic,
    required this.speedLimit,
    required this.deviceLimit,
    required this.unitTime,
    required this.featured,
    this.description,
    required this.discounts,
    required this.sort,
    this.resetPrice,
    this.periods = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as int,
      name: json['name'] as String,
      unitPrice: json['unit_price'] as int,
      traffic: json['traffic'] as int,
      speedLimit: json['speed_limit'] as int? ?? 0,
      deviceLimit: json['device_limit'] as int,
      unitTime: json['unit_time'] as String,
      featured: json['featured'] as bool? ?? false,
      description: json['description'] as String?,
      discounts: (json['discount'] as List<dynamic>?)
              ?.map((e) => PlanDiscount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sort: json['sort'] as int? ?? 999, // 默认值为999，排在最后
      resetPrice: json['reset_price'] as int?,
      // periods deserialization is not strictly needed from JSON if we construct it manually in service, 
      // but good to have if we persist it. For now, empty list default is fine as we populate in Service.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_price': unitPrice,
      'traffic': traffic,
      'speed_limit': speedLimit,
      'device_limit': deviceLimit,
      'unit_time': unitTime,
      'featured': featured,
      'description': description,
      'discount': discounts.map((d) => d.toJson()).toList(),
      'sort': sort,
      'reset_price': resetPrice,
      // 'periods': periods.map((p) => p.toJson()).toList(), // Skip for now to minimize changes
    };
  }

  /// 获取套餐功能列表
  List<PlanFeature> getFeatures() {
    if (description == null || description!.isEmpty) {
      return [];
    }
    try {
      final parsed = jsonDecode(description!);
      if (parsed is Map<String, dynamic> && parsed['features'] is List) {
        final featuresList = parsed['features'] as List<dynamic>;
        return featuresList
            .map((f) => PlanFeature.fromJson(f as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // 解析失败，返回空列表
      print('[Plan] Failed to parse features: $e');
    }
    return [];
  }

  /// 格式化流量（字节 → 易读单位）
  String formatTraffic() {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = traffic.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  /// 格式化速度限制
  String formatSpeedLimit() {
    if (speedLimit == 0) {
      return '无限制';
    }

    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    double speed = speedLimit.toDouble();
    int unitIndex = 0;

    while (speed >= 1024 && unitIndex < units.length - 1) {
      speed /= 1024;
      unitIndex++;
    }

    return '${speed.toStringAsFixed(speed >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  /// 格式化设备限制
  String formatDeviceLimit() {
    if (deviceLimit <= 0) {
      return '无限制';
    }
    return '$deviceLimit 台设备';
  }

  /// 获取指定数量的折扣
  PlanDiscount? getDiscount(int quantity) {
    try {
      return discounts.firstWhere((d) => d.quantity == quantity);
    } catch (e) {
      return null;
    }
  }

  /// 计算指定数量的价格（分）
  int calculatePrice(int quantity) {
    // 优先从 periods 列表中查找精确价格
    if (periods.isNotEmpty) {
      try {
        final period = periods.firstWhere((p) => p.months == quantity);
        return period.price;
      } catch (_) {
        // Not found in periods, fallback
      }
    }

    // Fallback for legacy logic or if periods missing
    if (quantity == 0) return 0; // Should not happen for one-time if periods populated

    final discount = getDiscount(quantity);
    if (discount != null) {
      // 应用折扣：原价 * 数量 * 折扣百分比 / 100
      return (unitPrice * quantity * discount.discount / 100).round();
    }
    // 无折扣
    return unitPrice * quantity;
  }

  /// 计算指定数量的价格（元）
  double calculatePriceInYuan(int quantity) {
    return calculatePrice(quantity) / 100.0;
  }

  /// 计算折扣百分比（节省百分比）
  int? calculateDiscountPercent(int quantity) {
    final discount = getDiscount(quantity);
    if (discount != null) {
      return 100 - discount.discount;
    }
    return null;
  }

  /// 格式化计费周期
  String formatUnitTime() {
    const unitMap = {
      'Month': '月',
      'Year': '年',
      'Day': '天',
      'Hour': '小时',
      'Minute': '分钟',
    };
    return unitMap[unitTime] ?? unitTime;
  }
}

/// 套餐价格周期 (UI Model)
class PlanPeriod {
  final String key; // API 参数名 (month_price, onetime_price, etc.)
  final String name; // 显示名称 (月付, 永久, etc.)
  final int price; // 价格 (分)
  final int months; // 月数 (0 for onetime)
  final bool isOnetime;

  PlanPeriod({
    required this.key,
    required this.name,
    required this.price,
    required this.months,
    this.isOnetime = false,
  });

  /// 价格 (元)
  double get priceYuan => price / 100.0;
  
  /// 格式化价格
  String get formattedPrice => '¥${priceYuan.toStringAsFixed(2)}';
}
