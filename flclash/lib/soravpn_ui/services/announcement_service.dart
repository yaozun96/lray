/// 公告服务 - 已迁移到 Xboard API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/xboard_config.dart';
import 'xboard_auth_service.dart';

/// 公告服务
class AnnouncementService {
  /// 获取公告列表
  ///
  /// [page] 页码，默认1
  /// [size] 每页数量，默认99
  /// [pinnedOnly] 是否只获取置顶公告，null 表示不过滤
  /// [popupOnly] 是否只获取弹窗公告，null 表示不过滤
  static Future<List<Announcement>> getAnnouncements({
    int page = 1,
    int size = 99,
    bool? pinnedOnly,
    bool? popupOnly,
  }) async {
    final token = await XboardAuthService.getToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    try {
      // Xboard API: /api/v1/user/notice/fetch
      final url = XboardConfig.noticeFetchUrl;

      print('[AnnouncementService] Fetching announcements: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('[AnnouncementService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for error status if present
        if (data is Map && data.containsKey('status') && data['status'] != 'success' && data['status'] != 1) {
           throw Exception(data['message'] ?? 'Failed to get announcements');
        }

        final notices = (data['data'] != null) ? data['data'] as List? : (data is List ? data : null);
        
        if (notices == null) {
          return [];
        }

        var announcements = notices
            .map((json) => Announcement.fromJson(json))
            .toList();

        // 过滤
        if (pinnedOnly == true) {
          announcements = announcements.where((a) => a.pinned).toList();
        }
        if (popupOnly == true) {
          announcements = announcements.where((a) => a.popup).toList();
        }

        return announcements;
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('[AnnouncementService] Error: $e');
      rethrow;
    }
  }

  /// 获取置顶公告（只返回第一条）
  static Future<Announcement?> getPinnedAnnouncement() async {
    try {
      final announcements = await getAnnouncements(
        page: 1,
        size: 10,
        pinnedOnly: true,
      );

      // 找到第一个 pinned 为 true 的公告
      return announcements.firstWhere(
        (a) => a.pinned,
        orElse: () => announcements.isNotEmpty ? announcements.first : throw Exception('No announcements'),
      );
    } catch (e) {
      print('[AnnouncementService] No pinned announcement found');
      return null;
    }
  }
}

/// 公告模型
class Announcement {
  final int id;
  final String title;
  final String content; // HTML 格式
  final bool pinned;
  final bool popup;
  final int createdAt; // 时间戳（秒）

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
    required this.popup,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final tags = (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      // 根据 tags 判断置顶和弹窗状态
      pinned: tags.contains('置顶') || json['pinned'] == true || json['pinned'] == 1,
      popup: tags.contains('弹窗公告') || tags.contains('弹窗') || json['popup'] == true || json['popup'] == 1,
      createdAt: json['created_at'] ?? 0,
    );
  }

  /// 格式化创建时间
  String get formattedDate {
    try {
      // Xboard 使用秒级时间戳
      final timestamp = createdAt > 10000000000 ? createdAt : createdAt * 1000;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
