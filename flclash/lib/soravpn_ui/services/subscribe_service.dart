/// Subscribe Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 Xboard 服务
///
/// 新代码请直接使用:
/// - XboardServerService (节点和订阅)
/// - XboardUserService (用户订阅信息)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_clash/soravpn_ui/models/node_group.dart';
import 'package:fl_clash/soravpn_ui/models/routing_group.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/models/models.dart';
import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_server_service.dart';
import 'xboard_user_service.dart';
import 'xboard_auth_service.dart';

/// Subscription and node service for SoraVPN
/// 现已迁移到 Xboard API
class SubscribeService {
  static String get _baseUrl => XboardConfig.apiBaseUrl;

  /// Get Sing-box subscription config directly using subscription URL
  static Future<Map<String, dynamic>?> getSingBoxConfig(String subscriptionToken) async {
    // 注意: Xboard 使用完整的订阅 URL，而不是 token
    // 如果传入的是 token，需要构建完整 URL
    String subscribeUrl;
    if (subscriptionToken.startsWith('http')) {
      subscribeUrl = subscriptionToken;
    } else {
      // 从用户信息获取订阅 URL
      subscribeUrl = await XboardServerService.getSubscribeUrl() ?? '';
      if (subscribeUrl.isEmpty) {
        print('[SubscribeService] No subscribe URL found');
        return null;
      }
    }

    return await XboardServerService.getSingBoxConfig(subscribeUrl);
  }

  /// Get the subscription URL from user info
  static Future<String?> getFirstSubscriptionToken() async {
    return await XboardServerService.getSubscribeUrl();
  }

  /// Get user's subscription node list
  static Future<List<VpnNode>> getNodeList() async {
    final servers = await XboardServerService.getServers();
    return servers.map((server) => VpnNode(
      id: server.id,
      name: server.name,
      uuid: '',
      protocol: server.type,
      serverAddr: server.host ?? '',
      serverPort: server.port ?? 0,
      config: '',
      country: server.countryCode,
      tags: server.tags ?? [],
      speedLimit: 0,
      trafficRatio: server.rate,
    )).toList();
  }

  /// Get user's subscription node list grouped by outbound rules
  static Future<List<NodeGroup>> getGroupedNodeList() async {
    final serverGroups = await XboardServerService.getServerGroups();

    return serverGroups.map((group) => NodeGroup(
      subscriptionId: 0,
      groupName: group.name,
      nodes: group.servers.map((server) => VpnNode(
        id: server.id,
        name: server.name,
        uuid: '',
        protocol: server.type,
        serverAddr: server.host ?? '',
        serverPort: server.port ?? 0,
        config: '',
        country: server.countryCode,
        tags: server.tags ?? [],
        speedLimit: 0,
        trafficRatio: server.rate,
      )).toList(),
    )).toList();
  }

  /// Get routing groups for RoutingSettingsDialog
  static Future<List<RoutingGroup>> getRoutingGroups() async {
    final token = await XboardAuthService.getToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    print('[SubscribeService] Getting routing groups from FlClash core...');

    try {
      final groups = globalState.appController.getCurrentGroups();

      if (groups.isEmpty) {
        print('[SubscribeService] No groups found in FlClash core');
        return [];
      }

      List<RoutingGroup> routingGroups = [];

      for (var group in groups) {
        final groupName = group.name;

        if (groupName == 'GLOBAL' || group.hidden == true) {
          continue;
        }

        final proxyNames = group.all.map((proxy) => proxy.name).toList();
        final currentSelection = group.now ?? (proxyNames.isNotEmpty ? proxyNames.first : '');

        if (proxyNames.isNotEmpty) {
          routingGroups.add(RoutingGroup(
            name: groupName,
            options: proxyNames,
            defaultOption: currentSelection,
          ));
        }
      }

      return routingGroups;
    } catch (e) {
      print('[SubscribeService] Error getting routing groups: $e');
      throw Exception('Get routing groups error: $e');
    }
  }

