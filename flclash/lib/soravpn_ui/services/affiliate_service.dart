/// Affiliate Service - 已迁移到 Xboard API
/// 使用 XboardInviteService 代替

import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_invite_service.dart';

class AffiliateSummary {
  final double totalCommission; // 元
  final int inviteCount;
  final double? commissionRatio;
  final String inviteCode;
  final String inviteLink;

  AffiliateSummary({
    required this.totalCommission,
    required this.inviteCount,
    required this.commissionRatio,
    required this.inviteCode,
    required this.inviteLink,
  });
}

class AffiliateRecord {
  final String identifier;
  final DateTime registeredAt;
  final bool enabled;

  AffiliateRecord({
    required this.identifier,
    required this.registeredAt,
    required this.enabled,
  });
}

class AffiliateService {
  static String get _baseUrl => XboardConfig.apiBaseUrl;

  /// 获取邀请摘要 - 使用 Xboard API
  static Future<AffiliateSummary> getSummary() async {
    try {
      final inviteInfo = await XboardInviteService.getInviteInfo();

      // 获取邀请码列表中的第一个
      String inviteCode = '';
      if (inviteInfo.codes != null && inviteInfo.codes!.isNotEmpty) {
        inviteCode = inviteInfo.codes!.first.code;
      }

      return AffiliateSummary(
        totalCommission: (inviteInfo.stat?.commissionPendingBalance ?? 0) / 100.0,
        inviteCount: inviteInfo.stat?.registeredCount ?? 0,
        commissionRatio: null, // Xboard 不提供此字段
        inviteCode: inviteCode,
        inviteLink: inviteCode.isNotEmpty
            ? '$_baseUrl/#/register?aff=$inviteCode'
            : '',
      );
    } catch (e) {
      throw Exception('获取邀请信息失败: $e');
    }
  }

  /// 获取邀请记录列表 - Xboard API 可能不直接支持
  static Future<List<AffiliateRecord>> getAffiliateRecords() async {
    // Xboard 的邀请 API 不直接返回被邀请用户列表
    // 返回空列表或考虑使用其他方式
    return [];
  }
}
