class TicketMessage {
  final int id;
  final String content;
  final int userId;
  final int ticketId;
  final bool isAdmin; // true if replied by admin/support
  final int type; // 1: text, 2: image
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.content,
    required this.userId,
    required this.ticketId,
    required this.isAdmin,
    this.type = 1,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    // 根据后端API调整字段名
    // 这里假设后端返回的消息结构
    return TicketMessage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      content: json['content']?.toString() ?? '',
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      ticketId: int.tryParse(json['ticket_id'].toString()) ?? 0,
      isAdmin: (json['from'] == 'System') || (json['is_admin'] == 1) || (json['is_admin'] == '1'), 
      type: int.tryParse(json['type'].toString()) ?? 1,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is int) {
      // Assuming milliseconds if > 10000000000 (roughly year 2286 in seconds, so safe for ms check)
      if (date > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(date * 1000);
      }
    } else if (date is String) {
      if (date.isEmpty) return DateTime.now();
      // Try parsing numeric string
      final num = int.tryParse(date);
      if (num != null) return _parseDate(num);
      return DateTime.tryParse(date) ?? DateTime.now();
    }
    return DateTime.now();
  }

  bool get isImage => type == 2;
}