  /// Get user's active subscriptions
  static Future<List<Subscription>> getSubscriptionList() async {
    try {
      print('[SubscribeService] Getting subscription via getSubscribe API...');
      
      // 1. 尝试从本地缓存加载 (确保快速显示)
      final prefs = await SharedPreferences.getInstance();
      final cachedSubscribeJson = prefs.getString('cached_subscribe_data');
      XboardSubscribe? subscribeData;
      
      if (cachedSubscribeJson != null) {
        try {
           final Map<String, dynamic> jsonMap = json.decode(cachedSubscribeJson);
           subscribeData = XboardSubscribe.fromJson(jsonMap);
           print('[SubscribeService] Loaded cached subscription data');
        } catch (e) {
           print('[SubscribeService] Failed to parse cached subscription: $e');
        }
      }

      // 2. 如果有缓存，先返回 (但这通常是在异步函数中，直接返回就结束了)
      // 这里的策略是：如果没有缓存，等待网络。如果有缓存，如何更新？
      // 也许我们应该在 UI 层处理这个逻辑，或者在这里先返回缓存，然后后台更新？
      // 既然这是个 Future，我们只能返回一次。
      
      // 更好的做法是：如果有缓存，且距离上次更新不久，直接返回缓存？
      // 或者：必须等待网络以保证准确性？
      // 用户遇到的问题是第一次进入显示暂无套餐。
      
      // 我们修改为：优先获取网络，如果网络失败（或超时），则返回缓存。
      // 但现在的问题是网络请求可能太慢了，在此期间 UI 认为没有套餐。
      
      // 让我们尝试获取网络数据，但使用缓存作为后备。
      // 并且在获取成功后更新缓存。
      
      try {
        final subscribe = await XboardUserService.getSubscribe();
        
        // 缓存最新的订阅数据
        await prefs.setString('cached_subscribe_data', json.encode(subscribe.toJson()));
        
        subscribeData = subscribe; // 使用最新的
      } catch (e) {
         print('[SubscribeService] Network request failed: $e');
         if (subscribeData == null) rethrow; // 如果连缓存都没有，那就真的抛出错误
         print('[SubscribeService] Falling back to cached data');
      }
      
      if (subscribeData == null) return [];

      final subscribe = subscribeData;
      print('[SubscribeService] Subscribe data: planId=${subscribe.planId}, planName=${subscribe.planName}');
      print('[SubscribeService] Subscribe details: expiredAt=${subscribe.expiredAt}, transfer=${subscribe.transferEnable}, u=${subscribe.u}, d=${subscribe.d}');

      // 检查是否有有效套餐
      if (subscribe.planId == null || subscribe.planId == 0) {
        print('[SubscribeService] No plan assigned');
        return [];
      }

      // 检查是否有 plan 对象
      if (subscribe.plan == null) {
        print('[SubscribeService] No plan object in subscribe response');
        // 还是返回订阅，但显示 Unknown Plan
      }

      // 计算剩余天数
      final remainingDays = subscribe.remainingDays;
      print('[SubscribeService] Remaining days: $remainingDays');

      // 转换为旧的 Subscription 格式
      // 使用 XboardSubscribe 中的数据（而不是 user 数据）
      // reset_day 是后端直接返回的"距离下次重置还有多少天"
      final resetDays = int.tryParse(subscribe.resetDay ?? '') ?? 0;
      print('[SubscribeService] Reset days from API: $resetDays');

      return [
        Subscription(
          id: 1,
          userId: 0,
          subscribeId: subscribe.planId ?? 0,
          upload: subscribe.u ?? 0,
          download: subscribe.d ?? 0,
          traffic: subscribe.transferEnable ?? 0,
          startTime: 0,
          expireTime: subscribe.expiredAt ?? 0, // 秒级时间戳
          resetDaysRemaining: resetDays > 0 ? resetDays : null, // 直接存储剩余天数
          token: subscribe.subscribeUrl,
          subscribe: subscribe.plan != null
              ? SubscribePlan(
                  id: subscribe.plan!.id,
                  name: subscribe.plan!.name,
                  description: subscribe.plan!.content,
                  resetCycle: subscribe.plan!.resetDay ?? 0,
                )
              : null,
        ),
      ];
    } catch (e) {
      print('[SubscribeService] Error getting subscription list: $e');
      return [];
    }
  }

