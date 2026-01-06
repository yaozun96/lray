import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fl_clash/common/remote_config_service.dart';
import 'package:flutter/services.dart';

class PaymentMethodDialog extends StatefulWidget {
  final XboardOrder order;

  const PaymentMethodDialog({
    super.key,
    required this.order,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  bool _isLoading = true;
  List<XboardPaymentMethod> _methods = [];
  int _selectedMethodIndex = 0;
  bool _isProcessing = false;
  String? _qrData;

  String _currencySymbol = '¥';

  @override
  void initState() {
    super.initState();
    _currencySymbol = XboardConfig.currencySymbol;
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final fetchedMethods = await XboardOrderService.getPaymentMethods();
      
      // Filter based on configuration
      List<XboardPaymentMethod> methods = fetchedMethods;
      final rules = RemoteConfigService.config?.paymentRules;
      if (rules != null && rules.isNotEmpty) {
         methods = methods.where((m) {
           final myRules = rules.where((r) => r.paymentId == m.id).toList();
           
           // Whitelist behavior: if filtering is enabled, only methods with rules are shown
           if (myRules.isEmpty) return false; 
           
           // Check conditions
           for (var rule in myRules) {
             final amount = widget.order.totalAmountYuan; 
             bool minOk = rule.minAmount == null || amount >= rule.minAmount!;
             bool maxOk = rule.maxAmount == null || amount <= rule.maxAmount!;
             
             if (minOk && maxOk) return true;
           }
           
           return false;
         }).toList();
      }

      if (mounted) {
        setState(() {
          _methods = methods;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error loading methods: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pay() async {
    // If payable > 0, we must have methods
    final payable = widget.order.totalAmountYuan;
    if (payable > 0 && _methods.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    // If payable <= 0, we don't need a method ID (pass 0 or handle in service)
    final methodId = (payable <= 0) ? 0 : _methods[_selectedMethodIndex].id;
    
    try {
       final result = await XboardOrderService.checkoutOrder(tradeNo: widget.order.tradeNo, methodId: methodId);
       
        // If amount is 0 or result indicates success without payment URL (special free order handling)
       if (payable <= 0) {
           // Assume success and close
           if (mounted) {
              Navigator.of(context).pop(true);
           }
           return;
       }

       // Check if data is a URL. If so, prefer redirect even if type is '1' (QR).
       // Many gateways return a URL for their QR page, but desktop users prefer opening it.
       bool isUrl = result.data != null && (result.data!.startsWith('http://') || result.data!.startsWith('https://'));
       
       if (result.type == '1' && !isUrl) { // QR and NOT a standard URL
          setState(() {
            _qrData = result.data;
            _isProcessing = false;
          });
       } else {
          // Redirect (Type 2 OR Type 1 with URL data)
          if (result.data != null && result.data!.isNotEmpty) {
             final urlStr = result.data!;
             final url = Uri.parse(urlStr);
             
             // Try to launch
             bool launched = false;
             try {
               if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
                 launched = true;
               } else if (await launchUrl(url, mode: LaunchMode.platformDefault)) {
                 launched = true;
               }
             } catch (e) {
               if (mounted) {
                 _showErrorDialog('无法跳转支付: $e');
               }
             }
             
             if (launched) {
                if (mounted) Navigator.of(context).pop(true);
             } else {
                // Determine if we should show error or manual dialog
                // For custom schemes, failing to launch often means app not installed.
                // For http/https, it should have worked.
                
                // Show manual copy dialog as fallback
                if (mounted) {
                  _showPaymentLinkDialog(urlStr);
                }
             }
          } else {
            if (mounted) {
               _showErrorDialog('支付链接为空');
            }
          }
       }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('支付请求失败: $e');
      }
    } finally {
      if (mounted && _qrData == null) {
         setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('确定'))],
      )
    );
  }

  void _showPaymentLinkDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('支付链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('自动跳转失败，请复制链接到浏览器或对应APP打开支付。'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Text(url, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
               Clipboard.setData(ClipboardData(text: url));
               // Use a small dialog/toast overlay for success instead of snackbar or just pop
               Navigator.of(ctx).pop();
               showDialog(
                 context: context, 
                 builder: (_) => const AlertDialog(content: Text('已复制支付链接'), actions: [])
               );
               Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && Navigator.canPop(context)) Navigator.of(context).pop(true);
               });
            }, 
            child: const Text('复制'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_qrData != null) {
      return _buildQRCodeView();
    }

