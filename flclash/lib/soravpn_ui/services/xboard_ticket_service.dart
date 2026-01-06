import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';

/// Xboard 工单服务
/// 处理工单的创建、查询、回复和关闭
class XboardTicketService {
  /// 获取工单列表
  static Future<List<XboardTicket>> getTickets({int page = 1, int pageSize = 10}) async {
    final response = await xboardClient.get(
      '${XboardConfig.ticketFetchUrl}?page=$page&limit=$pageSize',
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get tickets');
    }

    if (response.data == null || response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((e) => XboardTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取工单详情 (包含消息列表)
  static Future<XboardTicket> getTicketDetail(int ticketId) async {
    final response = await xboardClient.get(
      XboardConfig.ticketFetchUrl,
      params: {'id': ticketId.toString()},
      fromJson: (data) => XboardTicket.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get ticket detail');
    }

    if (response.data == null) {
      throw Exception('No ticket data received');
    }

    return response.data!;
  }

  /// 创建工单
  /// [subject] 主题
  /// [message] 内容
  /// [level] 优先级 (0: 低, 1: 中, 2: 高)
  static Future<bool> createTicket({
    required String subject,
    required String message,
    int level = 0,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.ticketSaveUrl,
      data: {
        'subject': subject,
        'message': message,
        'level': level,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to create ticket');
    }

    return true;
  }

  /// 回复工单
  /// [ticketId] 工单 ID
  /// [message] 回复内容
  static Future<bool> replyTicket({
    required int ticketId,
    required String message,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.ticketReplyUrl,
      data: {
        'id': ticketId,
        'message': message,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to reply ticket');
    }

    return true;
  }

  /// 关闭工单
  static Future<bool> closeTicket(int ticketId) async {
    final response = await xboardClient.post(
      XboardConfig.ticketCloseUrl,
      data: {'id': ticketId},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to close ticket');
    }

    return true;
  }

  /// 撤回工单 (如果支持)
  static Future<bool> withdrawTicket(int ticketId) async {
    final response = await xboardClient.post(
      XboardConfig.ticketWithdrawUrl,
      data: {'id': ticketId},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to withdraw ticket');
    }

    return true;
  }
}
