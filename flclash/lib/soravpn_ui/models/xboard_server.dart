/// Xboard 服务器节点模型
class XboardServer {
  final int id;
  final int groupId;
  final int parentId;
  final List<String>? tags; // 标签
  final String name;
  final double rate; // 倍率
  final String? host;
  final int? port;
  final int? serverPort;
  final String? cipher;
  final int? isObfs;
  final String? network;
  final String? settings; // JSON 配置
  final int? tlsSettings;
  final int? ruleSettings;
  final int? dnsSettings;
  final int? show; // 是否显示
  final int? sort;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? lastCheckAt;
  final int? availableStatus; // 可用状态
  final String type; // shadowsocks, vmess, trojan 等

  XboardServer({
    required this.id,
    required this.groupId,
    this.parentId = 0,
    this.tags,
    required this.name,
    this.rate = 1.0,
    this.host,
    this.port,
    this.serverPort,
    this.cipher,
    this.isObfs,
    this.network,
    this.settings,
    this.tlsSettings,
    this.ruleSettings,
    this.dnsSettings,
    this.show,
    this.sort,
    this.createdAt,
    this.updatedAt,
    this.lastCheckAt,
    this.availableStatus,
    required this.type,
  });

  factory XboardServer.fromJson(Map<String, dynamic> json) {
    // 辅助函数：解析可能是 String 或 num 的 double 值
    double parseDouble(dynamic value, [double defaultValue = 1.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // 辅助函数：解析可能是 String 或 int 的 int 值
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return XboardServer(
      id: parseInt(json['id']) ?? 0,
      groupId: parseInt(json['group_id']) ?? 0,
      parentId: parseInt(json['parent_id']) ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      name: json['name']?.toString() ?? '',
      rate: parseDouble(json['rate']),
      host: json['host']?.toString(),
      port: parseInt(json['port']),
      serverPort: parseInt(json['server_port']),
      cipher: json['cipher']?.toString(),
      isObfs: parseInt(json['is_obfs']),
      network: json['network']?.toString(),
      settings: json['settings']?.toString(),
      tlsSettings: parseInt(json['tls_settings']),
      ruleSettings: parseInt(json['rule_settings']),
      dnsSettings: parseInt(json['dns_settings']),
      show: parseInt(json['show']),
      sort: parseInt(json['sort']),
      createdAt: parseInt(json['created_at']) != null
          ? DateTime.fromMillisecondsSinceEpoch(parseInt(json['created_at'])! * 1000)
          : null,
      updatedAt: parseInt(json['updated_at']) != null
          ? DateTime.fromMillisecondsSinceEpoch(parseInt(json['updated_at'])! * 1000)
          : null,
      lastCheckAt: parseInt(json['last_check_at']),
      availableStatus: parseInt(json['available_status']) ?? (json['is_online'] == 1 ? 1 : null),
      type: json['type']?.toString() ?? '',
    );
  }

  /// 是否可用
  bool get isAvailable => availableStatus == 1 || availableStatus == null;

  /// 获取国家代码 (从名称或标签推断)
  String get countryCode {
    final lowerName = name.toLowerCase();

    // 常见国家映射
    if (lowerName.contains('hongkong') || lowerName.contains('hong kong') || lowerName.contains('hk') || name.contains('香港')) return 'HK';
    if (lowerName.contains('taiwan') || lowerName.contains('tw') || name.contains('台湾')) return 'TW';
    if (lowerName.contains('japan') || lowerName.contains('jp') || name.contains('日本')) return 'JP';
    if (lowerName.contains('singapore') || lowerName.contains('sg') || name.contains('新加坡')) return 'SG';
    if (lowerName.contains('korea') || lowerName.contains('kr') || name.contains('韩国')) return 'KR';
    if (lowerName.contains('united states') || lowerName.contains('us') || lowerName.contains('america') || name.contains('美国')) return 'US';
    if (lowerName.contains('united kingdom') || lowerName.contains('uk') || lowerName.contains('britain') || name.contains('英国')) return 'GB';
    if (lowerName.contains('germany') || lowerName.contains('de') || name.contains('德国')) return 'DE';
    if (lowerName.contains('france') || lowerName.contains('fr') || name.contains('法国')) return 'FR';
    if (lowerName.contains('canada') || lowerName.contains('ca') || name.contains('加拿大')) return 'CA';
    if (lowerName.contains('australia') || lowerName.contains('au') || name.contains('澳大利亚')) return 'AU';
    if (lowerName.contains('russia') || lowerName.contains('ru') || name.contains('俄罗斯')) return 'RU';
    if (lowerName.contains('india') || lowerName.contains('in') || name.contains('印度')) return 'IN';
    if (lowerName.contains('netherlands') || lowerName.contains('nl') || name.contains('荷兰')) return 'NL';
    if (lowerName.contains('turkey') || lowerName.contains('tr') || name.contains('土耳其')) return 'TR';
    if (lowerName.contains('brazil') || lowerName.contains('br') || name.contains('巴西')) return 'BR';
    if (lowerName.contains('argentina') || lowerName.contains('ar') || name.contains('阿根廷')) return 'AR';
    if (lowerName.contains('philippines') || lowerName.contains('ph') || name.contains('菲律宾')) return 'PH';
    if (lowerName.contains('vietnam') || lowerName.contains('vn') || name.contains('越南')) return 'VN';
    if (lowerName.contains('thailand') || lowerName.contains('th') || name.contains('泰国')) return 'TH';
    if (lowerName.contains('malaysia') || lowerName.contains('my') || name.contains('马来西亚')) return 'MY';
    if (lowerName.contains('indonesia') || lowerName.contains('id') || name.contains('印度尼西亚')) return 'ID';

    return 'XX'; // 未知
  }

  /// 协议类型名称
  String get typeName {
    switch (type.toLowerCase()) {
      case 'shadowsocks':
        return 'SS';
      case 'vmess':
        return 'VMess';
      case 'trojan':
        return 'Trojan';
      case 'vless':
        return 'VLESS';
      case 'hysteria':
        return 'Hysteria';
      case 'hysteria2':
        return 'Hysteria2';
      default:
        return type.toUpperCase();
    }
  }
}

/// Xboard 服务器分组
class XboardServerGroup {
  final String name;
  final List<XboardServer> servers;

  XboardServerGroup({
    required this.name,
    required this.servers,
  });
}
