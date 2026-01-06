import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

class Ticket {
  final int id;
  final String title;
  final int status; // 0: 待处理, 1: 已回复, 2: 已关闭
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  final int userId;

  Ticket({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? json['subject'] as String? ?? '无标题',
      status: json['status'] as int? ?? 0,
      description: json['description'] as String? ?? json['content'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is int) {
      if (date.toString().length > 10) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(date * 1000);
      }
    } else if (date is String) {
      return DateTime.tryParse(date) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String get statusText {
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

  Color get statusColor {
    switch (status) {
      case 0:
        return AppTheme.primary; // Blue/Primary for Open
      case 1:
        return Colors.green; // Green for Answered
      case 2:
        return AppTheme.textSecondary; // Grey for Closed
      default:
        return AppTheme.textSecondary;
    }
  }
}
