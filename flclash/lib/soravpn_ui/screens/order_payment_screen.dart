import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/order.dart';
import 'package:fl_clash/soravpn_ui/models/payment_method.dart';
import 'package:fl_clash/soravpn_ui/services/purchase_service.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/screens/main_layout.dart';

/// 订单支付页面
class OrderPaymentScreen extends StatefulWidget {
  final Order order;
  final PaymentMethod paymentMethod;
  final String? identifier; // 未登录用户的邮箱

  const OrderPaymentScreen({
    super.key,
    required this.order,
    required this.paymentMethod,
    this.identifier,
  });

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  late Order _order;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  bool _isCheckingStatus = false;
  String? _paymentUrl;
  String? _checkoutUrl; // 用于二维码或URL支付
  String? _checkoutType; // checkout响应的type字段（'url' 或 'qr'）
  Duration? _remainingTime; // 订单剩余时间
  bool _hasLaunchedPayment = false; // 是否已经自动打开过支付链接

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    print('[OrderPaymentScreen] Init with order: ${_order.toJson()}');
    print('[OrderPaymentScreen] Initial status: ${_order.status}, isPaid: ${_order.isPaid}, isBalance: ${widget.paymentMethod.isBalance}');
    _initPayment();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPayment() async {
    print('[OrderPaymentScreen] _initPayment started, isBalance: ${widget.paymentMethod.isBalance}');
    print('[OrderPaymentScreen] Payment method: ${widget.paymentMethod.toJson()}');
    print('[OrderPaymentScreen] isUrlType: ${widget.paymentMethod.isUrlType}, isQrType: ${widget.paymentMethod.isQrType}');

    // 如果订单已包含支付URL，直接使用
    if (_order.paymentUrl != null) {
      _paymentUrl = _order.paymentUrl;
      print('[OrderPaymentScreen] Set _paymentUrl from order: $_paymentUrl');
    }

    // 立即检查一次订单状态（内部会调用 getPaymentCheckout）
    await _checkOrderStatus();

    // 如果订单还未支付，开始轮询和倒计时
    if (!_order.isPaid) {
      _startPolling();
      _startCountdown();
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkOrderStatus();
    });
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_order.createdAt == 0) return;

    final createdTime = _order.createdAtDateTime;
    final expireTime = createdTime.add(const Duration(minutes: 15));
    final now = DateTime.now();
    final remaining = expireTime.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      setState(() {
        _remainingTime = null;
      });
      _countdownTimer?.cancel();
      return;
    }

    setState(() {
      _remainingTime = remaining;
    });
  }

  String _getCountdownText() {
    if (_remainingTime == null) return '支付时间已过';

    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes.remainder(60);
    final seconds = _remainingTime!.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _checkOrderStatus() async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      print('[OrderPaymentScreen] Checking order status for: ${_order.orderNo}');
      final order = await PurchaseService.getOrderStatus(
        orderNo: _order.orderNo,
        identifier: widget.identifier,
      );

      print('[OrderPaymentScreen] Order status check result: ${order.toJson()}');
      print('[OrderPaymentScreen] Status: ${order.status}, isPaid: ${order.isPaid}');

      setState(() {
        _order = order;
        _isCheckingStatus = false;
      });

      // 如果订单已支付或已关闭，停止轮询和倒计时
      if (order.isPaid || order.isClosed) {
        print('[OrderPaymentScreen] Order completed, stopping polling');
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        if (order.isPaid) {
          _handlePaymentSuccess();
        }
      } else {
        // 订单还是待支付状态，调用 ORDER_CHECKOUT
        // 参考网站实现：PurchasingOrderContent.vue:335-355
        // 网站在每次轮询时都会调用此接口，这可能触发后端处理余额支付
        try {
          print('[OrderPaymentScreen] Order still pending, calling getPaymentCheckout');
          final checkout = await PurchaseService.getPaymentCheckout(
            orderNo: _order.orderNo,
          );
          print('[OrderPaymentScreen] Payment checkout response: $checkout');

          if (checkout['payment_url'] != null || checkout['checkout_url'] != null) {
            final checkoutUrl = checkout['checkout_url'] ?? checkout['payment_url'];
            final checkoutType = checkout['type'] as String?;
            print('[OrderPaymentScreen] Got checkout URL: $checkoutUrl');
            print('[OrderPaymentScreen] Checkout type: $checkoutType');

            setState(() {
              _checkoutUrl = checkoutUrl;
              _checkoutType = checkoutType;
              // 如果是URL类型支付，设置_paymentUrl
              if (_checkoutType == 'url' && _paymentUrl == null) {
                _paymentUrl = _checkoutUrl;
                print('[OrderPaymentScreen] Set _paymentUrl to: $_paymentUrl');
              }
            });

            // 如果是URL类型支付，且还没有自动打开过，则自动打开浏览器
            if (_checkoutType == 'url' && !_hasLaunchedPayment) {
              _hasLaunchedPayment = true;
              print('[OrderPaymentScreen] Auto-launching payment URL...');
              // 使用 Future.delayed 确保 setState 完成后再打开浏览器
              Future.delayed(const Duration(milliseconds: 100), () {
                _launchPaymentUrl();
              });
            }
          }
        } catch (e) {
          print('[OrderPaymentScreen] Get payment checkout error: $e');
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
      });
      print('[OrderPaymentScreen] Check order status error: $e');
    }
  }

  Future<void> _handlePaymentSuccess() async {
    // 如果订单包含token（新用户注册），自动登录
    if (_order.token != null && _order.token!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _order.token!);
        if (widget.identifier != null) {
          await prefs.setString(
            'user_data',
            jsonEncode({'email': widget.identifier}),
          );
        }
      } catch (e) {
        print('Auto login error: $e');
      }
    }

    // 显示成功提示并跳转到主页
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
              SizedBox(width: 12),
              Text('支付成功'),
            ],
          ),
          content: const Text('您的订阅已激活，感谢您的支持！'),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭对话框
                Navigator.of(context).pop();
                // 清除所有页面并跳转到主布局（包含侧边栏和仪表盘）
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainLayout()),
                  (route) => false,
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchPaymentUrl() async {
    print('[OrderPaymentScreen] _launchPaymentUrl called, _paymentUrl: $_paymentUrl');
    if (_paymentUrl == null) {
      print('[OrderPaymentScreen] _paymentUrl is null, returning');
      return;
    }

    try {
      final uri = Uri.parse(_paymentUrl!);
      print('[OrderPaymentScreen] Parsed URI: $uri');

      final canLaunch = await canLaunchUrl(uri);
      print('[OrderPaymentScreen] canLaunchUrl result: $canLaunch');

      if (canLaunch) {
        print('[OrderPaymentScreen] Launching URL in external browser...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[OrderPaymentScreen] URL launched successfully');
      } else {
        print('[OrderPaymentScreen] Cannot launch URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开支付链接'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      print('[OrderPaymentScreen] Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开支付链接失败: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
          const Spacer(),
          _buildBackButton(),
        ],
      ),
    );
  }

  /// 主内容区域
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              // 状态图标
              _buildStatusIcon(),
              const SizedBox(height: 8),

              // 状态文本
              _buildStatusText(),
              const SizedBox(height: 12),

              // 订单信息
              _buildOrderInfo(),
              const SizedBox(height: 12),

              // 操作按钮
              _buildActionButtons(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
          color: AppTheme.bgLightSecondary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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

  /// 状态图标
  Widget _buildStatusIcon() {
    if (_order.isPaid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.success,
          size: 36,
        ),
      );
    } else if (_order.isClosed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel_rounded,
          color: AppTheme.error,
          size: 36,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkest.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.payment_rounded,
          color: AppTheme.bgDarkest,
          size: 36,
        ),
      );
    }
  }

  /// 状态文本
  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _order.status.label,
          style: const TextStyle(
            color: AppTheme.textLightPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // 显示倒计时（仅在待支付状态下）
        if (!_order.isPaid && !_order.isClosed) ...[
          Text(
            _getCountdownText(),
            style: const TextStyle(
              color: AppTheme.textLightSecondary,
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          _getStatusDescription(),
          style: const TextStyle(
            color: AppTheme.textLightSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStatusDescription() {
    if (_order.isPaid) {
      return '您的订阅已成功激活';
    } else if (_order.isClosed) {
      return '订单已关闭或取消';
    } else {
      return '请完成支付以激活订阅';
    }
  }

  /// 订单信息
  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildInfoRow('订单号', _order.orderNo),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          _buildInfoRow('支付方式', widget.paymentMethod.name),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          _buildInfoRow(
            '订单金额',
            '¥${_order.amountInYuan.toStringAsFixed(2)}',
            valueColor: AppTheme.bgDarkest,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool valueBold = false}) {
    return Row(
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
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textLightPrimary,
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 操作按钮
  Widget _buildActionButtons() {
    if (_order.isPaid) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('完成', style: TextStyle(fontSize: 16)),
        ),
      );
    } else if (_order.isClosed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.bgLight,
            foregroundColor: AppTheme.textLightPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
          child: const Text('返回', style: TextStyle(fontSize: 16)),
        ),
      );
    } else {
      return Column(
        children: [
          // QR码支付：显示二维码（根据checkout响应的type判断）
          if (_checkoutType == 'qr' && _checkoutUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: QrImageView(
                data: _checkoutUrl!,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '请使用支付宝或微信扫码支付',
              style: TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // URL支付：前往支付按钮（根据checkout响应的type判断）
          if (_checkoutType == 'url' && _paymentUrl != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _launchPaymentUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('前往支付', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 刷新订单状态按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _checkOrderStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textLightPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: _isCheckingStatus
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgDarkest),
                      ),
                    )
                  : const Text('刷新订单状态', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
    }
  }
}
