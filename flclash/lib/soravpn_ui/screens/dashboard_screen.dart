import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/vpn_service.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/services/announcement_service.dart';
import 'package:fl_clash/soravpn_ui/models/proxy_mode.dart';
import 'package:fl_clash/soravpn_ui/widgets/subscription_card.dart';
import 'package:fl_clash/soravpn_ui/widgets/announcement_dialog.dart';
import 'package:fl_clash/soravpn_ui/widgets/popup_announcement_dialog.dart';
import 'package:fl_clash/soravpn_ui/widgets/world_map_background_v2.dart';
import 'package:fl_clash/soravpn_ui/widgets/node_selection_dialog.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_user.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_user_service.dart';
import 'package:fl_clash/soravpn_ui/widgets/pending_order_alert.dart';
import 'package:fl_clash/soravpn_ui/screens/order_list_screen.dart';

/// 仪表盘界面 - 参考 CyberShield 原型设计
class DashboardScreen extends ConsumerStatefulWidget {
  final VpnNode? selectedNode;
  final Function(VpnNode)? onNodeSelected;
  final VoidCallback? onNavigateToPlans;

  const DashboardScreen({
    super.key,
    this.selectedNode,
    this.onNodeSelected,
    this.onNavigateToPlans,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  // 静态变量：追踪本次应用启动是否已显示过弹窗
  static bool _hasShownPopupThisSession = false;

  // 连接状态现在从 runTimeProvider 获取，不再使用本地变量
  bool _isConnecting = false;
  Duration _connectionDuration = Duration.zero;
  Timer? _timer;
  Timer? _subscriptionRefreshTimer;
  ProxyMode _proxyMode = ProxyMode.smart;
  List<VpnNode> _nodes = [];
  VpnNode? _selectedNode;
  Subscription? _subscription;
  Map<int, int> _nodePings = {}; // node.id -> latency in ms
  bool _isPingingNodes = false;
  bool _isAutoSelected = false; // 标记节点是否自动选择
  String _fallbackAutoNodeName = '';

  // 按钮状态
  double _buttonScale = 1.0;
  bool _isButtonHovered = false;
  XboardUser? _user; // User info for card

  // 光波动画控制器
  late AnimationController _waveController1;
  late AnimationController _waveController2;
  late AnimationController _waveController3;
  late Animation<double> _waveAnimation1;
  late Animation<double> _waveAnimation2;
  late Animation<double> _waveAnimation3;

  @override
  void initState() {
    super.initState();

    // 初始化光波动画
    _initWaveAnimations();

    // 使用外部传入的节点，如果没有则保持为 null (提示用户选择)
    _selectedNode = widget.selectedNode;
    _isAutoSelected = false;

    // 同步代理模式（连接状态现在从 runTimeProvider 获取）
    _proxyMode = VpnService.proxyMode;
    print('[Dashboard] initState: proxyMode: ${_proxyMode.label}');

    // 如果已连接，停止光波动画（使用 VpnService.isConnected 检查初始状态）
    if (VpnService.isConnected) {
      _stopWaveAnimation();
    }

    _loadNodes();
    _loadSubscription();
    _startTimer();
    _startSubscriptionRefreshTimer();

    // 如果VPN已连接但节点不同，自动重新连接
    _checkAndReconnectIfNeeded();

    // 检查并显示弹窗公告
    _checkPopupAnnouncements();
  }

  /// 初始化光波动画
  void _initWaveAnimations() {
    // 第一圈光波 - 2秒周期
    _waveController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController1, curve: Curves.easeOut),
    );

    // 第二圈光波 - 2秒周期，延迟 0.6 秒
    _waveController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController2, curve: Curves.easeOut),
    );

    // 第三圈光波 - 2秒周期，延迟 1.2 秒
    _waveController3 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController3, curve: Curves.easeOut),
    );

    // 启动循环动画
    _startWaveAnimation();
  }

  /// 启动光波动画循环
  void _startWaveAnimation() {
    _waveController1.repeat();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _waveController2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _waveController3.repeat();
    });
  }

  /// 停止光波动画
  void _stopWaveAnimation() {
    _waveController1.stop();
    _waveController2.stop();
    _waveController3.stop();
    _waveController1.reset();
    _waveController2.reset();
    _waveController3.reset();
  }

  /// 检查是否需要重新连接到选中的节点
  void _checkAndReconnectIfNeeded() {
    if (_selectedNode == null) {
      print('[Dashboard] No selected node, skipping reconnect check');
      return;
    }

    final currentNode = VpnService.currentNode;
    final isConnected = VpnService.isConnected;

    print('[Dashboard] Reconnect check - isConnected: $isConnected, currentNode: ${currentNode?.name}, selectedNode: ${_selectedNode!.name}');

    if (isConnected && currentNode != null) {
      // 检查当前连接的节点是否与选中的节点相同
      if (currentNode.id != _selectedNode!.id) {
        print('[Dashboard] Node mismatch detected! Current: ${currentNode.name} (id: ${currentNode.id}), Selected: ${_selectedNode!.name} (id: ${_selectedNode!.id})');
        print('[Dashboard] Triggering reconnection...');
        _reconnectToNewNode();
      } else {
        print('[Dashboard] Nodes match, no reconnection needed');
      }
    } else {
      print('[Dashboard] Not connected or no current node, skipping reconnect');
    }
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的节点变化时，更新本地状态
    if (widget.selectedNode != oldWidget.selectedNode) {
      final nodeChanged = widget.selectedNode?.id != oldWidget.selectedNode?.id;

      setState(() {
        _selectedNode = widget.selectedNode;
        // 外部选择的节点不标记为自动选择
        if (_selectedNode != null) {
          _isAutoSelected = false;
        }
      });

      // 如果节点变化且当前已连接，自动重新连接到新节点
      if (nodeChanged && VpnService.isConnected && _selectedNode != null) {
        print('[Dashboard] Node changed while connected, reconnecting to new node: ${_selectedNode!.name}');
        _reconnectToNewNode();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscriptionRefreshTimer?.cancel();
    _waveController1.dispose();
    _waveController2.dispose();
    _waveController3.dispose();
    super.dispose();
  }

  /// 加载节点列表
  Future<void> _loadNodes() async {
    try {
      final nodes = await SubscribeService.getNodeList();
      if (mounted) {
        setState(() {
          _nodes = nodes;
        });
        await _resolveFallbackAutoNode(); // Resolve default auto node from config
        // Insert Auto node at the top
        // User requested NOT to show Auto in the list as a node
        // if (_nodes.isNotEmpty) {
        //   _nodes.insert(0, VpnNode.auto());
        // }
        
        // If no node is selected, keep it null to prompt user
        // if (_selectedNode == null) {
        //    _selectedNode = VpnNode.auto();
        //    _isAutoSelected = true;
        // }
        
        if (_selectedNode != null) {
           print('[Dashboard] Loaded nodes. Selected node: ${_selectedNode!.name}, Country: "${_selectedNode!.country}"');
        } else {
           print('[Dashboard] Loaded nodes. No node selected.');
        }

        /* 
        // Deprecated: No longer auto-ping to select best. User requested "Auto" (URL-Test) group default.
        if (_nodes.isNotEmpty) {
          _pingNodesAndAutoSelect();
        }
        */
      }
      
      // Ping the displayed node (whether Auto-resolved or manually selected)
      _pingDisplayNode();
      
      // Retry pinging a few times to ensure fallback node is caught and UI updates
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(seconds: i + 1), () {
          if (mounted) _pingDisplayNode();
        });
      }
      
    } catch (e) {
      print('[Dashboard] Load nodes error: $e');
    }
  }

  /// Ping only the currently displayed node to update its latency
  Future<void> _pingDisplayNode() async {
    if (!mounted || _selectedNode == null) return;
    
    VpnNode? targetNode = _selectedNode;
    
    // If selected node is Auto, resolving to actual node
    if (_isAutoSelected || _selectedNode!.id == -1) {
       var resolvedName = _getResolvedAutoNodeName();
       print('[Dashboard] Auto resolution result: "$resolvedName"');
       
       if (resolvedName.isNotEmpty) {
         targetNode = _findNodeByName(resolvedName);
       }
       
       // Fallback: if resolution failed or found node is null, try first available node
       if ((resolvedName.isEmpty || targetNode == null) && _nodes.isNotEmpty) {
         print('[Dashboard] Auto resolution failed, falling back to first node: ${_nodes.first.name}');
         targetNode = _nodes.first;
         // Optionally update the resolved name using fallback logic for future calls
         _fallbackAutoNodeName = targetNode.name;
       }
    }
    
    if (targetNode != null && targetNode.id != -1) {
      // Don't clear all pings, just update this one
      await _pingNode(targetNode);
    } else {
       print('[Dashboard] No valid node to ping (targetNode is ${targetNode?.name})');
       // If we really can't find a node, maybe just stop the spinner?
       // But _buildLatencyIndicator handles null as spinner.
       // We can force a timeout state if needed.
       if (targetNode != null) {
          if (mounted) setState(() => _nodePings[targetNode!.id] = -1);
       }
    }
  }

  /// 测试所有节点延迟并自动选择最低延迟的
  Future<void> _pingNodesAndAutoSelect() async {
    setState(() {
      _isPingingNodes = true;
      _nodePings.clear();
    });

    // 并发测试所有节点（限制并发数为5）
    final futures = <Future>[];
    for (var node in _nodes) {
      futures.add(_pingNode(node));
      if (futures.length >= 5) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // 选择延迟最低的节点
    if (_nodePings.isNotEmpty && _selectedNode == null) {
      int? lowestLatency;
      VpnNode? bestNode;

      for (var node in _nodes) {
        final ping = _nodePings[node.id];
        if (ping != null && ping > 0 && (lowestLatency == null || ping < lowestLatency)) {
          lowestLatency = ping;
          bestNode = node;
        }
      }

      if (bestNode != null) {
        setState(() {
          _selectedNode = bestNode;
          _isAutoSelected = true; // 标记为自动选择
        });
        // 通知外部节点已被自动选择
        widget.onNodeSelected?.call(bestNode!);
      }
    }

    setState(() {
      _isPingingNodes = false;
    });
  }

  /// 测试单个节点延迟
  Future<void> _pingNode(VpnNode node) async {
    try {
      // 使用 Google Generate 204 作为测试地址，或从配置中获取
      final testUrl = globalState.config.appSetting.testUrl ?? 'http://www.gstatic.com/generate_204';
      
      print('[Dashboard] Pinging node: ${node.name} with url: $testUrl');
      
      // Add timeout to prevent infinite spinner
      final delay = await coreController.getDelay(testUrl, node.name).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[Dashboard] Ping timeout for ${node.name}');
          throw TimeoutException('Ping timeout');
        },
      );
      
      if (mounted) {
        setState(() {
          // 根据 FlClash Delay 模型实现，delay.value 是延迟数值 (ms) (int?)
          // 0 或负数通常表示失败/超时
          final latency = delay.value ?? -1;
          print('[Dashboard] Ping success for ${node.name}: $latency ms');
          if (latency > 0) {
             _nodePings[node.id] = latency;
          } else {
             _nodePings[node.id] = -1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nodePings[node.id] = -1; 
        });
      }
    }
  }

  /// 加载订阅信息
  Future<void> _loadSubscription() async {
    try {
      print('[Dashboard] Loading subscription...');
      
      try {
        final userInfo = await XboardUserService.getUserInfo();
        if (mounted) {
           setState(() {
             _user = userInfo;
           });
        }
      } catch (e) {
        print('[Dashboard] Load user info error: $e');
      }

      final subscriptions = await SubscribeService.getSubscriptionList();
      print('[Dashboard] Subscriptions loaded: ${subscriptions.length} items');
      if (subscriptions.isEmpty) {
        print('[Dashboard] No subscriptions, setting _subscription to null');
      } else {
        print('[Dashboard] First subscription: ${subscriptions.first.name}');
      }
      if (mounted) {
        setState(() {
          _subscription = subscriptions.isNotEmpty ? subscriptions.first : null;
        });
        print('[Dashboard] setState called, _subscription is now: ${_subscription == null ? "null" : "not null"}');
      }
    } catch (e) {
      print('[Dashboard] Load subscription error: $e');
    }
  }

  /// 检查是否有有效订阅
  bool _hasValidSubscription() {
    print('[Dashboard] _hasValidSubscription called, _subscription is: ${_subscription == null ? "null" : "not null"}');
    if (_subscription == null) {
      print('[Dashboard] _hasValidSubscription returning false (subscription is null)');
      return false;
    }
    // 检查订阅是否过期（expireTime 是 Unix 时间戳，单位是秒）
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isValid = _subscription!.expireTime > now;
    print('[Dashboard] _hasValidSubscription returning $isValid (expireTime: ${_subscription!.expireTime}, now: $now)');
    return isValid;
  }

  /// 检查并显示弹窗公告
  Future<void> _checkPopupAnnouncements() async {
    try {
      // 如果本次会话已经显示过弹窗，则跳过
      if (_hasShownPopupThisSession) {
        print('[Dashboard] Popup already shown this session, skipping');
        return;
      }

      // 延迟一点时间，确保界面已经完全加载
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 获取所有公告
      final announcements = await AnnouncementService.getAnnouncements(
        page: 1,
        size: 99,
      );

      // 过滤出弹窗类公告
      final popupAnnouncements = announcements.where((a) => a.popup).toList();

      if (popupAnnouncements.isEmpty || !mounted) return;

      // 每次启动都显示最新的弹窗公告（列表第一个）
      final latestAnnouncement = popupAnnouncements.first;

      print('[Dashboard] Showing latest popup announcement: ${latestAnnouncement.id}');

      // 显示弹窗
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => PopupAnnouncementDialog(
            announcement: latestAnnouncement,
          ),
        );

        // 标记本次会话已显示过弹窗
        _hasShownPopupThisSession = true;
        print('[Dashboard] Popup announcement ${latestAnnouncement.id} shown');
      }
    } catch (e) {
      print('[Dashboard] Check popup announcements error: $e');
      // 不影响主流程，静默失败
    }
  }

  /// 显示节点选择对话框
  void _showNodeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => NodeSelectionDialog(
        initialSelectedProxy: _selectedNode?.name,
        onProxySelected: _handleInternalNodeSelection,
      ),
    );
  }

  void _handleInternalNodeSelection(String groupName, String proxyName) {
    if (proxyName == _getResolvedAutoNodeName() || proxyName == 'Auto' || proxyName == '自动选择') {
       // User selected "Auto" explicitly
       setState(() {
         // Auto is virtual node
         _selectedNode = VpnNode.auto();
         _isAutoSelected = true;
       });
       // Do not call onNodeSelected for Auto? Or do we?
       // Usually we just use local state for Auto.
       print('[Dashboard] Selected Auto mode');
    } else {
      VpnNode? node = _findNodeByName(proxyName);
      if (node != null) {
        setState(() {
          _selectedNode = node;
          _isAutoSelected = false;
        });
        widget.onNodeSelected?.call(node);
        print('[Dashboard] Selected node: ${node.name}, Country: "${node.country}"');
      } else {
        print('[Dashboard] Selected node not found in list: $proxyName');
        // If not found in our list, it might be a special node or we need to reload?
        // Create a temporary node to show
        setState(() {
          _selectedNode = VpnNode(
             id: 0, 
             name: proxyName, 
             uuid: '', 
             protocol: 'unknown', 
             serverAddr: '', 
             serverPort: 0, 
             config: '', 
             country: 'XX', // We don't know the country easily here...
             tags: [], 
             speedLimit: 0, 
             trafficRatio: 1
          );
           _isAutoSelected = false;
        });
        print('[Dashboard] Created temporary node for: $proxyName with Country XX');
      }
    }
    
    // Save selection logic is handled by VpnService.saveGroupSelection/FlClash internally
    // We just update UI here.
    
    // Ping the new selection
    _pingDisplayNode();
  }

  /// Pre-calculate a fallback node name from static config
  Future<void> _resolveFallbackAutoNode() async {
    try {
      final groups = await SubscribeService.getRoutingGroups();
      final targetNames = ['Auto', 'Url-Test', 'Automatic', '自动选择', '🚀 Proxy', 'Proxy'];
      
      for (var name in targetNames) {
         final group = groups.firstWhereOrNull((g) => g.name.toLowerCase().contains(name.toLowerCase()));
         if (group != null && group.options.isNotEmpty) {
           final firstOption = group.options.first;
           if (mounted) {
             setState(() {
               _fallbackAutoNodeName = firstOption;
             });
             _pingDisplayNode(); // Force ping immediately
           }
           return;
         }
      }
    } catch (e) {
      print('[Dashboard] Resolve fallback error: $e');
    }
  }

  /// 启动计时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (VpnService.isConnected && mounted) {
        setState(() {
          _connectionDuration += const Duration(seconds: 1);
        });
        
        // Refresh latency every 5 seconds
        if (timer.tick % 5 == 0) {
          _pingDisplayNode();
        }
      }
    });
  }

  /// 启动订阅信息刷新计时器 (每60秒刷新一次)
  void _startSubscriptionRefreshTimer() {
    _subscriptionRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        print('[Dashboard] Auto-refreshing subscription data...');
        _loadSubscription();
      }
    });
  }

  /// 重新连接到新节点（断开当前连接并连接到新节点）
  Future<void> _reconnectToNewNode() async {
    if (_selectedNode == null) return;

    print('[Dashboard] Reconnecting to new node: ${_selectedNode!.name}');
    print('[Dashboard] Current proxy mode: ${_proxyMode.label}');

    setState(() => _isConnecting = true);

    // 先断开当前连接
    await VpnService.disconnect();

    // 连接到新节点，保持当前的代理模式
    VpnService.setProxyMode(_proxyMode);
    print('[Dashboard] Set VpnService proxy mode to: ${_proxyMode.label}');
    final success = await VpnService.connect(_selectedNode!);

    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (success) {
          _connectionDuration = Duration.zero;
        } else {
          _showErrorDialog('切换节点失败: ${VpnService.lastError}');
        }
      });
      if (success) {
        // 动画由 build 方法的 provider watch 控制
        _loadSubscription();
      }
    }
  }

  /// 连接/断开 VPN
  Future<void> _toggleConnection() async {
    final isConnected = VpnService.isConnected;
    if (isConnected) {
      // 断开连接
      setState(() => _isConnecting = true);
      await VpnService.disconnect();
      setState(() {
        _isConnecting = false;
        _connectionDuration = Duration.zero;
      });
      // 动画由 build 方法的 provider watch 控制
      _loadSubscription();
    } else {
      // 连接 VPN
      if (_selectedNode == null) {
        _showErrorDialog('请先选择一个节点');
        return;
      }

      setState(() => _isConnecting = true);
      VpnService.setProxyMode(_proxyMode);
      final success = await VpnService.connect(_selectedNode!);

      if (mounted) {
        setState(() {
          _isConnecting = false;
          if (!success) {
            _showErrorDialog('连接失败: ${VpnService.lastError}');
          }
        });
        if (success) {
          // 动画由 build 方法的 provider watch 控制
          _loadSubscription();
        }
      }
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 切换代理模式
  Future<void> _switchProxyMode(ProxyMode mode) async {
    if (mode == _proxyMode) return;

    final wasConnected = VpnService.isConnected;
    final currentNode = _selectedNode;

    // 更新模式
    setState(() {
      _proxyMode = mode;
    });
    VpnService.setProxyMode(mode);

    // 如果已连接，断开后重新连接以应用新模式
    if (wasConnected && currentNode != null) {
      setState(() => _isConnecting = true);

      await VpnService.disconnect();

      // 短暂延迟确保断开完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 重新连接
      final success = await VpnService.connect(currentNode);

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        if (!success) {
          _connectionDuration = Duration.zero;
          _showErrorDialog('重连失败: ${VpnService.lastError ?? "未知错误"}');
        }
      });
      if (success) {
        _startTimer();
        // 重连成功后刷新订阅信息
        _loadSubscription();
      }
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  /// 检查是否是信息提示节点（需要过滤掉）
  bool _isInfoNode(String name) {
    return name.contains('剩余流量') ||
           name.contains('套餐到期') ||
           name.contains('距离') ||
           name.contains('重置') ||
           name.contains('到期时间') ||
           name.contains('过期') ||
           (name.contains('流量') && name.contains('GB'));
  }

  /// 获取 Auto 节点实际使用的节点名称
  String _getResolvedAutoNodeName() {
    try {
      final groups = globalState.appController.getCurrentGroups();

      // 1. First priority: Find group by Type (URLTest)
      try {
        final urlTestGroup = groups.firstWhere(
          (g) => g.type == GroupType.URLTest,
          orElse: () => Group(name: '', type: GroupType.Selector, all: [], now: '')
        );
        if (urlTestGroup.name.isNotEmpty) {
           // 检查 now 是否是信息节点
           if (urlTestGroup.now != null && urlTestGroup.now!.isNotEmpty && !_isInfoNode(urlTestGroup.now!)) {
             return urlTestGroup.now!;
           }
           // Fallback to first non-info node in the group
           final validNodes = urlTestGroup.all.where((p) => !_isInfoNode(p.name)).toList();
           if (validNodes.isNotEmpty) {
             return validNodes.first.name;
           }
        }
      } catch (_) {}

      // 2. Second priority: Find Url-Test group by name
      final targetNames = ['Auto', 'Url-Test', 'Automatic', '自动选择', '🚀 Proxy', 'Proxy'];

      for (var name in targetNames) {
        try {
          final group = groups.firstWhere(
            (g) => g.name.toLowerCase().contains(name.toLowerCase()),
            orElse: () => Group(name: '', type: GroupType.Selector, all: [], now: '')
          );
          if (group.name.isNotEmpty) {
             // 检查 now 是否是信息节点
             if (group.now != null && group.now!.isNotEmpty && !_isInfoNode(group.now!)) {
               return group.now!;
             }
             // Fallback to first non-info node
             final validNodes = group.all.where((p) => !_isInfoNode(p.name)).toList();
             if (validNodes.isNotEmpty) {
               return validNodes.first.name;
             }
          }
        } catch (_) {}
      }
    } catch (e) {
      print('[Dashboard] Resolve Auto node error: $e');
    }

    // 3. Last priority: Use statically resolved fallback
    if (_fallbackAutoNodeName.isNotEmpty && !_isInfoNode(_fallbackAutoNodeName)) {
      return _fallbackAutoNodeName;
    }

    return '';
  }

  /// 根据名称查找节点对象
  VpnNode? _findNodeByName(String name) {
    if (name.isEmpty) return null;
    try {
      return _nodes.firstWhere((n) => n.name.trim() == name.trim());
    } catch (_) {
      return null;
    }
  }

  /// Get the latency value to display
  int? _getDisplayLatency() {
    // If manually selected node is NOT auto (id -1)
    if (_selectedNode != null && _selectedNode!.id != -1) {
      if (_nodePings.containsKey(_selectedNode!.id)) {
        return _nodePings[_selectedNode!.id];
      }
      return null;
    }
    
    // If Auto is selected, try to find the resolved node
    final resolvedName = _getResolvedAutoNodeName();
    if (resolvedName.isNotEmpty) {
       final node = _findNodeByName(resolvedName);
       if (node != null && _nodePings.containsKey(node.id)) {
         return _nodePings[node.id];
       }
    }
    
    // Fallback: match the text display logic (first node)
    if (_nodes.isNotEmpty) {
       return _nodePings[_nodes.first.id];
    }
    
    return null;
  }

  /// 获取国旗 emoji
  String _getCountryFlag(String country) {
    const Map<String, String> countryFlags = {
      'US': '🇺🇸', 'USA': '🇺🇸',
      'JP': '🇯🇵', 'JPN': '🇯🇵',
      'SG': '🇸🇬', 'SGP': '🇸🇬',
      'GB': '🇬🇧', 'UK': '🇬🇧',
      'DE': '🇩🇪', 'DEU': '🇩🇪',
      'AU': '🇦🇺', 'AUS': '🇦🇺',
      'CA': '🇨🇦', 'CAN': '🇨🇦',
      'HK': '🇭🇰', 'HKG': '🇭🇰',
      'TW': '🇹🇼', 'TWN': '🇹🇼',
      'KR': '🇰🇷', 'KOR': '🇰🇷',
      'FR': '🇫🇷', 'FRA': '🇫🇷',
      'NL': '🇳🇱', 'NLD': '🇳🇱',
      'VN': '🇻🇳', 'VNM': '🇻🇳',
      'TH': '🇹🇭', 'THA': '🇹🇭',
      'ID': '🇮🇩', 'IDN': '🇮🇩',
      'MY': '🇲🇾', 'MYS': '🇲🇾',
      'PH': '🇵🇭', 'PHL': '🇵🇭',
      'IN': '🇮🇳', 'IND': '🇮🇳',
      'RU': '🇷🇺', 'RUS': '🇷🇺',
      'BR': '🇧🇷', 'BRA': '🇧🇷',
      'AR': '🇦🇷', 'ARG': '🇦🇷',
      'MX': '🇲🇽', 'MEX': '🇲🇽',
      'IT': '🇮🇹', 'ITA': '🇮🇹',
      'ES': '🇪🇸', 'ESP': '🇪🇸',
      'SE': '🇸🇪', 'SWE': '🇸🇪',
      'NO': '🇳🇴', 'NOR': '🇳🇴',
      'DK': '🇩🇰', 'DNK': '🇩🇰',
      'FI': '🇫🇮', 'FIN': '🇫🇮',
      'CH': '🇨🇭', 'CHE': '🇨🇭',
      'AT': '🇦🇹', 'AUT': '🇦🇹',
      'BE': '🇧🇪', 'BEL': '🇧🇪',
      'PL': '🇵🇱', 'POL': '🇵🇱',
      'CZ': '🇨🇿', 'CZE': '🇨🇿',
      'TR': '🇹🇷', 'TUR': '🇹🇷',
      'ZA': '🇿🇦', 'ZAF': '🇿🇦',
      'EG': '🇪🇬', 'EGY': '🇪🇬',
      'IL': '🇮🇱', 'ISR': '🇮🇱',
      'AE': '🇦🇪', 'ARE': '🇦🇪',
      'SA': '🇸🇦', 'SAU': '🇸🇦',
      'CN': '🇨🇳', 'CHN': '🇨🇳',
      'NZ': '🇳🇿', 'NZL': '🇳🇿',
    };

    return countryFlags[country.toUpperCase()] ?? '🌐';
  }

  /// 构建延迟指示器
  Widget _buildLatencyIndicator(int? ping) {
    if (ping == null) {
      // 正在测试
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.textLightTertiary,
            ),
          ),
        ],
      );
    }

    if (ping == -1) {
      // 超时/错误
      return const Text(
        'Timeout',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.error,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // 根据延迟确定颜色
    Color latencyColor;
    if (ping < 150) {
      latencyColor = Colors.green;
    } else if (ping < 300) {
      latencyColor = Colors.orange;
    } else {
      latencyColor = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.signal_cellular_alt,
          size: 14,
          color: latencyColor,
        ),
        const SizedBox(width: 3),
        Text(
          '${ping}ms',
          style: TextStyle(
            fontSize: 11,
            color: latencyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 从 FlClash 的 runTimeProvider 获取连接状态
    final isConnected = ref.watch(runTimeProvider) != null;
    
    // 根据连接状态控制动画
    if (isConnected && _waveController1.isAnimating) {
      _stopWaveAnimation();
    } else if (!isConnected && !_waveController1.isAnimating && !_isConnecting) {
      _startWaveAnimation();
    }
    
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // 主内容区域 - 连接控制（带地图背景）
          Expanded(
            child: Stack(
              children: [
                // 背景 - 世界地图
                Positioned.fill(
                  child: WorldMapBackgroundV2(
                    opacity: 0.3, // 模糊效果（降低透明度）
                    connectedNodeCountry: isConnected && _selectedNode != null
                        ? (() {
                            String c = _selectedNode!.id == -1 || _isAutoSelected 
                                ? _findNodeByName(_getResolvedAutoNodeName())?.country ?? 'XX'
                                : _selectedNode!.country;
                            
                            // 再次尝试从名称解析，防止为空
                            if (c.isEmpty || c == 'XX') {
                                final name = _selectedNode!.id == -1 || _isAutoSelected 
                                    ? _getResolvedAutoNodeName() 
                                    : _selectedNode!.name;
                                c = _resolveCountryFromName(name);
                            }
                            return c;
                          })()
                        : null,
                  ),
                ),
                
                if (isConnected && _selectedNode != null)
                  Positioned(
                    top: 20,
                    left: 24,
                    child: Text(
                      'Connected', 
                      style: TextStyle(
                        color: AppTheme.success, 
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: AppTheme.success.withOpacity(0.5),
                            blurRadius: 10,
                          )
                        ]
                      )
                    ),
                  ),

                // 待支付订单提醒 (置顶显示)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PendingOrderAlert(
                       onNavigateToOrderList: () {
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (_) => const OrderListScreen(isEmbedded: false)),
                         );
                       },
                    ),
                  ),
                ),
                
                // 连接控制内容
                Center(
                  child: SingleChildScrollView(
                    child: _buildConnectionArea(isConnected),
                  ),
                ),

                // 右上角公告按钮
                Positioned(
                  top: 20,
                  right: 24,
                  child: _buildAnnouncementButton(),
                ),
              ],
            ),
          ),

          // 底部 - 套餐信息卡片（仅在有有效订阅时显示）
          if (_hasValidSubscription())
            Container(
              color: AppTheme.bgLight,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SubscriptionCard(
                subscription: _subscription,
                user: _user,
                onNavigateToPlans: widget.onNavigateToPlans,
              ),
            ),
        ],
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildTopBar(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 连接状态
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? AppTheme.success : AppTheme.textLightTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? '已连接' : '未连接',
                style: TextStyle(
                  color: isConnected ? AppTheme.success : AppTheme.textLightSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // IP 隐藏状态
          Text(
            'IP: ${isConnected ? "已隐藏" : "未隐藏"}',
            style: const TextStyle(
              color: AppTheme.textLightSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 连接控制区域
  Widget _buildConnectionArea(bool isConnected) {
    // 检查是否有有效订阅
    if (!_hasValidSubscription()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '暂无有效套餐',
              style: TextStyle(
                color: AppTheme.textLightPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '购买套餐后即可开始使用',
              style: TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onNavigateToPlans,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgDarkest, // 深色按钮
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '购买套餐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 有有效订阅时显示原来的连接区域
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 大连接按钮（包含状态和时间）
          _buildConnectionButton(isConnected),

          const SizedBox(height: 24),

          // 提示文字或节点信息
          if (_selectedNode != null)
            GestureDetector(
              onTap: _showNodeSelectionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgLightCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 自动选择标识 - 已移除
                    // if (_isAutoSelected) ...
                    // 国旗
                    Text(
                      _selectedNode!.id == -1 && _getResolvedAutoNodeName().isNotEmpty
                          ? _getCountryFlag(_findNodeByName(_getResolvedAutoNodeName())?.country ?? 'XX')
                          : _getCountryFlag(_selectedNode!.country),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    // 节点名 (如果是Auto且已解析出实际节点，显示实际节点名)
                    Flexible(
                      child: Text(
                        _selectedNode!.id == -1
                            ? (_getResolvedAutoNodeName().isNotEmpty
                                ? _getResolvedAutoNodeName()
                                : (_nodes.where((n) => !_isInfoNode(n.name)).firstOrNull?.name ?? 'Loading...'))
                            : (_isInfoNode(_selectedNode!.name) ? _getResolvedAutoNodeName() : _selectedNode!.name),
                        style: const TextStyle(
                          color: AppTheme.textLightSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 延迟状态
                    _buildLatencyIndicator(_getDisplayLatency()),
                    const SizedBox(width: 12),
                    // 切换节点按钮
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.bgDarkest.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '切换',
                        style: TextStyle(
                          color: AppTheme.bgDarkest,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _showNodeSelectionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgLightCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isPingingNodes ? '正在测试节点...' : '请选择节点',
                      style: const TextStyle(
                        color: AppTheme.textLightSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 切换节点按钮
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.bgDarkest.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '选择',
                        style: TextStyle(
                          color: AppTheme.bgDarkest,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // 模式切换按钮
          _buildModeSelector(),
        ],
      ),
    );
  }

  /// 大连接按钮 - 带光波扩散效果
  Widget _buildConnectionButton(bool isConnected) {
    // 图标和文字始终为白色
    final buttonColor = Colors.white;

    final borderColor = isConnected
        ? AppTheme.success
        : AppTheme.border;

    // 悬停时整体放大，按下时缩小
    final double finalScale = _isButtonHovered && !_isConnecting ? 1.05 : _buttonScale;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          if (!_isConnecting) {
            setState(() => _buttonScale = 0.95);
          }
        },
        onTapUp: (_) {
          setState(() => _buttonScale = 1.0);
          if (!_isConnecting) _toggleConnection();
        },
        onTapCancel: () => setState(() => _buttonScale = 1.0),
        child: AnimatedScale(
          scale: finalScale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 光波层 - 仅在未连接状态显示
                if (!isConnected) ...[
                  _buildWaveRing(_waveAnimation1, borderColor, 1),
                  _buildWaveRing(_waveAnimation2, borderColor, 2),
                  _buildWaveRing(_waveAnimation3, borderColor, 3),
                ],

                // 主按钮
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? AppTheme.success
                        : const Color(0xFF1A1D2E),
                    border: Border.all(
                      color: borderColor,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: _isConnecting
                        ? SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 电源图标
                              Icon(
                                Icons.power_settings_new_rounded,
                                size: 56,
                                color: buttonColor,
                              ),
                              const SizedBox(height: 12),
                              // 状态文字
                              Text(
                                isConnected ? '已连接' : '点击连接',
                                style: TextStyle(
                                  color: buttonColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              // 连接时间（仅在已连接时显示）
                              if (isConnected) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _formatDuration(_connectionDuration),
                                  style: TextStyle(
                                    color: buttonColor.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建光波环
  Widget _buildWaveRing(Animation<double> animation, Color color, int index) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        // 恢复原来的效果：从内部 (140) 开始向外扩散
        // 范围稍微大一点：原来的增量是 80 (到220)，现在增加到 120 (到260)
        final size = 140 + (120 * progress);
        final opacity = (1.0 - progress) * 0.5;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  /// 模式选择器
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            icon: Icons.auto_mode_rounded,
            label: '智能',
            mode: ProxyMode.smart,
            isSelected: _proxyMode == ProxyMode.smart,
          ),
          const SizedBox(width: 6),
          _buildModeButton(
            icon: Icons.public_rounded,
            label: '全局',
            mode: ProxyMode.global,
            isSelected: _proxyMode == ProxyMode.global,
          ),
        ],
      ),
    );
  }

  /// 模式按钮
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required ProxyMode mode,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _isConnecting ? null : () => _switchProxyMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.bgDarkest : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textLightSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textLightPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 公告按钮
  Widget _buildAnnouncementButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const AnnouncementDialog(),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.notifications_rounded,
              color: AppTheme.textLightSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  String _resolveCountryFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('hongkong') || lowerName.contains('hong kong') || lowerName.contains('hk') || name.contains('香港')) return 'HK';
    if (lowerName.contains('taiwan') || lowerName.contains('tw') || name.contains('台湾')) return 'TW';
    if (lowerName.contains('japan') || lowerName.contains('jp') || name.contains('日本')) return 'JP';
    if (lowerName.contains('singapore') || lowerName.contains('sg') || name.contains('新加坡')) return 'SG';
    if (lowerName.contains('korea') || lowerName.contains('kr') || name.contains('韩国')) return 'KR';
    if (lowerName.contains('united states') || lowerName.contains('us') || lowerName.contains('america') || name.contains('美国')) return 'US';
    if (lowerName.contains('united kingdom') || lowerName.contains('uk') || lowerName.contains('britain') || name.contains('英国')) return 'GB';
    if (lowerName.contains('germany') || lowerName.contains('de') || name.contains('德国')) return 'DE';
    if (lowerName.contains('france') || lowerName.contains('fr') || name.contains('法国')) return 'FR';
    if (lowerName.contains('canada') || lowerName.contains('ca') || name.contains('加拿大')) return 'CA';
    if (lowerName.contains('australia') || lowerName.contains('au') || name.contains('澳大利亚')) return 'AU';
    if (lowerName.contains('russia') || lowerName.contains('ru') || name.contains('俄罗斯')) return 'RU';
    if (lowerName.contains('india') || lowerName.contains('in') || name.contains('印度')) return 'IN';
    if (lowerName.contains('netherlands') || lowerName.contains('nl') || name.contains('荷兰')) return 'NL';
    if (lowerName.contains('turkey') || lowerName.contains('tr') || name.contains('土耳其')) return 'TR';
    if (lowerName.contains('brazil') || lowerName.contains('br') || name.contains('巴西')) return 'BR';
    if (lowerName.contains('argentina') || lowerName.contains('ar') || name.contains('阿根廷')) return 'AR';
    if (lowerName.contains('philippines') || lowerName.contains('ph') || name.contains('菲律宾')) return 'PH';
    if (lowerName.contains('vietnam') || lowerName.contains('vn') || name.contains('越南')) return 'VN';
    if (lowerName.contains('thailand') || lowerName.contains('th') || name.contains('泰国')) return 'TH';
    if (lowerName.contains('malaysia') || lowerName.contains('my') || name.contains('马来西亚')) return 'MY';
    if (lowerName.contains('indonesia') || lowerName.contains('id') || name.contains('印度尼西亚')) return 'ID';
    return 'XX';
  }
}
