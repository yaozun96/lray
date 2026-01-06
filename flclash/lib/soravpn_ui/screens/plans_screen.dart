import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/plan.dart';
import 'package:fl_clash/soravpn_ui/services/purchase_service.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/purchasing_screen.dart';

/// 套餐列表页面
class PlansScreen extends StatefulWidget {
  final int? renewalPlanId; // 续费时传入当前套餐ID

  const PlansScreen({
    super.key,
    this.renewalPlanId,
  });

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Plan> _plans = [];
  bool _isLoading = true;
  String? _error;
  int _selectedPeriod = 1; // 默认选择
  final Set<int> _expandedPlanIds = {}; // 跟踪哪些套餐的特性是展开的

  List<int> _periods = []; // 从后台数据动态获取

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plans = await PurchaseService.getPlans();

      // 按价格从高到低排序
      plans.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));

      // 从所有套餐的折扣列表中提取可用周期
      final periodsSet = <int>{};
      for (final plan in plans) {
        // Collect periods from new periods list if available
        if (plan.periods.isNotEmpty) {
          for (final period in plan.periods) {
            periodsSet.add(period.months);
          }
        } else {
          // Fallback to legacy discount logic
          for (final discount in plan.discounts) {
            periodsSet.add(discount.quantity);
          }
          // Default monthly is always available in legacy view
          periodsSet.add(1); 
        }
      }
      
      // Ensure at least monthly is present if we have no periods (shouldn't happen)
      if (periodsSet.isEmpty) periodsSet.add(1);

      // 周期按从大到小排序 (One-time/0 should probably be last or first? Usually last.)
      // Let's sort: 36, 24, 12, 6, 3, 1, 0 (if 0 is One-time)
      final periodsList = periodsSet.toList()..sort((a, b) => b.compareTo(a));

      setState(() {
        _plans = plans;
        _periods = periodsList;
        // 默认选择最久的周期
        if (periodsList.isNotEmpty) {
          _selectedPeriod = periodsList.first; // 最久的周期（已从大到小排序）
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // 标题栏
          _buildTitleBar(),

          // 主内容区域
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 标题栏
  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLightCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择适合您的套餐',
                  style: TextStyle(
                    color: AppTheme.textLightPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '（* 价格以 ${ConfigService.currencyUnit} 计价，包含消费税）',
                  style: const TextStyle(
                    color: AppTheme.textLightSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: _buildPeriodSelector(),
          ),
        ],
      ),
    );
  }

  /// 周期选择器
  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedPeriod = period;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.bgDarkest : AppTheme.bgLightSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.bgDarkest
                    : AppTheme.border,
                width: 1,
              ),
            ),
            child: Text(
              period == 1 ? '按月' : period == 3 ? '按季' : '按年',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textLightSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 主内容区域
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgDarkest),
            ),
            SizedBox(height: 16),
            Text(
              '加载套餐列表...',
              style: TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPlans,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return const Center(
        child: Text(
          '暂无可用套餐',
          style: TextStyle(
            color: AppTheme.textLightSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据宽度自适应列数
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: _plans.map((plan) {
              final width = crossAxisCount == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;

              return SizedBox(
                width: width,
                child: _buildPlanCard(plan),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// 套餐卡片
  Widget _buildPlanCard(Plan plan) {
    final price = plan.calculatePriceInYuan(_selectedPeriod);
    final monthlyPrice = price / _selectedPeriod;
    final discountPercent = plan.calculateDiscountPercent(_selectedPeriod);
    final features = plan.getFeatures();

    final isLongestPeriod = _periods.isNotEmpty && _selectedPeriod == _periods.first;
    final isRenewalPlan = widget.renewalPlanId != null && plan.id == widget.renewalPlanId;
    final shouldShowFeatured = isLongestPeriod && _plans.isNotEmpty && plan == _plans.first && !isRenewalPlan;
    final isExpanded = _expandedPlanIds.contains(plan.id);

    final badges = <Widget>[];
    if (isRenewalPlan) {
      badges.add(_buildPlanBadge('当前套餐', AppTheme.primary, Colors.white));
    } else if (shouldShowFeatured) {
      badges.add(_buildPlanBadge('最受欢迎', AppTheme.bgDarkest, Colors.white));
    }
    if (discountPercent != null) {
      badges.add(_buildPlanBadge('节省 $discountPercent%', AppTheme.error.withValues(alpha: 0.15), AppTheme.error));
    }

    final card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (shouldShowFeatured || isRenewalPlan)
              ? AppTheme.bgDarkest
              : AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          if (shouldShowFeatured || isRenewalPlan)
            BoxShadow(
              color: AppTheme.bgDarkest.withValues(alpha: 0.25),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badges.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges,
            ),
          if (badges.isNotEmpty) const SizedBox(height: 12),
          Text(
            plan.name,
            style: const TextStyle(
              color: AppTheme.textLightPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ConfigService.currencySymbol,
                style: const TextStyle(
                  color: AppTheme.textLightPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                price.toStringAsFixed(2),
                style: const TextStyle(
                  color: AppTheme.textLightPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _selectedPeriod == 1 ? '/ 月' : _selectedPeriod == 3 ? '/ 季' : '/ 年',
                style: const TextStyle(
                  color: AppTheme.textLightSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_selectedPeriod > 1) ...[
            const SizedBox(height: 4),
            Text(
              '月均 ${ConfigService.currencySymbol}${monthlyPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.textLightTertiary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPlanMetric(Icons.cloud_download_rounded, '每月流量', plan.formatTraffic()),
              _buildPlanMetric(Icons.speed_rounded, '连接速度', plan.formatSpeedLimit()),
              _buildPlanMetric(Icons.devices_rounded, '同时连接', plan.formatDeviceLimit()),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PurchasingScreen(
                      plan: plan,
                      initialQuantity: _selectedPeriod,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (shouldShowFeatured || isRenewalPlan) ? AppTheme.bgDarkest : AppTheme.bgLightSecondary,
                foregroundColor: (shouldShowFeatured || isRenewalPlan) ? Colors.white : AppTheme.textLightPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: (shouldShowFeatured || isRenewalPlan)
                        ? AppTheme.bgDarkest
                        : AppTheme.border,
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                isRenewalPlan ? '续费 ${plan.name}' : '获取 ${plan.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPlanIds.remove(plan.id);
                    } else {
                      _expandedPlanIds.add(plan.id);
                    }
                  });
                },
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.bgDarkest,
                  size: 20,
                ),
                label: Text(
                  isExpanded ? '收起特点' : '查看更多特点',
                  style: const TextStyle(
                    color: AppTheme.bgDarkest,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              crossFadeState:
                  isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              firstChild: Column(
                children: features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildPlanMetric(
                      Icons.check_circle_rounded,
                      feature.label,
                      '',
                      dense: true,
                      fullWidth: true,
                    ),
                  );
                }).toList(),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );

    return card;
  }

  Widget _buildPlanMetric(IconData icon, String label, String value,
      {bool dense = false, bool fullWidth = false}) {
    final hasBackground = !(dense && fullWidth);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 14,
        vertical: dense ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: hasBackground
            ? AppTheme.bgLightSecondary.withValues(alpha: dense ? 0.35 : 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: hasBackground
            ? Border.all(color: AppTheme.border)
            : null,
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 16 : 18, color: AppTheme.textLightSecondary),
          const SizedBox(width: 8),
          if (fullWidth)
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.textLightSecondary,
                  fontSize: dense ? 11 : 12,
                ),
              ),
            )
          else
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: dense ? 11 : 12,
              ),
            ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textLightPrimary,
                fontSize: dense ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String text, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getPlanDescription(Plan plan, List<PlanFeature> features) {
    if (features.isNotEmpty) {
      final text = features
          .take(3)
          .map((f) => f.label.trim())
          .where((label) => label.isNotEmpty)
          .join(' · ');
      if (text.isNotEmpty) {
        return text;
      }
    }

    final raw = plan.description?.trim();
    if (raw != null &&
        raw.isNotEmpty &&
        !(raw.startsWith('{') && raw.endsWith('}')) &&
        !(raw.startsWith('[') && raw.endsWith(']'))) {
      return raw;
    }

    return '高性能节点 · 智能分流 · 一键连线';
  }
}
