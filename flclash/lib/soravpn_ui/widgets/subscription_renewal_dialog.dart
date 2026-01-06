import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/plan.dart';
import 'package:fl_clash/soravpn_ui/services/purchase_service.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';
import 'package:fl_clash/soravpn_ui/models/order.dart';

class SubscriptionRenewalDialog extends StatefulWidget {
  final Plan plan;
  final int userSubscribeId;

  const SubscriptionRenewalDialog({
    super.key,
    required this.plan,
    required this.userSubscribeId,
  });

  @override
  State<SubscriptionRenewalDialog> createState() => _SubscriptionRenewalDialogState();
}

class _SubscriptionRenewalDialogState extends State<SubscriptionRenewalDialog> {
  late PlanPeriod _selectedPeriod;
  final TextEditingController _couponController = TextEditingController();
  
  OrderPreview? _orderPreview;
  bool _isLoadingPreview = false;
  bool _isCreatingOrder = false;
  String? _couponMessage;

  @override
  void initState() {
    super.initState();
    _initSelectedPeriod();
    _updatePreview();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _initSelectedPeriod() {
    if (widget.plan.periods.isNotEmpty) {
      // Prefer monthly or the first available period
      try {
        _selectedPeriod = widget.plan.periods.firstWhere(
          (p) => !p.isOnetime && p.months == 12, // User screenshot has Year selected by default
          orElse: () => widget.plan.periods.first,
        );
      } catch (_) {
        _selectedPeriod = widget.plan.periods.first;
      }
    } else {
      // Fallback
      _selectedPeriod = PlanPeriod(
        key: 'month_price',
        name: '月付',
        price: widget.plan.unitPrice,
        months: 1,
      );
    }
  }

  Future<void> _updatePreview() async {
    setState(() {
      _isLoadingPreview = true;
      _couponMessage = null;
    });

    try {
      // Use placeholder payment ID 1 just to get price preview
      final preview = await PurchaseService.getOrderPreview(
        subscribeId: widget.plan.id,
        payment: 1, 
        quantity: _selectedPeriod.months,
        period: _selectedPeriod.key,
        coupon: _couponController.text.trim(),
      );

      setState(() {
        _orderPreview = preview;
        _isLoadingPreview = false;
        // Don't show success message under input, will show in price summary
        _couponMessage = null; 
      });
    } catch (e) {
        setState(() {
            _isLoadingPreview = false;
            if (_couponController.text.isNotEmpty) {
               _couponMessage = '优惠码无效';
            }
        });
    }
  }

  // ... _handleNextStep ...
  // ... build methods ...

  Widget _buildPriceSummary() {
      final amount = _orderPreview?.totalAmountInYuan ?? _selectedPeriod.priceYuan;
      final originalPrice = _orderPreview?.priceInYuan ?? _selectedPeriod.priceYuan;
      final discount = _orderPreview?.couponDiscountInYuan ?? 0.0;
      
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.bgLightSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
              children: [
                 Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                         const Text('原价', style: TextStyle(color: AppTheme.textLightSecondary, fontSize: 13)),
                         Text('${ConfigService.currencySymbol}${originalPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textLightPrimary)),
                     ],
                 ),
                 if (discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            const Text('已优惠', style: TextStyle(color: AppTheme.textLightSecondary, fontSize: 13)),
                            Text(
                                '-${ConfigService.currencySymbol}${discount.toStringAsFixed(2)}', 
                                style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w500)
                            ),
                        ],
                    ),
                 ],
                 const SizedBox(height: 12),
                 const Divider(height: 1, color: AppTheme.border),
                 const SizedBox(height: 12),
                 Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                         const Text('实付金额', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                         if (_isLoadingPreview)
                             const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                         else
                             Text(
                                 '${ConfigService.currencySymbol}${amount.toStringAsFixed(0)}',
                                 style: const TextStyle(
                                     fontSize: 20,
                                     fontWeight: FontWeight.bold,
                                     color: Color(0xFF3B82F6), // Blue color
                                 ),
                             ),
                     ],
                 ),
              ],
          ),
      );
  }

  Future<void> _handleNextStep() async {
    setState(() => _isCreatingOrder = true);
    
    try {
       // 1. Create Order
       final tradeNo = await XboardOrderService.createOrder(
          planId: widget.plan.id,
          period: _selectedPeriod.key,
          couponCode: _couponController.text.trim().isEmpty ? null : _couponController.text.trim(),
       );
       
       // 2. Get Order Details
       final order = await XboardOrderService.getOrderDetail(tradeNo);
       
       if (!mounted) return;
       
       // 3. Close this dialog and Open Unified Payment Dialog
       final messenger = ScaffoldMessenger.of(context);
       Navigator.of(context).pop(); 
       
       final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PaymentMethodDialog(order: order),
       );

       if (result == true) {
          messenger.showSnackBar(
             const SnackBar(content: Text('支付成功'), backgroundColor: AppTheme.success),
          );
          XboardOrderService.orderUpdateNotifier.value++;
          // Note: We can't easily trigger refresh here as we don't have the callback.
          // But usually OrderPaymentScreen or returning to the main screen triggers a refresh in `SubscriptionCard` or `Dashboard`.
       }
       
    } catch (e) {
       if (mounted) {
           setState(() => _isCreatingOrder = false);
           ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('创建订单失败: $e'), backgroundColor: AppTheme.error),
           );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 440, // Reduced width from 500
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Tighter padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            Text(widget.plan.name, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))), // Smaller text
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodGrid(),
                    const SizedBox(height: 20), // Reduced spacing
                    _buildCouponInput(),
                    const SizedBox(height: 20),
                    _buildPriceSummary(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reduced spacing
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '续费订阅',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 20), // Lighter close icon
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildPeriodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12, // Reduced spacing
        crossAxisSpacing: 12,
        childAspectRatio: 1.6, // Shorter cards
      ),
      itemCount: widget.plan.periods.length,
      itemBuilder: (context, index) {
        final period = widget.plan.periods[index];
        final isSelected = _selectedPeriod.key == period.key;
        return _buildPeriodCard(period, isSelected);
      },
    );
  }

  Widget _buildPeriodCard(PlanPeriod period, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = period);
        _updatePreview();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14), // Reduced padding inside card
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.name,
                  style: TextStyle(
                    fontSize: 13, // Smaller text
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ConfigService.currencySymbol}${period.priceYuan.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24, // Reduced from 28
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check, size: 10, color: Colors.white), // Smaller icon
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInput() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('优惠码', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Row(
                  children: [
                      Expanded(
                          child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)), // Focus-like border
                              ),
                              child: Row(
                                  children: [
                                      const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Icon(Icons.confirmation_number_outlined, color: Color(0xFF9CA3AF), size: 20),
                                      ),
                                      Expanded(
                                          child: TextField(
                                              controller: _couponController,
                                              decoration: const InputDecoration(
                                                  hintText: '输入优惠码 (可选)',
                                                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.only(bottom: 2), // Adjust alignment
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                              onSubmitted: (_) => _updatePreview(),
                                          ),
                                      ),
                                  ],
                              ),
                          ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                            onPressed: _updatePreview,
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                foregroundColor: const Color(0xFF374151),
                            ),
                            child: const Text('验证'),
                        ),
                      ),
                  ],
              ),
              if (_couponMessage != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                          _couponMessage!,
                          style: TextStyle(
                              fontSize: 12,
                              color: _couponMessage!.contains('无效') ? AppTheme.error : AppTheme.success,
                          ),
                      ),
                  ),
          ],
      );
  }



  // Maintaining simplified footer
  Widget _buildFooter() {
    return Row(
        children: [
            Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('取消'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                  ),
                ),
            ),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                      onPressed: _isCreatingOrder ? null : _handleNextStep,
                      icon: const Icon(Icons.payment, size: 18),
                      label: _isCreatingOrder 
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                           : const Text('确认续费'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Strong blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                  ),
                ),
            ),
        ],
    );
  }
}
