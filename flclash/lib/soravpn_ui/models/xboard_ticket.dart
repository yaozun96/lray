/// Xboard 工单模型
class XboardTicket {
  final int id;
  final int userId;
  final String subject; // 主题
  final int level; // 优先级: 0: 低, 1: 中, 2: 高
  final int status; // 状态: 0: 待处理, 1: 已回复, 2: 已关闭
  final String? replyStatus; // 回复状态
  final int? createdAt;
  final int? updatedAt;
  final List<XboardTicketMessage>? message; // 消息列表

  XboardTicket({
    required this.id,
    required this.userId,
    required this.subject,
    this.level = 0,
    this.status = 0,
    this.replyStatus,
    this.createdAt,
    this.updatedAt,
    this.message,
  });

  factory XboardTicket.fromJson(Map<String, dynamic> json) {
    return XboardTicket(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      subject: json['subject'] ?? '',
      level: json['level'] ?? 0,
      status: json['status'] ?? 0,
      replyStatus: json['reply_status']?.toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      message: json['message'] != null
          ? (json['message'] as List)
              .map((e) => XboardTicketMessage.fromJson(e))
              .toList()
          : null,
    );
  }

  /// 优先级名称
  String get levelName {
    switch (level) {
      case 0:
        return '低';
      case 1:
        return '中';
      case 2:
        return '高';
      default:
        return '未知';
    }
  }

  /// 状态名称
  String get statusName {
    switch (status) {
      case 0:
        return '待处理';
      case 1:
        return '已回复';
      case 2:
        return '已关闭';
      default:
        return '未知';
    }
  }

  /// 是否已关闭
  bool get isClosed => status == 2;

  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;

  /// 更新时间
  DateTime? get updatedTime =>
      updatedAt != null ? DateTime.fromMillisecondsSinceEpoch(updatedAt! * 1000) : null;
}

/// Xboard 工单消息模型
class XboardTicketMessage {
  final int id;
  final int ticketId;
  final int userId;
  final String message;
  final bool isMe; // 是否是用户发送的
  final int? createdAt;
  final int? updatedAt;

  XboardTicketMessage({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    this.isMe = false,
    this.createdAt,
    this.updatedAt,
  });

  factory XboardTicketMessage.fromJson(Map<String, dynamic> json) {
    return XboardTicketMessage(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      message: json['message'] ?? '',
      isMe: json['is_me'] == 1 || json['is_me'] == true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// 创建时间
  DateTime? get createdTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000) : null;
}
