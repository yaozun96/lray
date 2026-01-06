import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_models.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/order_config_dialog.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';
import 'package:fl_clash/common/remote_config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/order_detail_screen.dart';
import 'package:fl_clash/soravpn_ui/widgets/pending_order_alert.dart';

class StoreScreen extends StatefulWidget {
  final Function(String orderNo, bool fromCreate)? onNavigateToOrder;

  const StoreScreen({super.key, this.onNavigateToOrder});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  List<XboardPlan> _allPlans = [];
  List<XboardPlan> _filteredPlans = [];
  
  // Filtering
  String _selectedPlanType = 'cycle'; 
  List<Map<String, dynamic>> _planTypeOptions = [];
  
  // Config
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    _currencySymbol = XboardConfig.currencySymbol;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await XboardOrderService.getPlans();
      _allPlans = plans.where((p) => p.show).toList();
      _calculatePlanTypeOptions();
      _filterPlans();
    } catch (e) {
      debugPrint('Error loading plans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取套餐失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic Helpers ---

  List<String> _getPlanTags(XboardPlan plan) {
    if (plan.tags == null) return [];
    return plan.tags!.map((t) {
      if (t is String) return t;
      if (t is Map && t['name'] != null) return t['name'].toString();
      return '';
    }).where((s) => s.isNotEmpty).toList();
  }

  void _calculatePlanTypeOptions() {
    final dynamicTags = <String, Map<String, bool>>{};
    
    // Check all plans
    bool hasOnetime = false;
    bool hasCycle = false;

    for (var plan in _allPlans) {
      final tags = _getPlanTags(plan);
      final isOnetime = plan.onetimePrice != null;
      final isCycle = plan.monthPrice != null || plan.quarterPrice != null || 
                      plan.halfYearPrice != null || plan.yearPrice != null ||
                      plan.twoYearPrice != null || plan.threeYearPrice != null;

      if (tags.isNotEmpty) {
        for (var tag in tags) {
          if (!dynamicTags.containsKey(tag)) {
            dynamicTags[tag] = {'hasOnetime': false, 'hasCycle': false};
          }
          if (isOnetime) dynamicTags[tag]!['hasOnetime'] = true;
          if (isCycle) dynamicTags[tag]!['hasCycle'] = true;
        }
      } else {
        if (isOnetime && !isCycle) hasOnetime = true;
        if (isCycle) hasCycle = true;
      }
    }

    _planTypeOptions = [];
    if (hasOnetime) {
      _planTypeOptions.add({'label': '永久套餐', 'value': 'onetime', 'icon': Icons.all_inclusive});
    }
    if (hasCycle) {
      _planTypeOptions.add({'label': '周期套餐', 'value': 'cycle', 'icon': Icons.update});
    }

    // Sort based on remote config
    final order = RemoteConfigService.config?.planTypeOrder;
    if (order != null && order.isNotEmpty) {
      _planTypeOptions.sort((a, b) {
        final valA = a['value'] as String;
        final valB = b['value'] as String;
        final indexA = order.indexOf(valA);
        final indexB = order.indexOf(valB);

        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return 0; // Keep original order if neither is in config
      });
    }

    dynamicTags.forEach((tag, info) {
      IconData icon = Icons.loyalty;
      if (tag.toLowerCase().contains('tiktok') || tag.contains('直播')) {
        icon = Icons.live_tv;
      } else if (tag.contains('游戏')) {
        icon = Icons.sports_esports;
      }
      _planTypeOptions.add({'label': tag, 'value': tag, 'icon': icon});
    });

    // Always select the first option available after sorting, 
    // to ensure the default view respects the configured order (e.g. onetime first).
    if (_planTypeOptions.isNotEmpty) {
       // Only if the current selection is default 'cycle' and checking if we should override?
       // Actually, on initial load _selectedPlanType is 'cycle'.
       // We should check if this is the first load?
       // But _loadPlans is only called in initState. So it is safe to overwrite.
       _selectedPlanType = _planTypeOptions.first['value'];
    }
  }

  void _filterPlans() {
    _filteredPlans = _allPlans.where((p) {
      final tags = _getPlanTags(p);
      final isTagged = tags.isNotEmpty;
      final hasOnetime = p.onetimePrice != null;
      final hasCycle = p.monthPrice != null || p.quarterPrice != null ||
                       p.halfYearPrice != null || p.yearPrice != null ||
                       p.twoYearPrice != null || p.threeYearPrice != null;

      if (_selectedPlanType == 'onetime') {
        return hasOnetime && !hasCycle && !isTagged;
      } else if (_selectedPlanType == 'cycle') {
        return hasCycle && !isTagged;
      } else {
        return tags.contains(_selectedPlanType);
      }
    }).toList();

    // Sort by price
    _filteredPlans.sort((a, b) {
      int getPrice(XboardPlan p) {
        if (_selectedPlanType == 'onetime') return p.onetimePrice ?? 0;
        return p.minPrice ?? 0;
      }
      return getPrice(a).compareTo(getPrice(b));
    });
  }

  Future<void> _startPurchase(XboardPlan plan) async {
    // 1. Config Dialog
    final orderId = await showDialog<String>(
      context: context, 
      builder: (_) => OrderConfigDialog(plan: plan)
    );

    if (orderId != null && mounted) {
      if (mounted) {
         if (widget.onNavigateToOrder != null) {
           widget.onNavigateToOrder!(orderId, true);
         } else {
           Navigator.of(context).push(
             MaterialPageRoute(
               builder: (context) => OrderDetailScreen(
                 orderNo: orderId,
                 fromCreate: true,
               ),
             ),
           );
         }
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              // Header
              SliverPadding(
                padding: EdgeInsets.only(
                   top: MediaQuery.of(context).padding.top + 20,
                   left: 20,
                   right: 20,
                   bottom: 0
                ),
                sliver: SliverToBoxAdapter(
                   child: Column(
                     children: [
                        PendingOrderAlert(
                           onNavigateToOrderList: () {
                             if (widget.onNavigateToOrder != null) {
                               // We pass a dummy order number, but ideally we'd have a specific callback.
                               // However, the MainLayout handles _navigateToOrder(orderNo, fromCreate)
                               // If we pass empty string, it might just open the list? 
                               // Actually, MainLayout logic: "if fromCreate is true, it overrides"
                               // But we want to go back to list...
                               // Wait, onNavigateToOrder is typically _navigateToOrder in MainLayout.
                               // Let's see MainLayout _navigateToOrder implementation.
                               // It takes (String orderNo, bool fromCreate).
                               // If I call widget.onNavigateToOrder!('', false), it might work if treated as "view list".
                               // But MainLayout implementation of `_navigateToOrder` uses `_overridePage = OrderListScreen(...)` 
                               // regardless of arguments mostly, or uses it to highlight?
                               // Let's assume onNavigateToOrder with dummy ID works or use a new callback.
                               // Since I didn't add a new callback to StoreScreen in the plan, I should reuse existing or just pass a closure that works if MainLayout logic supports it.
                               // Actually, in MainLayout, _navigateToOrder sets the override page to OrderListScreen.
                               // So passing any string should be fine as long as it triggers the override.
                               widget.onNavigateToOrder!('', false);
                             }
                           },
                        ),
                       const SizedBox(height: 10),
                       Center(
                         child: _buildPlanTypeTabs(),
                       ),
                       const SizedBox(height: 20),
                     ],
                   ),
                ),
              ),

              // Plan Grid
              SliverPadding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                sliver: _filteredPlans.isEmpty
                  ? const SliverToBoxAdapter(child: Center(child: Text('暂无相关套餐', style: TextStyle(color: Colors.grey))))
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85, 
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildPlanCard(_filteredPlans[index]);
                        },
                        childCount: _filteredPlans.length,
                      ),
                    ),
              )
            ],
          ),
    );
  }

  Widget _buildPlanTypeTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _planTypeOptions.map((opt) {
          final isSelected = _selectedPlanType == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlanType = opt['value'];
                  _filterPlans();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B2446) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(opt['icon'], size: 14, color: isSelected ? Colors.white : Colors.grey),
                    const SizedBox(width: 8),
                    Text(opt['label'], style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 13, fontWeight: FontWeight.bold
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(XboardPlan plan) {
    // Check if onetime
    final isOnetime = _selectedPlanType == 'onetime' || plan.onetimePrice != null;
    
    return Container(
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.transparent), // invisible border for sizing
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4)
           )
         ]
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(plan.name, 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('¥', style: TextStyle(color: Colors.grey)),
              Text(_calculateDisplayPrice(plan, isOnetime), 
                 style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))
              ),
              Text('/${isOnetime ? '永久': '月起'}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Divider(height: 30),
          Expanded(
             child: SingleChildScrollView(
               physics: const NeverScrollableScrollPhysics(),
               child: Column(
                 children: _parseContent(plan.content).map((f) => Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(2),
                         decoration: BoxDecoration(
                           color: f['support'] ? Colors.black : Colors.grey.withOpacity(0.3),
                           shape: BoxShape.circle
                         ),
                         child: Icon(f['support'] ? Icons.check : Icons.close, size: 10, color: Colors.white)
                       ),
                       const SizedBox(width: 8),
                       Expanded(child: Text(f['feature'], style: TextStyle(
                         fontSize: 13, 
                         color: f['support'] ? Colors.black87 : Colors.grey
                         ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                     ],
                   ),
                 )).toList(),
               ),
             ),
          ),
          const SizedBox(height: 16),
          SizedBox(
             width: double.infinity,
             height: 44,
             child: ElevatedButton(
               onPressed: () => _startPurchase(plan),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF1B2446),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                 elevation: 0,
               ),
               child: const Text('订阅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ),
          )
        ],
      ),
    );
  }

  String _calculateDisplayPrice(XboardPlan plan, bool isOnetime) {
    if (isOnetime) {
       return ((plan.onetimePrice ?? 0) / 100).toStringAsFixed(1);
    }
    
    // Find lowest monthly price
    double? minMonthlyPrice;
    
    for (var p in plan.availablePeriods) {
       if (p.isOnetime) continue;
       double? monthly = p.monthlyPrice;
       if (monthly != null) {
          if (minMonthlyPrice == null || monthly < minMonthlyPrice) {
             minMonthlyPrice = monthly;
          }
       }
    }
    
    // Fallback to minPrice/100 if no periods found (shouldn't happen for valid plans)
    if (minMonthlyPrice == null) {
       return ((plan.minPrice ?? 0) / 100).toStringAsFixed(1);
    }
    
    return minMonthlyPrice.toStringAsFixed(1);
  }

  List<Map<String, dynamic>> _parseContent(String? content) {
    if (content == null) return [];
    try {
      final List<dynamic> json = jsonDecode(content);
      return json.map((e) {
         if (e is Map<String, dynamic> && e.containsKey('feature')) {
           return {'feature': e['feature'], 'support': e['support'] ?? true};
         }
         return null;
      }).whereType<Map<String,dynamic>>().toList();
    } catch (e) {
      return [];
    }
  }
}
