import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/plan.dart';
import 'package:fl_clash/soravpn_ui/models/payment_method.dart';
import 'package:fl_clash/soravpn_ui/models/order.dart';
import 'package:fl_clash/soravpn_ui/services/purchase_service.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/order_payment_screen.dart';

/// 购买详情页面
class PurchasingScreen extends StatefulWidget {
  final Plan plan;
  final int initialQuantity;
  final int? userSubscribeId; // 如果是续费，传入用户订阅ID
  final bool isRenewal; // 是否为续费模式

  const PurchasingScreen({
    super.key,
    required this.plan,
    this.initialQuantity = 1,
    this.userSubscribeId,
    this.isRenewal = false,
  });

  @override
  State<PurchasingScreen> createState() => _PurchasingScreenState();
}

class _PurchasingScreenState extends State<PurchasingScreen> {
  late PlanPeriod _selectedPeriod;
  List<PaymentMethod> _paymentMethods = [];
  List<PaymentMethod> _rawPaymentMethods = []; // 保存原始支付方式列表
  PaymentMethod? _selectedPaymentMethod;
  OrderPreview? _orderPreview;
  bool _isLoadingPaymentMethods = true;
  bool _isLoadingPreview = false;
  bool _isPurchasing = false;
  String? _error;

  // 未登录用户的表单
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  // 优惠码输入框显示状态
  bool _showCouponInput = false;
  bool _isLoggedIn = false;

  // 优惠码验证状态
  String? _couponMessage;
  bool _couponSuccess = false;

  // 用户余额（元）
  double _userBalance = 0;

  @override
  void initState() {
    super.initState();
    _initSelectedPeriod();
    _initPage();
  }

  void _initSelectedPeriod() {
    // Determine initial period based on initialQuantity or availability
    if (widget.plan.periods.isNotEmpty) {
      // Try to find matching period for initialQuantity
      try {
        _selectedPeriod = widget.plan.periods.firstWhere(
          (p) => p.months == widget.initialQuantity && !p.isOnetime, 
          orElse: () => widget.plan.periods.first
        );
      } catch (e) {
        _selectedPeriod = widget.plan.periods.first;
      }
    } else {
      // Fallback if no periods defined (should not happen with new logic, but safe default)
      _selectedPeriod = PlanPeriod(
        key: 'month_price', 
        name: '月付', 
        price: widget.plan.unitPrice, 
        months: 1
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      final userData = await AuthService.getUserData();
      if (userData != null && userData['email'] != null) {
        _emailController.text = userData['email'];
      }
    }
    await _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
      _error = null;
    });

