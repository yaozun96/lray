import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/services/purchase_service.dart';
import 'package:fl_clash/soravpn_ui/models/plan.dart';
import 'package:fl_clash/soravpn_ui/models/order.dart';
import 'package:fl_clash/soravpn_ui/models/payment_method.dart';
import 'package:fl_clash/soravpn_ui/screens/purchasing_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/plans_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/order_payment_screen.dart';
import 'package:fl_clash/soravpn_ui/widgets/subscription_renewal_dialog.dart';

/// 套餐信息卡片 - 参考 theme_website Profile.vue 布局
class SubscriptionCard extends StatelessWidget {
  final Subscription? subscription;
  final Future<void> Function()? onRefresh;
  // Ignoring user param for compatibility, or we can just remove it from Dashboard later
  final dynamic user;
  final VoidCallback? onNavigateToPlans;

  const SubscriptionCard({
    super.key,
    this.subscription,
    this.onRefresh,
    this.user,
    this.onNavigateToPlans,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return _buildEmptyCard(context);
    }

    final usedTraffic = subscription!.upload + subscription!.download;
    final totalTraffic = subscription!.traffic;
    final usedPercent = totalTraffic > 0
        ? ((usedTraffic / totalTraffic) * 100).clamp(0.0, 100.0)
        : 0.0;
    final remainingDays = subscription!.getExpireDays();
    final resetDays = subscription!.getResetDays();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部：套餐信息 + 按钮组
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 套餐图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3F3F46), Color(0xFF18181B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFBBF24),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),

                // 套餐名称和标签
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        subscription!.name,
                        style: const TextStyle(
                          color: AppTheme.textLightPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildTag(
                        icon: Icons.schedule_rounded,
                        text: '到期 $remainingDays 天',
                      ),
                      if (resetDays != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(
                          icon: Icons.refresh_rounded,
                          text: '$resetDays 天后重置',
                        ),
                      ],
                    ],
                  ),
                ),

                // 按钮组
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resetDays != null) ...[
                      _buildOutlineButton(
                        context: context,
                        icon: Icons.refresh_rounded,
                        label: '重置包',
                        onPressed: () => _handleBuyResetPack(context),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildOutlineButton(
                      context: context,
                      icon: Icons.swap_horiz_rounded,
                      label: '更换套餐',
                      onPressed: () {
                         if (onNavigateToPlans != null) {
                             onNavigateToPlans!();
                         } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PlansScreen(),
                              ),
                            );
                         }
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildPrimaryButton(
                      context: context,
                      icon: Icons.bolt_rounded,
                      label: '续费',
                      onPressed: () => _handleRenew(context),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 流量进度条
            Row(
              children: [
                // 流量文字
                Text(
                  '已用 ',
                  style: TextStyle(
                    color: AppTheme.textLightTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${_formatTrafficValue(usedTraffic)} ${_formatTrafficUnit(usedTraffic)}',
                  style: const TextStyle(
                    color: AppTheme.textLightPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' / ${_formatTrafficValue(totalTraffic)} ${_formatTrafficUnit(totalTraffic)}',
                  style: TextStyle(
                    color: AppTheme.textLightTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                // 进度条
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (usedPercent / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: usedPercent > 80
                                  ? [const Color(0xFFFB923C), const Color(0xFFEF4444)]
                                  : [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${usedPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppTheme.textLightTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5), // zinc-100
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF71717A)), // zinc-500
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF52525B), // zinc-600
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建轮廓按钮
  Widget _buildOutlineButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textLightPrimary,
        side: const BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 构建主要按钮
  Widget _buildPrimaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.primaryForeground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 处理续费 - 使用 SubscriptionRenewalDialog (Popup)
  Future<void> _handleRenew(BuildContext context) async {
    try {
      final plans = await PurchaseService.getPlans();
      final currentPlan = plans.firstWhere(
        (plan) => plan.id == subscription!.subscribeId,
        orElse: () => throw Exception('未找到对应的套餐'),
      );

      if (context.mounted) {
        showDialog(
           context: context,
           builder: (context) => SubscriptionRenewalDialog(
               plan: currentPlan, 
               userSubscribeId: subscription!.id,
           ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// 处理购买重置包
  Future<void> _handleBuyResetPack(BuildContext context) async {
    try {
      // 获取套餐列表
      final plans = await PurchaseService.getPlans();
      final currentPlan = plans.firstWhere(
        (plan) => plan.id == subscription!.subscribeId,
        orElse: () => throw Exception('未找到对应的套餐'),
      );

      // 检查是否有重置包价格
      if (currentPlan.resetPrice == null || currentPlan.resetPrice == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('当前套餐不支持购买重置包'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        return;
      }

      final resetPriceYuan = currentPlan.resetPrice! / 100.0;

      if (!context.mounted) return;

      // 显示确认对话框
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('购买重置包'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '重置包价格：¥${resetPriceYuan.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // amber-100
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)), // amber-300
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '您的套餐流量 ${subscription!.getResetDays() ?? 0} 天后会自动重置。如果不想等待，可购买此流量包立即重置流量，但不影响正常流量重置，且流量不会叠加。',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45309), // amber-700
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmBuyResetPack(context, currentPlan);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
              ),
              child: const Text('确认购买'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// 确认购买重置包
  Future<void> _confirmBuyResetPack(BuildContext context, Plan plan) async {
    try {
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在创建订单...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 获取支付方式列表
      final paymentMethods = await PurchaseService.getPaymentMethods();
      if (paymentMethods.isEmpty) {
        throw Exception('暂无可用的支付方式');
      }

      // 创建订单，period 使用 'reset_price'
      final xboardOrder = await PurchaseService.createOrder(
        planId: plan.id,
        period: 'reset_price',
      );

      // 转换为兼容的 Order 格式
      final order = Order(
        orderNo: xboardOrder.tradeNo,
        status: OrderStatus.pending,
        amount: xboardOrder.totalAmount,
        createdAt: xboardOrder.createdAt ?? 0,
      );

      if (!context.mounted) return;

      // 如果只有一个支付方式，直接跳转
      if (paymentMethods.length == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderPaymentScreen(
              order: order,
              paymentMethod: paymentMethods.first,
            ),
          ),
        );
      } else {
        // 显示支付方式选择对话框
        _showPaymentMethodDialog(context, order, paymentMethods);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建订单失败：${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// 显示支付方式选择对话框
  void _showPaymentMethodDialog(
    BuildContext context,
    Order order,
    List<PaymentMethod> paymentMethods,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择支付方式'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              return ListTile(
                leading: Icon(
                  _getPaymentIcon(method.platform ?? ''),
                  color: AppTheme.primary,
                ),
                title: Text(method.name),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderPaymentScreen(
                        order: order,
                        paymentMethod: method,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 获取支付方式图标
  IconData _getPaymentIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'alipay':
      case 'alipayf2f':
        return Icons.account_balance_wallet;
      case 'wechat':
      case 'wechatpay':
        return Icons.chat;
      case 'stripe':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  /// 格式化流量数值
  String _formatTrafficValue(int bytes) {
    if (bytes < 1024) return bytes.toString();
    if (bytes < 1024 * 1024) return (bytes / 1024).toStringAsFixed(1);
    if (bytes < 1024 * 1024 * 1024) {
      return (bytes / (1024 * 1024)).toStringAsFixed(1);
    }
    return (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
  }

  /// 格式化流量单位
  String _formatTrafficUnit(int bytes) {
    if (bytes < 1024) return 'B';
    if (bytes < 1024 * 1024) return 'KB';
    if (bytes < 1024 * 1024 * 1024) return 'MB';
    return 'GB';
  }

  /// 空卡片
  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textLightTertiary,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            '暂无有效套餐',
            style: TextStyle(
              color: AppTheme.textLightSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
               if (onNavigateToPlans != null) {
                   onNavigateToPlans!();
               } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlansScreen(),
                    ),
                  );
               }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            child: const Text('购买套餐'),
          ),
        ],
      ),
    );
  }
}