  /// Get unsubscribe preview - Xboard 可能不支持
  @Deprecated('Xboard may not support unsubscribe preview')
  static Future<UnsubscribePreview> getUnsubscribePreview(int subscriptionId) async {
    throw Exception('Unsubscribe preview is not supported');
  }

  /// Cancel subscription - Xboard 可能不支持
  @Deprecated('Xboard may not support direct unsubscribe')
  static Future<void> unsubscribe(int subscriptionId) async {
    throw Exception('Direct unsubscribe is not supported');
  }

  /// Sync subscription to FlClash Core
  static Future<void> syncToFlClash() async {
    // 强制从 Xboard API 获取最新的订阅信息，不使用缓存
    String? subscribeUrl;
    try {
      print('[SubscribeService] Getting fresh subscribe URL from Xboard API...');
      final subscribe = await XboardUserService.getSubscribe();
      subscribeUrl = subscribe.subscribeUrl;
      print('[SubscribeService] Got subscribe URL: $subscribeUrl');
    } catch (e) {
      print('[SubscribeService] Failed to get subscribe URL from API: $e');
      // 如果 API 失败，尝试从本地获取
      subscribeUrl = await XboardServerService.getSubscribeUrl();
    }

    if (subscribeUrl == null || subscribeUrl.isEmpty) {
      print('[SubscribeService] No subscription URL found for sync');
      return;
    }

    // 移除 flag=clash 参数，尝试获取原始节点列表
    // 这样 FlClash Core 会自动处理分组，而不是使用服务端预设的分组
    final url = subscribeUrl;

    print('[SubscribeService] Syncing to FlClash with URL: $url');

    const soraProfileId = 'soravpn_main';

    final exists = globalState.config.profiles.any((p) => p.id == soraProfileId);

    final profile = Profile(
      id: soraProfileId,
      label: 'SoraVPN',
      url: url,
      autoUpdateDuration: const Duration(minutes: 60),
    );

    if (exists) {
      await globalState.appController.updateProfile(profile);
    } else {
      await globalState.appController.addProfile(profile);
    }

    if (globalState.config.currentProfileId != soraProfileId) {
      globalState.appController.setProfileAndAutoApply(profile);
    }
  }

  static Future<String?> getToken() => XboardAuthService.getToken();
}

/// VPN Node model - 保持兼容
class VpnNode {
  final int id;
  final String name;
  final String uuid;
  final String protocol;
  final String serverAddr;
  final int serverPort;
  final String config;
  final String country;
  final List<String> tags;
  final int speedLimit;
  final double trafficRatio;
  final String? method;
  final String? password;
  final String? flow;
  final int? alterId;
  final String? security;
  final Map<String, dynamic>? tls;
  final Map<String, dynamic>? rawJson;

  VpnNode({
    required this.id,
    required this.name,
    required this.uuid,
    required this.protocol,
    required this.serverAddr,
    required this.serverPort,
    required this.config,
    required this.country,
    required this.tags,
    required this.speedLimit,
    required this.trafficRatio,
    this.method,
    this.password,
    this.flow,
    this.alterId,
    this.security,
    this.tls,
    this.rawJson,
  });

  factory VpnNode.fromJson(Map<String, dynamic> json) {
    return VpnNode(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      uuid: json['uuid'] ?? '',
      protocol: json['protocol'] ?? json['type'] ?? '',
      serverAddr: json['address'] ?? json['server_addr'] ?? json['server'] ?? json['host'] ?? '',
      serverPort: json['port'] ?? json['server_port'] ?? 443,
      config: json['config'] ?? '',
      country: json['country'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      speedLimit: json['speed_limit'] ?? 0,
      trafficRatio: (json['traffic_ratio'] ?? json['rate'] ?? 1.0).toDouble(),
      method: json['method'] ?? json['cipher'],
      password: json['password'],
      flow: json['flow'],
      alterId: json['alter_id'] ?? json['aid'],
      security: json['security'],
      tls: json['tls'] is Map ? Map<String, dynamic>.from(json['tls']) : null,
      rawJson: json,
    );
  }

  factory VpnNode.auto() {
    return VpnNode(
      id: -1,
      name: 'Auto',
      uuid: '',
      protocol: 'url-test',
      serverAddr: '',
      serverPort: 0,
      config: '',
      country: 'XX',
      tags: ['Auto'],
      speedLimit: 0,
      trafficRatio: 1.0,
    );
  }
}

/// Subscribe plan details - 保持兼容
class SubscribePlan {
  final int id;
  final String name;
  final String? description;
  final int resetCycle;

