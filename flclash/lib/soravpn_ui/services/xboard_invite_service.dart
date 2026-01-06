import '../config/xboard_config.dart';
import '../models/xboard_models.dart';
import 'xboard_http_client.dart';

/// Xboard 邀请服务
/// 处理邀请码、佣金等操作
class XboardInviteService {
  /// 获取邀请信息 (包含邀请码和统计)
  static Future<XboardInvite> getInviteInfo() async {
    final response = await xboardClient.get(
      XboardConfig.inviteFetchUrl,
      fromJson: (data) => XboardInvite.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get invite info');
    }

    return response.data ?? XboardInvite();
  }

  /// 生成新的邀请码
  static Future<XboardInviteCode> generateInviteCode() async {
    final response = await xboardClient.get(
      XboardConfig.inviteSaveUrl,
      fromJson: (data) => XboardInviteCode.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to generate invite code');
    }

    if (response.data == null) {
      throw Exception('No invite code received');
    }

    return response.data!;
  }

  /// 获取邀请码列表
  static Future<List<XboardInviteCode>> getInviteCodes() async {
    final info = await getInviteInfo();
    return info.codes ?? [];
  }

  /// 获取邀请统计
  static Future<XboardInviteStat> getInviteStat() async {
    final info = await getInviteInfo();
    return info.stat ?? XboardInviteStat();
  }

  static Future<bool> transferCommission(int amount) async {
    final response = await xboardClient.post(
      XboardConfig.transferUrl,
      data: {'transfer_amount': amount},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to transfer commission');
    }

    return true;
  }

  /// 申请提现
  static Future<bool> withdrawCommission({
    required String method,
    required String account,
  }) async {
    final response = await xboardClient.post(
      XboardConfig.inviteWithdrawUrl,
      data: {
        'withdraw_method': method,
        'withdraw_account': account,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to withdraw commission');
    }

    return true;
  }

  /// 获取邀请明细
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<List<XboardInviteDetail>> getInviteDetails({int page = 1, int pageSize = 20}) async {
    final response = await xboardClient.get(
      '${XboardConfig.inviteDetailsUrl}?page=$page&limit=$pageSize',
      fromJson: (data) {
         if (data is List) {
           return data.map((e) => XboardInviteDetail.fromJson(e as Map<String, dynamic>)).toList();
         }
         return <XboardInviteDetail>[];
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to get invite details');
    }

    return response.data ?? [];
  }

  /// 获取邀请链接
  /// [inviteCode] 邀请码
  /// [baseUrl] 网站基础 URL
  static String getInviteUrl(String inviteCode, {String? baseUrl}) {
    final url = baseUrl ?? XboardConfig.apiBaseUrl;
    return '$url/#/register?code=$inviteCode';
  }
}