    try {
      final methods = await PurchaseService.getPaymentMethods();

      // 获取用户余额（如果已登录）
      if (_isLoggedIn) {
        try {
          // 从服务器获取最新用户信息（包括余额）
          final userInfo = await AuthService.getUserInfo();
          print('[PurchasingScreen] User info: $userInfo');

          if (userInfo['balance'] != null) {
            _userBalance = (userInfo['balance'] as num).toDouble() / 100; // 转换为元
            print('[PurchasingScreen] User balance: $_userBalance yuan');
          }
        } catch (e) {
          print('[PurchasingScreen] Failed to get user info: $e');
          // 如果获取失败，继续处理但余额为0
        }
      }

      setState(() {
        _rawPaymentMethods = methods;
        _isLoadingPaymentMethods = false;
      });

      // 根据当前订单金额更新支付方式状态
      _updatePaymentMethodsWithBalance();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPaymentMethods = false;
      });
    }
  }

  /// 根据当前订单金额更新支付方式的余额状态
  void _updatePaymentMethodsWithBalance({bool updatePreview = true}) {
    if (_rawPaymentMethods.isEmpty) return;

    // 获取当前订单总价
    final orderAmount = _orderPreview?.totalAmountInYuan ?? _selectedPeriod.priceYuan;
    print('[PurchasingScreen] Order amount: $orderAmount yuan, User balance: $_userBalance yuan');

    // 检查Balance支付方式是否余额不足
    final processedMethods = _rawPaymentMethods.map((method) {
      if (method.isBalance && _isLoggedIn) {
        // 如果余额不足，禁用该支付方式
        if (_userBalance < orderAmount) {
          return PaymentMethod(
            id: method.id,
            name: method.name,
            platform: method.platform,
            icon: method.icon,
            type: method.type,
            disabled: true,
            disabledReason: '余额不足（当前余额: ${ConfigService.currencySymbol}${_userBalance.toStringAsFixed(2)}）',
          );
        }
      }
      return method;
    }).toList();

    setState(() {
      _paymentMethods = processedMethods;

      // 如果当前选择的支付方式被禁用，则选择第一个可用的
      if (_selectedPaymentMethod != null && _selectedPaymentMethod!.disabled) {
        final firstAvailable = processedMethods.firstWhere(
          (m) => !m.disabled,
          orElse: () => processedMethods.first,
        );
        _selectedPaymentMethod = firstAvailable;
      } else if (_selectedPaymentMethod == null && processedMethods.isNotEmpty) {
        // 首次加载，选择第一个未禁用的支付方式
        _selectedPaymentMethod = processedMethods.firstWhere(
          (m) => !m.disabled,
          orElse: () => processedMethods.first,
        );
      }
    });

    // 更新预览（如果需要）
    if (updatePreview && _selectedPaymentMethod != null) {
      _updatePreview();
    }
  }

  Future<void> _updatePreview() async {
    if (_selectedPaymentMethod == null) return;

    setState(() {
      _isLoadingPreview = true;
      _couponMessage = null; // 清除之前的消息
    });

    try {
      final preview = await PurchaseService.getOrderPreview(
        subscribeId: widget.plan.id,
        payment: _selectedPaymentMethod!.id,
        quantity: _selectedPeriod.months, // Legacy fallback
        period: _selectedPeriod.key,      // New explicit period key
        coupon: _couponController.text.trim(),
        identifier: _isLoggedIn ? null : _emailController.text.trim(),
      );

      setState(() {
        _orderPreview = preview;
        _isLoadingPreview = false;

        // 如果有优惠码且验证成功，显示成功提示
        if (_couponController.text.trim().isNotEmpty && preview.couponDiscountInYuan > 0) {
          _couponMessage = '优惠码已应用，优惠 ${ConfigService.currencySymbol}${preview.couponDiscountInYuan.toStringAsFixed(2)}';
          _couponSuccess = true;
        } else if (_couponController.text.trim().isNotEmpty) {
          // 有优惠码但没有优惠（可能是不适用）
          _couponMessage = null;
          _couponSuccess = false;
        }
      });

      // 订单预览更新后，重新检查余额状态（因为总价可能因优惠码等因素改变）
      // updatePreview=false 避免循环调用
      _updatePaymentMethodsWithBalance(updatePreview: false);
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;

        // 显示错误提示
        if (_couponController.text.trim().isNotEmpty) {
          _couponMessage = '优惠码无效或已过期';
          _couponSuccess = false;
        }
      });

      print('[PurchasingScreen] Preview error: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPaymentMethod == null) {
      _showError('请选择支付方式');
      return;
    }

    if (!_isLoggedIn && _emailController.text.trim().isEmpty) {
      _showError('请输入邮箱地址');
      return;
    }

    // 续费模式必须已登录
    if (widget.isRenewal && !_isLoggedIn) {
      _showError('续费需要登录账号');
      return;
    }

    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      late final Order order;

      if (widget.isRenewal) {
        // 续费模式：调用续费API
        print('[PurchasingScreen] Starting renewal - userSubscribeId: ${widget.userSubscribeId}, payment_id: ${_selectedPaymentMethod!.id}, period: ${_selectedPeriod.key}');

        order = await PurchaseService.renewSubscription(
          userSubscribeId: widget.userSubscribeId!,
          payment: _selectedPaymentMethod!.id,
          quantity: _selectedPeriod.months,
          coupon: _couponController.text.trim(),
          period: _selectedPeriod.key,
        );

        print('[PurchasingScreen] Renewal completed - Order: ${order.toJson()}');
      } else {
        // 购买模式：调用购买API
        print('[PurchasingScreen] Starting purchase - payment_id: ${_selectedPaymentMethod!.id}, isBalance: ${_selectedPaymentMethod!.isBalance}, period: ${_selectedPeriod.key}');

        order = await PurchaseService.purchase(
          subscribeId: widget.plan.id,
          payment: _selectedPaymentMethod!.id,
          quantity: _selectedPeriod.months,
          coupon: _couponController.text.trim(),
          identifier: _isLoggedIn ? null : _emailController.text.trim(),
          password: _isLoggedIn ? null : _passwordController.text,
          period: _selectedPeriod.key,
        );

        print('[PurchasingScreen] Purchase completed - Order: ${order.toJson()}');
      }

      print('[PurchasingScreen] Order status: ${order.status}, orderNo: ${order.orderNo}');

      setState(() {
        _isPurchasing = false;
      });

      // 跳转到订单支付页面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderPaymentScreen(
              order: order,
              paymentMethod: _selectedPaymentMethod!,
              identifier: _isLoggedIn ? null : _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
        _error = e.toString();
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(height: 10, color: AppTheme.bgLightCard),
            // 标题栏
            _buildTitleBar(),

            // 主内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// 标题栏
  Widget _buildTitleBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLightCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.isRenewal ? '续费' : '购买套餐',
            style: const TextStyle(
              color: AppTheme.textLightPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildBackButton(),
        ],
      ),
    );
  }

  /// 主内容区域
  Widget _buildContent() {
    if (_isLoadingPaymentMethods) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgDarkest),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：表单区域
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 账户信息（仅未登录用户）
                if (!_isLoggedIn) ...[
                  _buildAccountSection(),
                  const SizedBox(height: 12),
                ],

                // 购买时长选择
                _buildDurationSelector(),
                const SizedBox(height: 12),

                // 优惠码
                _buildCouponSection(),
                const SizedBox(height: 12),

                // 支付方式选择
                _buildPaymentMethodSection(),
              ],
            ),
          ),
        ),

        // 右侧：价格预览
        Container(
          width: 360,
          decoration: const BoxDecoration(
            color: AppTheme.bgLightCard,
            border: Border(
              left: BorderSide(color: AppTheme.border, width: 1),
            ),
          ),
          child: _buildPricePreview(),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    void handleBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).maybePop();
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: handleBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgLightSecondary.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back_rounded, color: AppTheme.textLightPrimary, size: 18),
            SizedBox(width: 6),
            Text(
              '返回',
              style: TextStyle(
                color: AppTheme.textLightPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 购买时长选择
  Widget _buildDurationSelector() {
    // If we have periods, use them. Otherwise show placeholder or error.
    if (widget.plan.periods.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '购买时长',
          style: TextStyle(
            color: AppTheme.textLightPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.plan.periods.map((period) {
            final isSelected = _selectedPeriod.key == period.key;
            // Calculate discount for display if applicable
            // For now, rely on plan's discount list if it's not one-time
            int? discountPercent;
            if (!period.isOnetime && period.months > 0) {
               discountPercent = widget.plan.calculateDiscountPercent(period.months);
            }

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                // 重新检查余额状态
                _updatePaymentMethodsWithBalance();
                // 注意：_updatePaymentMethodsWithBalance() 会自动调用 _updatePreview()
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 160,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.muted : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: !isSelected ? [
                    const BoxShadow(
                      color: AppTheme.border,
                      blurRadius: 0,
                      spreadRadius: 0.5,
                      offset: Offset(0, 0),
                    ),
                  ] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          period.name,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryDark : AppTheme.textLightPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (discountPercent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountPercent%',
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period.formattedPrice,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryDark : AppTheme.textLightPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 账户信息部分
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '账户信息',
          style: TextStyle(
            color: AppTheme.textLightPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '邮箱地址',
            hintText: '请输入邮箱地址',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: '密码（可选）',
            hintText: '留空则系统自动生成密码',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 8),
        const Text(
          '提示：首次购买会自动创建账户',
          style: TextStyle(
            color: AppTheme.textLightTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 支付方式选择
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '支付方式',
          style: TextStyle(
            color: AppTheme.textLightPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...(_paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod?.id == method.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: method.disabled
                  ? null
                  : () {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                      _updatePreview();
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: method.disabled
                      ? AppTheme.bgLightCard.withValues(alpha: 0.5)
                      : (isSelected ? AppTheme.muted : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: !isSelected && !method.disabled ? [
                    const BoxShadow(
                      color: AppTheme.border,
                      blurRadius: 0,
                      spreadRadius: 0.5,
                      offset: Offset(0, 0),
                    ),
                  ] : null,
                ),
                child: Row(
                  children: [
                    // 支付方式图标：优先使用网络图标，否则使用默认图标
                    if (method.icon != null && method.icon!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          method.icon!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // 加载失败时显示默认图标
                            return Icon(
                              method.isBalance
                                  ? Icons.account_balance_wallet_rounded
                                  : Icons.payment_rounded,
                              color: method.disabled
                                  ? AppTheme.textLightTertiary
                                  : (isSelected ? AppTheme.primaryDark : AppTheme.textLightSecondary),
                              size: 24,
                            );
                          },
                        ),
                      )
                    else
                      Icon(
                        method.isBalance
                            ? Icons.account_balance_wallet_rounded
                            : Icons.payment_rounded,
                        color: method.disabled
                            ? AppTheme.textLightTertiary
                            : (isSelected ? AppTheme.primaryDark : AppTheme.textLightSecondary),
                        size: 24,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                method.name,
                                style: TextStyle(
                                  color: method.disabled
                                      ? AppTheme.textLightTertiary
                                      : (isSelected ? AppTheme.primaryDark : AppTheme.textLightPrimary),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (method.isBalance && _isLoggedIn) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.primary.withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '余额: ${ConfigService.currencySymbol}${_userBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (method.disabled && method.disabledReason != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              method.disabledReason!,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 12,
                                ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.bgDarkest,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }

  /// 优惠码部分
  Widget _buildCouponSection() {
    if (!_showCouponInput) {
      // 折叠状态：显示"有优惠码？"按钮
      return TextButton.icon(
        onPressed: () {
          setState(() {
            _showCouponInput = true;
          });
        },
        icon: const Icon(
          Icons.confirmation_number_outlined,
          size: 18,
          color: AppTheme.bgDarkest,
        ),
        label: const Text(
          '有优惠码？',
          style: TextStyle(
            color: AppTheme.bgDarkest,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // 展开状态：显示完整的优惠码输入框
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '优惠码（可选）',
              style: TextStyle(
                color: AppTheme.textLightPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            // 收起按钮
            TextButton(
              onPressed: () {
                setState(() {
                  _showCouponInput = false;
                  _couponMessage = null;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '收起',
                style: TextStyle(
                  color: AppTheme.textLightSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: const InputDecoration(
                  hintText: '请输入优惠码',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // 清除验证消息当用户修改优惠码时
                  if (_couponMessage != null) {
                    setState(() {
                      _couponMessage = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoadingPreview ? null : _updatePreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('应用'),
            ),
          ],
        ),
        // 验证消息
        if (_couponMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _couponSuccess
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _couponSuccess
                    ? AppTheme.success.withValues(alpha: 0.3)
                    : AppTheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _couponSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 16,
                  color: _couponSuccess ? AppTheme.success : AppTheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _couponMessage!,
                    style: TextStyle(
                      color: _couponSuccess ? AppTheme.success : AppTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 价格预览
  Widget _buildPricePreview() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品详情
          const Text(
            '商品详情',
            style: TextStyle(
              color: AppTheme.textLightPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgLightSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 套餐名称和数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.plan.name,
                        style: const TextStyle(
                          color: AppTheme.textLightPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _selectedPeriod.isOnetime 
                          ? '一次性' 
                          : 'x ${_selectedPeriod.months} ${widget.plan.formatUnitTime()}',
                      style: const TextStyle(
                        color: AppTheme.textLightSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 10),

                // 套餐信息
                _buildPlanDetailItem(Icons.cloud_download_rounded, '每月流量', widget.plan.formatTraffic()),
                const SizedBox(height: 8),
                _buildPlanDetailItem(Icons.speed_rounded, '连接速度', widget.plan.formatSpeedLimit()),
                const SizedBox(height: 8),
                _buildPlanDetailItem(Icons.devices_rounded, '同时连接', widget.plan.formatDeviceLimit()),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 商品账单
          const Text(
            '商品账单',
            style: TextStyle(
              color: AppTheme.textLightPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // 价格明细
          if (_orderPreview != null) ...[
            _buildPriceItem('价格', _orderPreview!.priceInYuan),
            _buildPriceItem('商品折扣', -_orderPreview!.productDiscountInYuan, isDiscount: true),
            _buildPriceItem('折扣码优惠', -_orderPreview!.couponDiscountInYuan, isDiscount: true),
            _buildPriceItem('手续费', _orderPreview!.feeAmountInYuan),
            _buildPriceItem('赠金抵扣', -_orderPreview!.giftAmountInYuan, isDiscount: true),
            const SizedBox(height: 10),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '总价',
                  style: TextStyle(
                    color: AppTheme.textLightPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${ConfigService.currencySymbol}${_orderPreview!.totalAmountInYuan.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.bgDarkest,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '（* 价格以 ${ConfigService.currencyUnit} 计价，包含消费税）',
              style: const TextStyle(
                color: AppTheme.textLightTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ] else if (_isLoadingPreview) ...[
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgDarkest),
              ),
            ),
          ] else ...[
            // 使用计算的价格
            Builder(
              builder: (context) {
                final price = _selectedPeriod.priceYuan; // Use period price directly
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '总计',
                          style: TextStyle(
                            color: AppTheme.textLightPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${ConfigService.currencySymbol}${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.bgDarkest,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '（* 价格以 ${ConfigService.currencyUnit} 计价，包含消费税）',
                      style: const TextStyle(
                        color: AppTheme.textLightTertiary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // 购买按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '立即购买',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// 价格项
  Widget _buildPriceItem(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textLightSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}${ConfigService.currencySymbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount ? AppTheme.success : AppTheme.textLightPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 套餐详情项
  Widget _buildPlanDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.bgDarkest.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textLightSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLightPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
