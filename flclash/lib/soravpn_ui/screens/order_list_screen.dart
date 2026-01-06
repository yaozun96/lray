import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/order_service.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/screens/order_screen.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';

class OrderListScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? initialOrderNo;
  final bool autoPay;
  final VoidCallback? onBack;
  final bool showTitle;

  const OrderListScreen({
    super.key, 
    this.isEmbedded = false,
    this.initialOrderNo,
    this.autoPay = false,
    this.onBack,
    this.showTitle = true,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _isLoading = true;
  List<XboardOrder> _orders = [];
  bool _hasAutoPaid = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_orders.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      const pageSize = 10;
      final orders = await XboardOrderService.getOrders(page: _page, pageSize: pageSize);
      // Sort by created time desc
      orders.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
      if (mounted) {
        setState(() {
          if (_page == 1) {
            _orders = orders;
          } else {
            _orders.addAll(orders);
          }
          if (orders.length < pageSize) {
            _hasMore = false;
          }
          _isLoading = false;
        });

        // Handle auto-pay only on first load
        if (_page == 1 && widget.initialOrderNo != null && widget.autoPay && !_hasAutoPaid) {
           final targetOrder = _orders.firstWhere((o) => o.tradeNo == widget.initialOrderNo, orElse: () => XboardOrder(
             tradeNo: '', 
             userId: 0,
             planId: 0,
             type: 1,
             status: -1, 
             createdAt: 0, 
             updatedAt: 0, 
             totalAmount: 0
           ));
           
           if (targetOrder.tradeNo.isNotEmpty && targetOrder.status == 0) {
              _hasAutoPaid = true; // Mark as handled
              // Delay slightly to ensure UI build
              Future.microtask(() => _openPaymentDialog(targetOrder));
           }
        }
      }
    } catch (e) {
      if (mounted) {
        if (!widget.isEmbedded) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to load orders: $e')),
           );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPaymentDialog(XboardOrder order) async {
    // Use unified payment dialog
    final result = await showDialog(
      context: context,
      builder: (_) => PaymentMethodDialog(order: order),
    );
    
    // Refresh orders on return (e.g. if paid or cancelled inside dialog potentially)
    _page = 1;
    _hasMore = true;
    _loadOrders();
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      final msg = await XboardOrderService.cancelOrder(orderId);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
         _page = 1;
         _hasMore = true;
         _loadOrders(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取消失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading && _page == 1
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty
          ? const Center(child: Text('暂无订单', style: TextStyle(color: Colors.grey)))
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading && _hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  setState(() {
                    _isLoading = true;
                    _page++;
                  });
                  _loadOrders();
                }
                return true;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(0), // Removed padding for embedded
                itemCount: _orders.length + (_hasMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _orders.length) {
                     return const Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                     );
                  }
                  final order = _orders[index];
                  return _buildOrderCard(order);
                },
              ),
            );

    if (widget.isEmbedded) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            if (widget.showTitle)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 16, 16), // Added padding
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    if (widget.onBack != null)
                      const SizedBox(width: 16),
                    const Text('我的订单', style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary
                    )),
                  ],
                ),
              ),
            if (widget.showTitle)
              const SizedBox(height: 8), // Adjusted spacing
            Expanded(child: content),
         ],
       );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLightSecondary,
      appBar: AppBar(
        title: const Text('我的订单', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
           color: Colors.black87,
           onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildOrderCard(XboardOrder order) {
    String statusText;
    Color statusColor;
    Color statusBgColor;

    switch (order.status) {
      case 0: // Pending
        statusText = '待支付';
        statusColor = const Color(0xFFFF9800);
        statusBgColor = const Color(0xFFFFF3E0);
        break;
      case 1: // Processing
        statusText = '开通中';
        statusColor = AppTheme.primary;
        statusBgColor = AppTheme.primary.withOpacity(0.1);
        break;
      case 2: // Cancelled
        statusText = '已取消';
        statusColor = const Color(0xFF9E9E9E); // Grey
        statusBgColor = const Color(0xFFEEEEEE);
        break;
      case 3: // Completed
        statusText = '已完成';
        statusColor = const Color(0xFF4CAF50); // Green
        statusBgColor = const Color(0xFFE8F5E9);
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    // Determine title based on order type
    String title = order.plan?.name ?? '未知套餐';
    if (order.type == 5) {
      title = '余额充值';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Add margin for shadow visibility
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Subtle shadow
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '订单号: ${order.tradeNo}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    Text(
                      '¥ ${(order.totalAmount / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900, 
                        fontFamily: 'Rubik',
                        color: AppTheme.textPrimary
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (order.status == 0) ...[
             const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)), // Lighter divider
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   SizedBox(
                     height: 36,
                     child: OutlinedButton(
                       onPressed: () => _cancelOrder(order.tradeNo),
                       style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 20),
                         side: BorderSide(color: Colors.grey.shade300),
                         foregroundColor: Colors.grey.shade600,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                         visualDensity: VisualDensity.compact,
                       ),
                       child: const Text('取消订单', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   SizedBox(
                     height: 36,
                     child: ElevatedButton(
                       onPressed: () => _openPaymentDialog(order),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primary,
                         foregroundColor: Colors.white,
                         elevation: 0, // Flat design
                         padding: const EdgeInsets.symmetric(horizontal: 20),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                         visualDensity: VisualDensity.compact,
                       ),
                       child: const Text('立即支付', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                     ),
                   ),
                 ],
               ),
             )
          ]
        ],
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