    // Calculations
    // totalAmount in API response is usually the Final Payable Amount (Net).
    // So we reconstruct the Original Price (Gross).
    final payable = widget.order.totalAmountYuan; 
    final discount = widget.order.discountAmountYuan ?? 0;
    final surplus = (widget.order.surplusAmount ?? 0) / 100;
    final balance = (widget.order.balance ?? 0) / 100;
    
    final isRecharge = widget.order.planId == 0;
    
    // Original Price = Payable + Deductions
    // For recharge, backend likely treats Bonus as Discount. We normally don't show "Price: 115" for "Recharge 100".
    // So for recharge, we exclude discount from Original Price and hide the discount row.
    final originalPrice = payable + (isRecharge ? 0 : discount) + surplus + balance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Header
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const Text('选择支付方式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                 ],
               ),
               const SizedBox(height: 8),
               Text('订单号: ${widget.order.tradeNo}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
               
               const SizedBox(height: 20),
               
               // Detailed Breakdown
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF9FAFB),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: const Color(0xFFE5E7EB))
                 ),
                 child: Column(
                   children: [
                      _buildDetailRow(isRecharge ? '充值金额' : '商品总价', '$_currencySymbol${originalPrice.toStringAsFixed(2)}'),
                      if (discount > 0)
                        isRecharge 
                          ? _buildDetailRow('赠送金额', '+ $_currencySymbol${discount.toStringAsFixed(2)}', isMinus: true) // Green text for bonus
                          : _buildDetailRow('优惠金额', '-$_currencySymbol${discount.toStringAsFixed(2)}', isMinus: true),
                      if (surplus > 0)
                        _buildDetailRow('折抵金额', '-$_currencySymbol${surplus.toStringAsFixed(2)}', isMinus: true),
                      if (balance > 0)
                        _buildDetailRow('余额支付', '-$_currencySymbol${balance.toStringAsFixed(2)}', isMinus: true),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('应付金额', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_currencySymbol${payable.toStringAsFixed(2)}', 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))
                          ),
                        ],
                      )
                   ],
                 ),
               ),
               
               const SizedBox(height: 24),


               // Methods List - Hide if amount is 0
               if (payable > 0)
                 _isLoading 
                   ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                   : _methods.isEmpty 
                      ? const Center(child: Text('暂无可用支付方式'))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _methods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                             final method = _methods[index];
                             final isSelected = _selectedMethodIndex == index;
                             return InkWell(
                               onTap: () => setState(() => _selectedMethodIndex = index),
                               borderRadius: BorderRadius.circular(12),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                 decoration: BoxDecoration(
                                   border: Border.all(
                                     color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                                     width: isSelected ? 2 : 1
                                   ),
                                   borderRadius: BorderRadius.circular(12),
                                   color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                 ),
                                 child: Row(
                                   children: [
                                     if (method.icon != null)
                                       Image.network(
                                          method.icon!, 
                                          width: 24, 
                                          height: 24, 
                                          headers: const {
                                            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                            'Referer': 'https://api.cwtgo.com/',
                                            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8'
                                          },
                                          errorBuilder: (ctx, err, stack) {
                                             print('DEBUG: Image Load Error for ${method.name}: $err');
                                             return const Icon(Icons.payment); // Fallback
                                          }
                                       ),
                                     const SizedBox(width: 12),
                                     Expanded(child: Text(method.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                     if (isSelected)
                                       const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 18)
                                   ],
                                 ),
                               ),
                             );
                          },
                        ),
                      
               const SizedBox(height: 24),
               
               SizedBox(
                 width: double.infinity,
                 height: 48,
                 child: ElevatedButton(
                   onPressed: (_isLoading || _isProcessing || (_methods.isEmpty && payable > 0)) ? null : _pay,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF16A34A), // Green for pay
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                     elevation: 0,
                   ),
                   child: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 16),
                            SizedBox(width: 8),
                            Text('立即支付', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMinus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(
            color: isMinus ? Colors.green : Colors.black87,
            fontWeight: isMinus ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }

  Widget _buildQRCodeView() {
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('扫码支付', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             SizedBox(
               width: 200, height: 200,
               child: QrImageView(data: _qrData!, size: 200),
             ),
             const SizedBox(height: 20),
             const Text('请使用对应APP扫码完成支付', style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 20),
             TextButton(
               onPressed: () => Navigator.of(context).pop(true), 
               child: const Text('我已支付'),
             )
           ],
         ),
       ),
    );
  }
}
