import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderScreen extends StatefulWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _isLoading = true;
  XboardOrder? _order;
  List<XboardPaymentMethod> _paymentMethods = [];
  int _selectedPaymentIndex = 0;
  bool _isProcessingPay = false; // Paying
  bool _isCancelling = false;
  
  // Polling
  Timer? _pollingTimer;

  // Config
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    _currencySymbol = XboardConfig.currencySymbol;
    _loadData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final order = await XboardOrderService.getOrderDetail(widget.orderId);
      final methods = await XboardOrderService.getPaymentMethods();
      
      setState(() {
        _order = order;
        _paymentMethods = methods;
        if (order.status == 0) {
          _startPolling();
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fail to load order: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
       if (!mounted || _order == null || _order!.status != 0) {
         timer.cancel();
         return;
       }
       try {
         final updatedOrder = await XboardOrderService.getOrderDetail(widget.orderId);
         if (updatedOrder.status != 0) {
            timer.cancel();
            setState(() => _order = updatedOrder);
            if (updatedOrder.status == 3) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('支付成功！')));
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
         }
       } catch (_) {}
    });
  }

  Future<void> _cancelOrder() async {
    setState(() => _isCancelling = true);
    try {
      await XboardOrderService.cancelOrder(widget.orderId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订单已取消')));
      _loadData(); // Refresh status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('fail to cancel: $e')));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _payNow() async {
    if (_paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无支付方式')));
      return;
    }
    
    setState(() => _isProcessingPay = true);
    final method = _paymentMethods[_selectedPaymentIndex];
    
    try {
      final result = await XboardOrderService.checkoutOrder(tradeNo: widget.orderId, methodId: method.id);
      
      if (result.type == '1') { // Assuming type '1' is QR from model inspection (was int before)
         // QR Code
         if (mounted && result.data != null) _showQRCodeDialog(result.data!);
      } else {
         // URL Jump
         if (result.data != null) {
            final url = Uri.parse(result.data!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              throw '无法打开支付链接';
            }
         }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('支付失败: $e')));
    } finally {
      if (mounted) setState(() => _isProcessingPay = false);
    }
  }

  void _showQRCodeDialog(String qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('扫码支付', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: qrData, size: 200),
            ),
            const SizedBox(height: 16),
            const Text('请使用对应APP扫码支付', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                 SizedBox(width: 8),
                 Text('检测支付结果...', style: TextStyle(fontSize: 12))
               ],
            )
          ],
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('关闭'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[OrderScreen] build. Order: ${_order?.tradeNo}, Status: ${_order?.status}, Total: ${_order?.totalAmount}');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _order == null 
          ? _buildErrorState()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 20,
                      right: 20,
                      bottom: 20
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildAmountCard(),
                        if (_order!.status == 0 && _order!.totalAmount > 0) ...[
                           const SizedBox(height: 16),
                           _buildPaymentMethodCard(),
                        ],
                        const SizedBox(height: 100), // Spacing for bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
       bottomNavigationBar: _order != null && _order!.status == 0 ? _buildBottomBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('订单不存在', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回'))
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
               Container(
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20), // Circle shape
                   border: Border.all(color: Colors.grey.shade200),
                 ),
                 child: IconButton(
                   icon: const Icon(Icons.arrow_back, color: Colors.black54),
                   onPressed: () => Navigator.of(context).pop(),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('订单详情', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                     const SizedBox(height: 4),
                     Text('订单号：${widget.orderId}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                   ],
                 ),
               ),
            ],
          ),
        ),
        // Illustration placeholder (can replace with actual asset if available)
        // Opacity 0.9, w-24 h-24
        Opacity(
          opacity: 0.9,
          child: Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
               // user might not have local asset, so we skip or use a generic icon placeholder
               // image: DecorationImage(image: AssetImage('assets/images/order_illustration.png')) 
            ),
            child: Icon(Icons.shopping_cart_checkout, size: 60, color: Colors.blue.shade100.withOpacity(0.5)), 
          ),
        )
      ],
    );
  }

  Widget _buildStatusCard() {
    Color color;
    Color bgColor;
    String text;
    IconData icon;
    
    switch (_order!.status) {
      case 0: // Pending
        color = const Color(0xFFD97706); // amber-600
        bgColor = const Color(0xFFFEF3C7); // amber-100
        text = '待支付';
        icon = Icons.access_time_filled;
        break;
      case 1: // Processing
        color = const Color(0xFF2563EB); // blue-600
        bgColor = const Color(0xFFDBEAFE); // blue-100
        text = '开通中';
        icon = Icons.sync;
        break;
      case 2: // Cancelled
        color = const Color(0xFF52525B); // zinc-600
        bgColor = const Color(0xFFF4F4F5); // zinc-100
        text = '已取消';
        icon = Icons.cancel;
        break;
      case 3: // Completed
        color = const Color(0xFF16A34A); // green-600
        bgColor = const Color(0xFFDCFCE7); // green-100
        text = '已完成';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.black;
        bgColor = Colors.grey.shade100;
        text = '未知';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Container(
             width: 56, height: 56,
             decoration: BoxDecoration(
               color: bgColor,
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: color, size: 28),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                 const SizedBox(height: 4),
                 if (_order!.createdAt != null)
                 Text(
                   DateTime.fromMillisecondsSinceEpoch(_order!.createdAt! * 1000).toLocal().toString().replaceAll('.000', ''),
                   style: TextStyle(fontSize: 13, color: Colors.grey.shade500)
                 )
               ],
             )
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text('应付金额', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
               const SizedBox(height: 4),
               Text(
                 '$_currencySymbol${(_order!.totalAmount / 100).toStringAsFixed(2)}',
                 style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2563EB) /* blue-600 */, fontFamily: 'Rubik'),
               )
             ],
           )
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCardContainer(
      title: '商品信息',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
           if (_order!.plan != null) ...[
             _buildInfoRow('产品名称', _order!.plan!.name, isValueBold: true),
             _buildDivider(),
             if (_order!.period != null)
               _buildInfoRow('类型/周期', _formatPeriod(_order!.period!)),
             _buildDivider(),
             if (_order!.plan!.transferEnable != null)
                _buildInfoRow('产品流量', '${_order!.plan!.transferEnable} GB'),
           ] else 
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('套餐信息获取失败', style: TextStyle(color: Colors.red)),
             ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return _buildCardContainer(
      title: '费用明细',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
           if (_order!.plan != null)
             _buildInfoRow('商品价格', '$_currencySymbol${(_order!.plan!.monthPrice ?? _order!.totalAmount) / 100}'), 
           
           if (_order!.balance != null && _order!.balance! > 0) ...[
              _buildDivider(),
              _buildInfoRow('余额支付', '- $_currencySymbol${(_order!.balance! / 100).toStringAsFixed(2)}', valueColor: const Color(0xFF16A34A) /* green-600 */),
           ],

           if (_order!.discountAmount != null && _order!.discountAmount! > 0) ...[
              _buildDivider(),
              _buildInfoRow('优惠金额', '', 
                customValueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF4F46E5)], // pink-500, purple-500, indigo-600
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('- $_currencySymbol${(_order!.discountAmount! / 100).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ),
           ],

           if (_order!.surplusAmount != null && _order!.surplusAmount! > 0) ...[
              _buildDivider(),
              _buildInfoRow('旧订阅折抵', '- $_currencySymbol${(_order!.surplusAmount! / 100).toStringAsFixed(2)}', valueColor: const Color(0xFF16A34A)),
           ],

           if (_order!.refundAmount != null && _order!.refundAmount! > 0) ...[
              _buildDivider(),
              _buildInfoRow('退回账户金额', '- $_currencySymbol${(_order!.refundAmount! / 100).toStringAsFixed(2)}', valueColor: const Color(0xFF16A34A)),
           ],

           // Total Row
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
             color: const Color(0xFFFAFAFA), // slightly grey
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('实付金额', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                 Text(
                   '$_currencySymbol${(_order!.totalAmount / 100).toStringAsFixed(2)}',
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontFamily: 'Rubik'),
                 )
               ],
             ),
           )
        ],
      ),
    );
  }


  Widget _buildPaymentMethodCard() {
    print('[OrderScreen] building payment methods. Count: ${_paymentMethods.length}');
    return _buildCardContainer(
      title: '选择支付方式',
      icon: Icons.credit_card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _paymentMethods.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('暂无可用支付方式', style: TextStyle(color: Colors.grey))),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 64,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final isSelected = _selectedPaymentIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPaymentIndex = index),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) /* blue-50 */ : Colors.white,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) /* blue-500 */ : Colors.grey.shade200, 
                              width: isSelected ? 2 : 1
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (method.icon != null && method.icon!.isNotEmpty)
                                Image.network(
                                  method.icon!, 
                                  width: 24, height: 24, 
                                  errorBuilder: (_,__,___) {
                                     print('Failed to load icon: ${method.icon}');
                                     return Icon(Icons.payment, color: isSelected ? const Color(0xFF2563EB) : Colors.grey);
                                  }
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(method.name, style: TextStyle(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF374151),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14
                                ), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          )
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 20, 
        bottom: MediaQuery.of(context).padding.bottom + 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _cancelOrder,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isCancelling 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('取消订单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessingPay ? null : _payNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isProcessingPay
                 ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                 : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 18),
                      SizedBox(width: 8),
                      Text('立即支付', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildCardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), thickness: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isValueBold = false, Color? valueColor, Widget? customValueWidget}) {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
           if (customValueWidget != null)
             customValueWidget
           else
             Text(value, style: TextStyle(
               fontWeight: isValueBold ? FontWeight.w600 : FontWeight.normal,
               color: valueColor ?? Colors.black87,
               fontSize: 14
             )),
         ],
       ),
     );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFF3F4F6), thickness: 1);
  }

  
  String _formatPeriod(String period) {
    switch (period) {
      case 'month_price': return '月付';
      case 'quarter_price': return '季付';
      case 'half_year_price': return '半年付';
      case 'year_price': return '年付';
      case 'two_year_price': return '两年付';
      case 'three_year_price': return '三年付';
      case 'onetime_price': return '一次性';
      default: return period;
    }
  }
}
