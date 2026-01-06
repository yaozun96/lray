import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';
import 'xboard_user_service.dart';

/// Xboard 服务器节点服务
/// 处理节点获取、订阅同步等操作
class XboardServerService {
  /// 获取服务器节点列表
  static Future<List<XboardServer>> getServers() async {
    final response = await xboardClient.get(
      XboardConfig.serverFetchUrl,
    );

    // 如果请求失败，打印详细信息并抛出异常
    if (!response.success) {
      print('[XboardServerService] Failed to get servers: ${response.message}');
      print('[XboardServerService] Status code: ${response.statusCode}');
      throw Exception(response.message ?? 'Failed to get servers');
    }

    // 如果数据为空或不是列表，返回空列表
    if (response.data == null) {
      print('[XboardServerService] No server data returned');
      return [];
    }

    if (response.data is! List) {
      print('[XboardServerService] Server data is not a list: ${response.data.runtimeType}');
      return [];
    }

    final servers = (response.data as List)
        .map((e) => XboardServer.fromJson(e as Map<String, dynamic>))
        .toList();

    print('[XboardServerService] Loaded ${servers.length} servers');
    return servers;
  }

  /// 按分组获取服务器列表
  static Future<List<XboardServerGroup>> getServerGroups() async {
    final servers = await getServers();

    // 按 groupId 分组
    final Map<int, List<XboardServer>> grouped = {};
    for (final server in servers) {
      grouped.putIfAbsent(server.groupId, () => []).add(server);
    }

    // 转换为 XboardServerGroup 列表
    return grouped.entries.map((entry) {
      return XboardServerGroup(
        name: '节点组 ${entry.key}',
        servers: entry.value,
      );
    }).toList();
  }

  /// 获取订阅链接
  static Future<String?> getSubscribeUrl() async {
    try {
      // 先尝试从本地获取
      final storedUrl = await XboardUserService.getStoredSubscribeUrl();
      if (storedUrl != null && storedUrl.isNotEmpty) {
        return storedUrl;
      }

      // 从服务器获取
      final subscribe = await XboardUserService.getSubscribe();
      return subscribe.subscribeUrl;
    } catch (e) {
      print('[XboardServerService] Failed to get subscribe URL: $e');
      return null;
    }
  }

  /// 获取 Clash 格式的订阅配置
  /// [subscribeUrl] 订阅链接
  static Future<String?> getClashConfig(String subscribeUrl) async {
    try {
      // 添加 flag=clash 参数
      final url = subscribeUrl.contains('?')
          ? '$subscribeUrl&flag=clash'
          : '$subscribeUrl?flag=clash';

      print('[XboardServerService] Fetching Clash config from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'clash-verge/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('[XboardServerService] Failed to get Clash config: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[XboardServerService] Error fetching Clash config: $e');
      return null;
    }
  }

  /// 获取 Sing-box 格式的订阅配置
  /// [subscribeUrl] 订阅链接
  static Future<Map<String, dynamic>?> getSingBoxConfig(String subscribeUrl) async {
    try {
      // 添加 flag=singbox 参数
      final url = subscribeUrl.contains('?')
          ? '$subscribeUrl&flag=singbox'
          : '$subscribeUrl?flag=singbox';

      print('[XboardServerService] Fetching Sing-box config from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'sing-box/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          String body = response.body;
          // 移除可能的注释行
          if (body.startsWith('//')) {
            final newlineIndex = body.indexOf('\n');
            if (newlineIndex != -1) {
              body = body.substring(newlineIndex + 1);
            }
          }
          return jsonDecode(body) as Map<String, dynamic>;
        } catch (e) {
          print('[XboardServerService] Failed to parse Sing-box config: $e');
          return null;
        }
      } else {
        print('[XboardServerService] Failed to get Sing-box config: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[XboardServerService] Error fetching Sing-box config: $e');
      return null;
    }
  }

  /// 获取通用订阅链接 (Base64 编码)
  static Future<String?> getGenericConfig(String subscribeUrl) async {
    try {
      print('[XboardServerService] Fetching generic config from: $subscribeUrl');

      final response = await http.get(
        Uri.parse(subscribeUrl),
        headers: {
          'User-Agent': 'ClashForAndroid/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('[XboardServerService] Failed to get generic config: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[XboardServerService] Error fetching generic config: $e');
      return null;
    }
  }

  /// 解析订阅信息头部
  /// 从 HTTP 响应头中获取订阅信息
  static Future<Map<String, dynamic>?> parseSubscriptionInfo(String subscribeUrl) async {
    try {
      final response = await http.get(
        Uri.parse(subscribeUrl),
        headers: {
          'User-Agent': 'ClashForAndroid/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final headers = response.headers;

        // 常见的订阅信息头部
        final subscriptionUserinfo = headers['subscription-userinfo'];
        final profileUpdateInterval = headers['profile-update-interval'];
        final profileWebPageUrl = headers['profile-web-page-url'];

        if (subscriptionUserinfo != null) {
          // 解析 subscription-userinfo 头部
          // 格式: upload=123456; download=789012; total=1000000000; expire=1234567890
          final Map<String, dynamic> info = {};
          final parts = subscriptionUserinfo.split(';');
          for (final part in parts) {
            final kv = part.trim().split('=');
            if (kv.length == 2) {
              final key = kv[0].trim();
              final value = int.tryParse(kv[1].trim()) ?? 0;
              info[key] = value;
            }
          }

          if (profileUpdateInterval != null) {
            info['update_interval'] = int.tryParse(profileUpdateInterval) ?? 24;
          }

          if (profileWebPageUrl != null) {
            info['web_page_url'] = profileWebPageUrl;
          }

          return info;
        }
      }

      return null;
    } catch (e) {
      print('[XboardServerService] Error parsing subscription info: $e');
      return null;
    }
  }
}
