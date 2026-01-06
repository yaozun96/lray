/// Xboard 套餐模型
class XboardPlan {
  final int id;
  final int groupId;
  final int? transferEnable; // 流量 (GB)
  final String name;
  final int? speedLimit; // 速度限制 (Mbps)
  final bool show; // 是否显示
  final int? sort;
  final bool renew; // 是否允许续费
  final int? resetPriceType; // 重置价格类型
  final int? capacityLimit; // 容量限制
  final String? content; // 描述
  final int? monthPrice; // 月付价格 (分)
  final int? quarterPrice; // 季付价格 (分)
  final int? halfYearPrice; // 半年付价格 (分)
  final int? yearPrice; // 年付价格 (分)
  final int? twoYearPrice; // 两年付价格 (分)
  final int? threeYearPrice; // 三年付价格 (分)
  final int? onetimePrice; // 一次性价格 (分)
  final int? resetPrice; // 重置价格 (分)
  final List<dynamic>? tags; // 标签
  final DateTime? createdAt;
  final DateTime? updatedAt;

  XboardPlan({
    required this.id,
    required this.groupId,
    this.transferEnable,
    required this.name,
    this.speedLimit,
    this.show = true,
    this.sort,
    this.renew = true,
    this.resetPriceType,
    this.capacityLimit,
    this.content,
    this.monthPrice,
    this.quarterPrice,
    this.halfYearPrice,
    this.yearPrice,
    this.twoYearPrice,
    this.threeYearPrice,
    this.onetimePrice,
    this.resetPrice,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory XboardPlan.fromJson(Map<String, dynamic> json) {
    return XboardPlan(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? 0,
      transferEnable: json['transfer_enable'],
      name: json['name'] ?? '',
      speedLimit: json['speed_limit'],
      show: json['show'] == 1 || json['show'] == true,
      sort: json['sort'],
      renew: json['renew'] == 1 || json['renew'] == true || json['renew'] == null,
      resetPriceType: json['reset_price_type'],
      capacityLimit: json['capacity_limit'],
      content: json['content'],
      monthPrice: json['month_price'],
      quarterPrice: json['quarter_price'],
      halfYearPrice: json['half_year_price'],
      yearPrice: json['year_price'],
      twoYearPrice: json['two_year_price'],
      threeYearPrice: json['three_year_price'],
      onetimePrice: json['onetime_price'],
      resetPrice: json['reset_price'],
      tags: json['tags'],
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] * 1000)
          : null,
    );
  }

  /// 获取所有可用的价格周期
  List<PlanPeriod> get availablePeriods {
    final periods = <PlanPeriod>[];

    if (monthPrice != null && monthPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'month_price',
        name: '月付',
        price: monthPrice!,
        months: 1,
      ));
    }
    if (quarterPrice != null && quarterPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'quarter_price',
        name: '季付',
        price: quarterPrice!,
        months: 3,
      ));
    }
    if (halfYearPrice != null && halfYearPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'half_year_price',
        name: '半年付',
        price: halfYearPrice!,
        months: 6,
      ));
    }
    if (yearPrice != null && yearPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'year_price',
        name: '年付',
        price: yearPrice!,
        months: 12,
      ));
    }
    if (twoYearPrice != null && twoYearPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'two_year_price',
        name: '两年付',
        price: twoYearPrice!,
        months: 24,
      ));
    }
    if (threeYearPrice != null && threeYearPrice! > 0) {
      periods.add(PlanPeriod(
        key: 'three_year_price',
        name: '三年付',
        price: threeYearPrice!,
        months: 36,
      ));
    }
    if (onetimePrice != null && onetimePrice! > 0) {
      periods.add(PlanPeriod(
        key: 'onetime_price',
        name: '一次性',
        price: onetimePrice!,
        months: 0,
        isOnetime: true,
      ));
    }

    return periods;
  }

  /// 最低价格 (分)
  int? get minPrice {
    final prices = [
      monthPrice,
      quarterPrice,
      halfYearPrice,
      yearPrice,
      twoYearPrice,
      threeYearPrice,
      onetimePrice,
    ].whereType<int>().where((p) => p > 0);

    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  /// 流量格式化
  String get formattedTraffic {
    if (transferEnable == null) return '无限';
    if (transferEnable! < 1024) return '${transferEnable}GB';
    return '${(transferEnable! / 1024).toStringAsFixed(1)}TB';
  }

  /// 根据数量 (月数) 获取价格
  int getPriceByQuantity(int quantity) {
    switch (quantity) {
      case 1:
        return monthPrice ?? 0;
      case 3:
        return quarterPrice ?? 0;
      case 6:
        return halfYearPrice ?? 0;
      case 12:
        return yearPrice ?? 0;
      case 24:
        return twoYearPrice ?? 0;
      case 36:
        return threeYearPrice ?? 0;
      case 0:
        return onetimePrice ?? 0;
      default:
        // 尝试按月计算
        if (monthPrice != null && monthPrice! > 0) {
          return monthPrice! * quantity;
        }
        return 0;
    }
  }
}

/// 套餐价格周期
class PlanPeriod {
  final String key; // API 参数名
  final String name; // 显示名称
  final int price; // 价格 (分)
  final int months; // 月数
  final bool isOnetime; // 是否一次性

  PlanPeriod({
    required this.key,
    required this.name,
    required this.price,
    required this.months,
    this.isOnetime = false,
  });

  /// 价格 (元)
  double get priceYuan => price / 100;

  /// 格式化价格
  String get formattedPrice => '¥${priceYuan.toStringAsFixed(2)}';

  /// 月均价格 (元)
  double? get monthlyPrice {
    if (isOnetime || months == 0) return null;
    return priceYuan / months;
  }
}
