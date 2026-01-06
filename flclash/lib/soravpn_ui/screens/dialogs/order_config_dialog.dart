import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';

class OrderConfigDialog extends StatefulWidget {
  final XboardPlan plan;

  const OrderConfigDialog({super.key, required this.plan});

  @override
  State<OrderConfigDialog> createState() => _OrderConfigDialogState();
}

class _OrderConfigDialogState extends State<OrderConfigDialog> {
  late String _selectedPeriodKey;
  
  // Coupon
  final TextEditingController _couponController = TextEditingController();
  bool _isVerifyingCoupon = false;
  Map<String, dynamic>? _couponData; 
  bool _showCouponInput = false;

  String _currencySymbol = '¥';
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _currencySymbol = XboardConfig.currencySymbol;
    _initPeriod();
  }

  void _initPeriod() {
    final periods = widget.plan.availablePeriods;
    if (periods.isNotEmpty) {
      // Default to Max Period (sorting by months descending)
      if (widget.plan.onetimePrice != null) {
         _selectedPeriodKey = 'onetime_price';
      } else {
         // Sort by months descending
         final sorted = List<PlanPeriod>.from(periods)..sort((a, b) => b.months.compareTo(a.months));
         _selectedPeriodKey = sorted.first.key;
      }
    } else {
      _selectedPeriodKey = '';
    }
  }

  Future<void> _verifyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isVerifyingCoupon = true);
    try {
      final res = await XboardOrderService.checkCoupon(code: code, planId: widget.plan.id);
      setState(() {
        _couponData = {
          'code': code,
          'type': res.type,
          'value': res.value,
        };
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('优惠码验证成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _couponData = null);
    } finally {
      if (mounted) setState(() => _isVerifyingCoupon = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedPeriodKey.isEmpty) return;
    
    setState(() => _isCreatingOrder = true);
    try {
      final orderId = await XboardOrderService.createOrder(
          planId: widget.plan.id,
          period: _selectedPeriodKey,
          couponCode: _couponData != null ? _couponController.text.trim() : null,
      );
      
      if (mounted) {
        Navigator.of(context).pop(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建订单失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  double _calculateFinalPrice() {
     final periods = widget.plan.availablePeriods;
     if (periods.isEmpty) return 0;
     final p = periods.firstWhere((p) => p.key == _selectedPeriodKey, orElse: () => periods.first);
     
     double price = p.priceYuan;
     
     if (_couponData != null) {
       final type = _couponData!['type'];
       final value = _couponData!['value']; 
       
       if (type == 1) { // Fixed
          double discount = value / 100.0;
          price = (price - discount);
       } else { // Percent
          double discount = price * (value / 100.0);
          price = (price - discount);
       }
     }
     return price < 0 ? 0 : price;
  }
  
  double _calculateDiscountAmount() {
    final periods = widget.plan.availablePeriods;
     if (periods.isEmpty) return 0;
     final p = periods.firstWhere((p) => p.key == _selectedPeriodKey, orElse: () => periods.first);
     double original = p.priceYuan;
     double finalPrice = _calculateFinalPrice();
     return original - finalPrice;
  }
  
  // Calculations for display
  int _calculateSavings(PlanPeriod p) {
    if (p.isOnetime || p.months <= 1 || widget.plan.monthPrice == null) return 0;
    
    final monthlyPrice = widget.plan.monthPrice! / 100;
    final standardTotal = monthlyPrice * p.months;
    final currentTotal = p.priceYuan;
    
    if (standardTotal <= 0) return 0;
    
    final savings = ((standardTotal - currentTotal) / standardTotal) * 100;
    return savings.round();
  }

  @override
  Widget build(BuildContext context) {
    // Website style colors
    const activeBorderColor = Color(0xFF3B82F6); // Blue-500
    const inactiveBorderColor = Color(0xFFE5E7EB); // Zinc-200
  
    final periods = widget.plan.availablePeriods;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Wider to fit more
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
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('配置订阅', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Text(widget.plan.name, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                     ],
                   ),
                   IconButton(
                     onPressed: () => Navigator.of(context).pop(),
                     icon: const Icon(Icons.close, color: Colors.grey),
                   )
                ],
              ),
              const SizedBox(height: 24),
              
              const Text('选择周期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Periods Wrap
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: periods.map((p) => _buildPeriodCard(p, activeBorderColor, inactiveBorderColor)).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Coupon & Summary
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: inactiveBorderColor),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (!_showCouponInput && _couponData == null)
                       InkWell(
                         onTap: () => setState(() => _showCouponInput = true),
                         child: const Row(
                           children: [
                             Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.grey),
                             SizedBox(width: 8),
                             Text('使用优惠码', style: TextStyle(fontSize: 14, color: Colors.grey)),
                           ],
                         ),
                       )
                    else 
                       Row(
                         children: [
                           Expanded(
                             child: TextField(
                               controller: _couponController,
                               decoration: InputDecoration(
                                 hintText: '输入优惠码',
                                 isDense: true,
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                 fillColor: Colors.white,
                                 filled: true,
                               ),
                               enabled: _couponData == null,
                             ),
                           ),
                           const SizedBox(width: 8),
                           if (_couponData == null)
                             ElevatedButton(
                               onPressed: _isVerifyingCoupon ? null : _verifyCoupon,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF1B2446),
                                 foregroundColor: Colors.white,
                                 visualDensity: VisualDensity.compact,
                               ),
                               child: const Text('验证'),
                             )
                           else
                             IconButton(
                               icon: const Icon(Icons.close),
                               onPressed: () => setState(() {
                                 _couponData = null;
                                 _couponController.clear();
                               }),
                             )
                         ],
                       ),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    
                    _buildSummaryRow('套餐价格', '$_currencySymbol${_getSelectedOriginalPrice()}'),
                    if (_couponData != null)
                      _buildSummaryRow('优惠减免', '- $_currencySymbol${_calculateDiscountAmount().toStringAsFixed(2)}', isHighlight: true),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('总计', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$_currencySymbol${_calculateFinalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                        )
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreatingOrder ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2446),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: _isCreatingOrder 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('确认订单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPeriodCard(PlanPeriod p, Color activeBorderColor, Color inactiveBorderColor) {
    final isSelected = _selectedPeriodKey == p.key;
    final savings = _calculateSavings(p);
    
    // Monthly price logic
    String displayPrice = '';
    String displayUnit = '';
    String originalPriceDisplay = '';
    
    if (p.isOnetime) {
      displayPrice = p.priceYuan.toStringAsFixed(0);
      displayUnit = '一次性';
    } else {
      double monthly = p.monthlyPrice ?? 0;
      displayPrice = monthly.toStringAsFixed(1); // 16.6
      if (displayPrice.endsWith('.0')) displayPrice = displayPrice.substring(0, displayPrice.length - 2);
      displayUnit = '/月';
      
      // Standard monthly price for strikethrough
      if (widget.plan.monthPrice != null && savings > 0) {
        originalPriceDisplay = '$_currencySymbol${(widget.plan.monthPrice! / 100).toStringAsFixed(0)}/月';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodKey = p.key),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              constraints: const BoxConstraints(minHeight: 100), // Flexible height
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? activeBorderColor : inactiveBorderColor,
                  width: isSelected ? 2 : 1
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Wrap content
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (isSelected)
                        Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: activeBorderColor,
                            shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        )
                      else
                        Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            shape: BoxShape.circle
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 20), // Replace Spacer with fixed gap
                  // Price row
                  Wrap( // Allow wrapping if price is very long
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                       if (originalPriceDisplay.isNotEmpty)
                         Text(originalPriceDisplay, style: const TextStyle(
                           decoration: TextDecoration.lineThrough,
                           color: Colors.grey,
                           fontSize: 12
                         )),
                       
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: savings > 0 ? const Color(0xFFEF4444) : const Color(0xFF6B7280), // Red or Grey
                           borderRadius: BorderRadius.circular(4)
                         ),
                         child: Text(
                           '$_currencySymbol$displayPrice$displayUnit', 
                           style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                         ),
                       )
                    ],
                  )
                ],
              ),
            ),
            
            // Savings Badge
            if (savings > 0)
              Positioned(
                top: -8,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // Green
                    borderRadius: BorderRadius.circular(10), // Pill shape
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('省$savings%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  String _getSelectedOriginalPrice() {
     final periods = widget.plan.availablePeriods;
     if (periods.isEmpty) return '0.00';
     final p = periods.firstWhere((p) => p.key == _selectedPeriodKey, orElse: () => periods.first);
     return p.priceYuan.toStringAsFixed(2);
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(
            color: isHighlight ? Colors.green : Colors.black87,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}
