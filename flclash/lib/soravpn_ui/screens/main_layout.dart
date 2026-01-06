import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/widgets/sidebar.dart';
import 'package:fl_clash/soravpn_ui/screens/dashboard_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/store_screen.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/screens/invite_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/ticket/ticket_list_page.dart'; // [New Import]
import 'package:fl_clash/soravpn_ui/screens/settings_screen.dart'; // [Account page]

import 'package:fl_clash/views/tools.dart'; // [New Import]
import 'package:fl_clash/views/about.dart'; // [About page]
import 'package:fl_clash/soravpn_ui/screens/order_detail_screen.dart'; // [New Import]
import 'package:fl_clash/soravpn_ui/screens/order_list_screen.dart'; // [New Import - For Order List Navigation]
import 'package:fl_clash/soravpn_ui/screens/account_security_screen.dart'; // [Change Password]

/// 主布局 - 包含侧边栏和内容区域
class MainLayout extends StatefulWidget {
  final int initialIndex;
  
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;
  VpnNode? _selectedNode; // 当前选中的节点
  Widget? _overridePage; // Page to show instead of _pages[_selectedIndex]
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _navigateToOrder(String orderNo, bool fromCreate) {
    setState(() {
      _overridePage = OrderListScreen(
        isEmbedded: true, // Use embedded mode
        initialOrderNo: orderNo,
        autoPay: fromCreate, // Auto open payment if from create
        onBack: () {
          setState(() {
            _overridePage = null;
          });
        },
      );
    });
  }

  // 所有页面
  List<Widget> get _pages => [
    DashboardScreen(
      selectedNode: _selectedNode,
      onNavigateToPlans: () {
        setState(() {
          _selectedIndex = 1; // 跳转到购买套餐页面
          _overridePage = null;
        });
      },

      onNodeSelected: (node) {
        setState(() {
          _selectedNode = node;
        });
      },
    ), // 0: 仪表盘

    StoreScreen(
      onNavigateToOrder: (orderNo, fromCreate) => _navigateToOrder(orderNo, fromCreate),
    ), // 1: 购买订阅
    const InviteScreen(), // 2: 邀请赚钱
    // const TicketListPage(), // Moved/Removed from sidebar
    const ToolsView(), // 3: 设置
    SettingsScreen(
      onNavigateToOrder: (orderNo, fromCreate) => _navigateToOrder(orderNo, fromCreate),
    ), // 4: 我的账户
    const AboutView(), // 5: 关于
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边导航栏
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _overridePage = null; // Clear override when switching tabs
              });
            },
          ),

          // 主内容区域
          Expanded(
            child: _overridePage ?? _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

/// 占位页面（用于未开发的功能）
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '功能开发中...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