  SubscribePlan({
    required this.id,
    required this.name,
    this.description,
    required this.resetCycle,
  });

  factory SubscribePlan.fromJson(Map<String, dynamic> json) {
    return SubscribePlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? json['content'],
      resetCycle: json['reset_cycle'] ?? 0,
    );
  }

  String get resetCycleText {
    switch (resetCycle) {
      case 0:
        return '不重置';
      case 1:
        return '每月1日';
      case 2:
        return '每月';
      case 3:
        return '每年';
      default:
        return '未知';
    }
  }
}

/// Subscription model - 保持兼容
class Subscription {
  final int id;
  final int userId;
  final int subscribeId;
  final int upload;
  final int download;
  final int traffic;
  final int startTime;
  final int expireTime;
  final int? resetDaysRemaining; // 距离下次重置的天数（直接从API获取）
  final String token;
  final SubscribePlan? subscribe;

  Subscription({
    required this.id,
    required this.userId,
    required this.subscribeId,
    required this.upload,
    required this.download,
    required this.traffic,
    required this.startTime,
    required this.expireTime,
    this.resetDaysRemaining,
    required this.token,
    this.subscribe,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      subscribeId: json['subscribe_id'] ?? json['plan_id'] ?? 0,
      upload: json['upload'] ?? json['u'] ?? 0,
      download: json['download'] ?? json['d'] ?? 0,
      traffic: json['traffic'] ?? json['transfer_enable'] ?? 0,
      startTime: json['start_time'] ?? json['created_at'] ?? 0,
      expireTime: json['expire_time'] ?? json['expired_at'] ?? 0,
      resetDaysRemaining: json['reset_day'],
      token: json['token'] ?? json['subscribe_url'] ?? '',
      subscribe: json['subscribe'] != null || json['plan'] != null
          ? SubscribePlan.fromJson(json['subscribe'] ?? json['plan'])
          : null,
    );
  }

  String get name => subscribe?.name ?? 'Unknown Plan';

  double get usagePercentage {
    if (traffic == 0) return 0;
    final used = upload + download;
    return (used / traffic * 100).clamp(0, 100);
  }

  String formatTraffic(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int? getResetDays() {
    // 直接返回 API 返回的剩余天数
    return resetDaysRemaining;
  }

  int getExpireDays() {
    if (expireTime == 0) return 0;
    try {
      // Xboard 使用秒级时间戳，需要转换为毫秒
      // 参考 theme_website: expiredTime * 1000
      final expireTimestamp = expireTime > 10000000000 ? expireTime : expireTime * 1000;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = expireTimestamp - now;
      if (diff <= 0) return 0;
      return (diff / 1000 / 60 / 60 / 24).floor(); // 毫秒转天数
    } catch (e) {
      return 0;
    }
  }

  String getResetCycle() {
    return subscribe?.resetCycleText ?? '未知';
  }
}

/// Unsubscribe preview model - 保持兼容
class UnsubscribePreview {
  final double deductionAmount;

  UnsubscribePreview({
    required this.deductionAmount,
  });

  factory UnsubscribePreview.fromJson(Map<String, dynamic> json) {
    final deduction = json['deduction_amount'] ??
        json['deductionAmount'] ??
        json['remaining_value'] ??
        json['refund_amount'] ??
        0;
    final amount = (deduction is int) ? deduction.toDouble() : (deduction as num).toDouble();
    return UnsubscribePreview(
      deductionAmount: amount / 100,
    );
  }
}
