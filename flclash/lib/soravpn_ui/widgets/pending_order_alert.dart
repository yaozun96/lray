import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';

class PendingOrderAlert extends StatefulWidget {
  final VoidCallback? onNavigateToOrderList;

  const PendingOrderAlert({
    super.key, 
    this.onNavigateToOrderList,
  });

  @override
  State<PendingOrderAlert> createState() => _PendingOrderAlertState();
}

class _PendingOrderAlertState extends State<PendingOrderAlert> {
  bool _isVisible = false;
  XboardOrder? _pendingOrder;

  @override
  void initState() {
    super.initState();
    _checkPendingOrders();
    XboardOrderService.orderUpdateNotifier.addListener(_checkPendingOrders);
  }

  @override
  void dispose() {
    XboardOrderService.orderUpdateNotifier.removeListener(_checkPendingOrders);
    super.dispose();
  }

  Future<void> _checkPendingOrders() async {
    try {
      final orders = await XboardOrderService.getOrders();
      final pendingOrders = orders.where((o) => o.status == 0).toList();
      
      if (mounted) {
        setState(() {
          if (pendingOrders.isNotEmpty) {
            _pendingOrder = pendingOrders.first;
            _isVisible = true;
          } else {
            _pendingOrder = null;
            _isVisible = false;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
           _isVisible = false; 
        });
      }
    }
  }

  void _openPaymentDialog(XboardOrder order) async {
    final result = await showDialog(
      context: context,
      builder: (_) => PaymentMethodDialog(order: order),
    );
    
    // If result is true (user said "I have paid" or redirection callback), hide immediately
    if (result == true && mounted) {
        setState(() {
            _isVisible = false;
            _pendingOrder = null;
        });
        // Then perform a background check to confirm
        _checkPendingOrders();
    } else {
        // Otherwise just refresh
        _checkPendingOrders();
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    // Optimistic Update: Hide immediately
    if (mounted) {
        setState(() {
            _isVisible = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在取消...'), duration: Duration(milliseconds: 500)),
        );
    }
    
    try {
      final msg = await XboardOrderService.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        // Re-check to be safe, but we expect it to be gone
        _checkPendingOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取消失败: $e')));
        // If failed, show it again
        _checkPendingOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _pendingOrder == null) return const SizedBox.shrink();

    final order = _pendingOrder!;

    // Slim, Single-Line Capsule Design
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light Orange Background
        borderRadius: BorderRadius.circular(30), // Capsule Shape
        border: Border.all(color: const Color(0xFFFFCC80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 18),
            const SizedBox(width: 8),

            // Text Info (Flexible)
            Flexible(
              child: InkWell(
                onTap: widget.onNavigateToOrderList,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: order.type == 5 ? "余额充值" : (order.plan?.name ?? "未知套餐"),
                        style: const TextStyle(
                          color: Color(0xFFBF360C),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(text: '  '),
                       TextSpan(
                        text: '¥${order.actualAmountYuan.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ]
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Cancel Button (Compact)
            SizedBox(
              height: 28,
              width: 48,
              child: TextButton(
                onPressed: () => _cancelOrder(order.tradeNo),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFBF360C),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12)
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 4),

            // Action Button (Compact)
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _openPaymentDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                ),
                child: const Text('去支付'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
