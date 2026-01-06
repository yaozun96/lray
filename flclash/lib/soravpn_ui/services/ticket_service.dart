/// Ticket Service - 已迁移到 Xboard API
/// 此文件现在作为兼容层，调用新的 XboardTicketService
///
/// 新代码请直接使用:
/// - XboardTicketService

import '../models/ticket.dart';
import '../models/ticket_message.dart';
import '../models/xboard_models.dart';
import 'xboard_ticket_service.dart';
import 'xboard_auth_service.dart';

/// Ticket service for SoraVPN
/// 现已迁移到 Xboard API
class TicketService {
  /// 获取工单列表
  static Future<List<Ticket>> getTickets({
    int page = 1,
    int size = 100,
    int? status,
  }) async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final xboardTickets = await XboardTicketService.getTickets(page: page, pageSize: size);

      // 如果指定了状态，进行过滤
      var filteredTickets = xboardTickets;
      if (status != null) {
        filteredTickets = xboardTickets.where((t) => t.status == status).toList();
      }

      // 转换为旧的 Ticket 格式
      return filteredTickets.map((t) {
        // Map Xboard status to Ticket status
        // Xboard: 0=Open, 1=Closed
        // Ticket: 0=Pending, 1=Answered, 2=Closed
        int ticketStatus = 0;
        if (t.status == 1) {
          ticketStatus = 2; // Closed
        } else {
          // Open
          if (t.replyStatus == '1') {
            ticketStatus = 0; // Pending (User Replied)
          } else {
            ticketStatus = 1; // Answered
          }
        }

        return Ticket(
          id: t.id,
          userId: t.userId,
          title: t.subject,
          description: '',
          status: ticketStatus,
          createdAt: t.createdTime ?? DateTime.now(),
          updatedAt: t.updatedTime ?? DateTime.now(),
        );
      }).toList().cast<Ticket>();
    } catch (e) {
      throw Exception('Get tickets error: $e');
    }
  }

  /// 获取工单详情
  static Future<Map<String, dynamic>> getTicketDetail(int id) async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final xboardTicket = await XboardTicketService.getTicketDetail(id);

      // Map Xboard status to Ticket status
      // Refined Logic based on User Feedback:
      // Xboard Status: 1 = Closed
      // Xboard Reply Status: '0' = Answered (Admin Replied), '1' = Pending (User Replied) [INVERTED]
      int ticketStatus = 0;
      if (xboardTicket.status == 1) {
        ticketStatus = 2; // Closed
      } else {
        // Open Logic
        if (xboardTicket.replyStatus == '1') {
          ticketStatus = 0; // Pending (User Replied)
        } else {
          ticketStatus = 1; // Answered (Admin Replied) - Assuming '0' or null means admin action
        }
      }

      final ticket = Ticket(
        id: xboardTicket.id,
        userId: xboardTicket.userId,
        title: xboardTicket.subject,
        description: '',
        status: ticketStatus,
        createdAt: xboardTicket.createdTime ?? DateTime.now(),
        updatedAt: xboardTicket.updatedTime ?? DateTime.now(),
      );

      List<TicketMessage> messages = [];
      if (xboardTicket.message != null) {
        messages = xboardTicket.message!.map((m) => TicketMessage(
          id: m.id,
          ticketId: m.ticketId,
          content: m.message,
          type: 1,
          userId: 0,
          isAdmin: !m.isMe,
          createdAt: m.createdTime ?? DateTime.now(),
        )).toList().cast<TicketMessage>();
      }

      return {
        'ticket': ticket,
        'messages': messages,
      };
    } catch (e) {
      throw Exception('Get ticket detail error: $e');
    }
  }

  /// 创建工单
  static Future<void> createTicket(String title, String content, int priority) async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      await XboardTicketService.createTicket(
        subject: title,
        message: content,
        level: priority,
      );
    } catch (e) {
      throw Exception('Create ticket error: $e');
    }
  }

  /// 回复工单
  /// [type] 1: text, 2: image
  static Future<void> replyTicket(int ticketId, String content, {int type = 1}) async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      await XboardTicketService.replyTicket(
        ticketId: ticketId,
        message: content,
      );
    } catch (e) {
      throw Exception('Reply ticket error: $e');
    }
  }

  /// 关闭工单
  static Future<void> closeTicket(int ticketId) async {
    try {
      final token = await XboardAuthService.getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      await XboardTicketService.closeTicket(ticketId);
    } catch (e) {
      throw Exception('Close ticket error: $e');
    }
  }
}
