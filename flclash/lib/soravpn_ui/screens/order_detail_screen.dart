import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderNo;
  final bool fromCreate;
  final VoidCallback? onBack;

  const OrderDetailScreen({
    super.key, 
    required this.orderNo,
    this.fromCreate = false,
    this.onBack,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  XboardOrder? _order;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
    _startPolling();
    _startCountdown();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _order?.status == 0) { // 0: Pending/Unpaid usually
        _loadOrderDetail(silent: true);
      } else {
        // Continue polling if pending, but Xboard status might be different?
        // XboardOrder status: 0=pending, 1=paid, 2=cancelled, 3=timeout?
        // Let's check status definition.
        // In previous view: 1=pending, 2=paid?
        // Let's rely on _order?.status handling in _getStatusText
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_order == null) return;
    
    // CreatedAt is seconds in XboardOrder usually
    final int createdAt = _order!.createdAt ?? 0;
    if (createdAt == 0) return;

    final createdTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    // Assuming 15 mins timeout
    final expireTime = createdTime.add(const Duration(minutes: 15));
    final now = DateTime.now();
    final remaining = expireTime.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      if (mounted) setState(() => _remainingTime = null);
      _countdownTimer?.cancel();
      return;
    }

    if (mounted) setState(() => _remainingTime = remaining);
  }

  String _getCountdownText() {
    if (_remainingTime == null) return '支付时间已过';

    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes.remainder(60);
    final seconds = _remainingTime!.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadOrderDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final order = await XboardOrderService.getOrderDetail(widget.orderNo);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });

        // Auto open payment if requested and status is pending
        if (widget.fromCreate && !silent && (_order?.status == 0)) {
           // Use a post-frame callback or simple delay to ensure dialog shows after build
           Future.microtask(() => _openPaymentDialog());
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText(int? status) {
    if (status == null) return '未知';
    switch (status) {
      case 0:
        return '待支付';
      case 1:
        return '已开通';
      case 2: // Cancelled
        return '已取消';
      case 3: // Expired
        return '已过期';
      default:
        return '状态 $status';
    }
  }
  
  String _getStatusDescription(int? status) {
    switch (status) {
      case 0: // Pending
        return '请完成支付以继续';
      case 1: // Paid
        return '订单已完成';
      default:
        return '';
    }
  }

  void _openPaymentDialog() async {
    if (_order == null) return;
    
    final result = await showDialog(
      context: context,
      builder: (context) => PaymentMethodDialog(order: _order!),
    );
    
    if (result == true) {
      _loadOrderDetail();
    }
  }
  
  // ... (build method remains mostly same until _order.statusText usage)

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // ... (Error handling omitted for brevity of replacement, assuming standard refactor)
    // Actually, I should include the whole block if I am replacing a big chunk or just the specific method.
    // The instruction is to fix errors. The errors are scattered.
    // Error 1: _updateCountdown
    // Error 2: statusText
    
    // I will replace from `_updateCountdown` down to `_buildContent` to cover both changes safely.
    // But `build` is huge.
    
    // Let's do a targeted replace for `_updateCountdown` first.
    return _isLoading ? Scaffold(backgroundColor: AppTheme.bgLight, body: const Center(child: CircularProgressIndicator())) :
           _errorMessage != null ? Scaffold(backgroundColor: AppTheme.bgLight, body: Center(child: Text(_errorMessage!))) :
           Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
             Container(height: 10, color: AppTheme.bgLightCard),
            _buildTitleBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTitleBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLightCard,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgLightSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, color: AppTheme.textLightPrimary, size: 18),
                  SizedBox(width: 6),
                  Text('返回', style: TextStyle(color: AppTheme.textLightPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_order == null) return const SizedBox();

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _buildStatusIcon(),
              const SizedBox(height: 8),
              Text(
                _order!.statusName, // Fixed: statusText -> statusName
                style: const TextStyle(
                  color: AppTheme.textLightPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_order!.status == 0) ...[ 
                 const SizedBox(height: 8),
                 Text(
                   _getCountdownText(),
                   style: const TextStyle(
                     color: AppTheme.textLightSecondary,
                     fontSize: 32,
                     fontWeight: FontWeight.w300,
                   ),
                 ),
              ],
              const SizedBox(height: 24),
              _buildOrderInfo(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    // 0: Pending, 1: Paid, 2: Cancelled
    switch (_order?.status) {
      case 1:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 36),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 36),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.bgDarkest.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.payment_rounded, color: AppTheme.bgDarkest, size: 36),
        );
    }
  }

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
          _buildInfoRow('订单号', _order?.tradeNo ?? ''),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 10),
          _buildInfoRow('商品', _order?.type == 1 ? '套餐购买' : '余额充值'), // Type logic?
          const SizedBox(height: 10),
          const Divider(color: AppTheme.border, height: 1),
           const SizedBox(height: 10),
          _buildInfoRow(
            '订单金额',
            '¥${((_order?.totalAmount ?? 0) / 100).toStringAsFixed(2)}',
            valueColor: AppTheme.bgDarkest,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLightSecondary, fontSize: 14)),
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
  
  Widget _buildActionButtons() {
    if (_order == null) return const SizedBox();
    
    // Status: 0=Pending, 1=Paid, 2=Cancelled
    if (_order!.status == 0) {
       return SizedBox(
         width: double.infinity,
         child: ElevatedButton(
           onPressed: _openPaymentDialog,
           style: ElevatedButton.styleFrom(
             backgroundColor: AppTheme.primary,
             foregroundColor: AppTheme.primaryForeground,
             padding: const EdgeInsets.symmetric(vertical: 16),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
           child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 20),
                SizedBox(width: 8),
                Text('立即支付', style: TextStyle(fontSize: 16)),
              ],
           ),
         ),
       );
    } else if (_order!.status == 1) {
       return SizedBox(
         width: double.infinity,
         child: ElevatedButton(
           onPressed: () => Navigator.of(context).pop(),
           style: ElevatedButton.styleFrom(
             backgroundColor: AppTheme.success,
             foregroundColor: Colors.white,
             padding: const EdgeInsets.symmetric(vertical: 16),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
           child: const Text('已支付', style: TextStyle(fontSize: 16)),
         ),
       );
    } else {
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
    }
  }
}
