import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/common/common.dart';

class RechargeDialog extends StatefulWidget {
  final Function(String tradeNo) onOrderCreated;

  const RechargeDialog({Key? key, required this.onOrderCreated}) : super(key: key);

  @override
  _RechargeDialogState createState() => _RechargeDialogState();
}

class _RechargeDialogState extends State<RechargeDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _bonusConfig = [];

  final List<int> _quickAmounts = [10, 50, 100, 200, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _fetchBonusConfig();
  }

  Future<void> _fetchBonusConfig() async {
    try {
      final config = await XboardOrderService.getRechargeBonusConfig();
      if (mounted) {
        setState(() {
          _bonusConfig = config;
        });
      }
    } catch (e) {
      print('Failed to fetch bonus config: $e');
    }
  }

  Future<void> _createRecharge() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) return;

    final amountYuan = double.tryParse(text);
    if (amountYuan == null || amountYuan < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的金额（最少10元）')));
      return;
    }

    if (amountYuan > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('单次充值金额不能超过10000元')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Amount in cents
      final amountCents = (amountYuan * 100).round();
      final tradeNo = await XboardOrderService.createRechargeOrder(amountCents);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onOrderCreated(tradeNo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建订单失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  double _calculateBonus(double amountYuan) {
    if (_bonusConfig.isEmpty) return 0;

    final amountCents = (amountYuan * 100).round();
    
    // Sort config by threshold descending
    final sortedConfig = List<Map<String, dynamic>>.from(_bonusConfig);
    sortedConfig.sort((a, b) {
      final tA = a['threshold'] as int? ?? 0;
      final tB = b['threshold'] as int? ?? 0;
      return tB.compareTo(tA);
    });

    for (var item in sortedConfig) {
      final threshold = item['threshold'] as int? ?? 0;
      if (amountCents >= threshold) {
        final bonusCents = item['bonus'] as int? ?? 0;
        return bonusCents / 100.0;
      }
    }

    return 0;
  }

  double get _currentBonus {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    final amount = double.tryParse(text);
    if (amount == null) return 0;
    return _calculateBonus(amount);
  }

  double get _totalAmount {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    final amount = double.tryParse(text);
    if (amount == null) return 0;
    return amount + _currentBonus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('账户充值', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   IconButton(
                     icon: const Icon(Icons.close),
                     onPressed: () => Navigator.pop(context),
                   ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择或输入金额', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  
                  // Quick amounts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts.map((amount) {
                      final isSelected = _amountController.text == amount.toString();
                      final bonus = _calculateBonus(amount.toDouble());
                      
                      return SizedBox(
                        width: 78,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _amountController.text = amount.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primary : AppTheme.bgLightSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.transparent
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '¥$amount',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (bonus > 0)
                                Positioned(
                                  top: -8,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${bonus.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Custom input
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '¥ ',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      hintText: '输入自定义金额 (10 - 10000)',
                      filled: true,
                      fillColor: AppTheme.bgLightSecondary,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  
                  if (_currentBonus > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            '充值赠送: ¥${_currentBonus.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '实到: ¥${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _createRecharge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('确认充值', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
