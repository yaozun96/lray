import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/services/vpn_service.dart';
import 'package:fl_clash/soravpn_ui/screens/auth_screen.dart';
import 'package:fl_clash/soravpn_ui/models/proxy_mode.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final VpnNode? initialSelectedNode;
  final Function(VpnNode)? onNodeSelected;

  const HomeScreen({
    super.key,
    this.initialSelectedNode,
    this.onNodeSelected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  List<VpnNode> _nodes = [];
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedNodeId;
  bool _isConnected = false;
  bool _singBoxInstalled = false;
  String? _singBoxVersion;
  ProxyMode _proxyMode = ProxyMode.smart;

  // Ping latency for each node
  Map<int, int> _nodePings = {}; // node.id -> latency in ms
  bool _isPingingAll = false;

  // Hover state for node cards
  int? _hoveredNodeId;

  @override
  void initState() {
    super.initState();
    // 使用初始选中的节点
    _selectedNodeId = widget.initialSelectedNode?.id;
    _loadData();
    _checkSingBox();
  }

  Future<void> _checkSingBox() async {
    final installed = await VpnService.isSingBoxInstalled();
    final version = await VpnService.getSingBoxVersion();
    setState(() {
      _singBoxInstalled = installed;
      _singBoxVersion = version;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await AuthService.getUserData();
      final nodes = await SubscribeService.getNodeList();
      final subscriptions = await SubscribeService.getSubscriptionList();

      setState(() {
        _userData = userData;
        _nodes = nodes;
        _subscriptions = subscriptions;
        _isLoading = false;
      });

      // Auto-test latency after loading nodes
      if (nodes.isNotEmpty) {
        _pingAllNodes();
      }
    } catch (e) {
      // Check if token expired
      if (e.toString().contains('TOKEN_EXPIRED')) {
        await AuthService.logout();
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pingNode(VpnNode node) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Try to resolve the host first
      final host = node.serverAddr.contains(':')
          ? node.serverAddr.split(':')[0]
          : node.serverAddr;

      // Use ping command (works on macOS/Linux)
      final result = await Process.run(
        'ping',
        ['-c', '1', '-W', '2000', host],
      ).timeout(const Duration(seconds: 3));

      stopwatch.stop();

      if (result.exitCode == 0) {
        // Parse ping output to get actual latency
        final output = result.stdout.toString();
        final match = RegExp(r'time=(\d+\.?\d*)').firstMatch(output);
        if (match != null) {
          final latency = double.parse(match.group(1)!).round();
          setState(() {
            _nodePings[node.id] = latency;
          });
        } else {
          setState(() {
            _nodePings[node.id] = stopwatch.elapsedMilliseconds;
          });
        }
      } else {
        setState(() {
          _nodePings[node.id] = -1; // Timeout
        });
      }
    } catch (e) {
      setState(() {
        _nodePings[node.id] = -1; // Error
      });
    }
  }

  Future<void> _pingAllNodes() async {
    setState(() {
      _isPingingAll = true;
      _nodePings.clear();
    });

    // Ping all nodes concurrently (but limit concurrency)
    final futures = <Future>[];
    for (var node in _nodes) {
      futures.add(_pingNode(node));
      // Add small delay to avoid overwhelming the system
      if (futures.length >= 5) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    setState(() {
      _isPingingAll = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _handleConnect(VpnNode node) async {
    // Check if disconnecting
    if (_isConnected && _selectedNodeId == node.id) {
      setState(() => _isLoading = true);

      await VpnService.disconnect();

      setState(() {
        _isConnected = false;
        _selectedNodeId = null;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接')),
      );
      return;
    }

    // Connecting to VPN
    setState(() => _isLoading = true);

    try {
      final success = await VpnService.connect(node);

      if (success) {
        setState(() {
          _isConnected = true;
          _selectedNodeId = node.id;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已连接到 ${node.name}')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: ${VpnService.lastError ?? "未知错误"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接错误: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.bgDarkest))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载数据失败',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.bgDarkest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (!_singBoxInstalled) _buildSingBoxWarning(),
                      const SizedBox(height: 12),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            const Spacer(),
                            // Test latency button
                            InkWell(
                              onTap: _isPingingAll ? null : _pingAllNodes,
                              borderRadius: BorderRadius.circular(6),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isPingingAll
                                      ? AppTheme.bgDarkest.withValues(alpha: 0.5)
                                      : AppTheme.bgDarkest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isPingingAll
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.speed, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPingingAll ? '测试中...' : '测试延迟',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Refresh button
                            InkWell(
                              onTap: _loadData,
                              borderRadius: BorderRadius.circular(6),
                              child: Ink(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDarkest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _nodes.isEmpty
                            ? const Center(
                                child: Text(
                                  '暂无可用节点',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _nodes.length,
                                itemBuilder: (context, index) {
                                  return _buildNodeCard(_nodes[index]);
                                },
                              ),
                      ),
                    ],
                  )
    );
  }

  Widget _buildSingBoxWarning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade400,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sing-box 未安装',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '请安装 Sing-box 以使用 VPN 功能:\nbrew install sing-box',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade200,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _checkSingBox,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade300,
            ),
            child: const Text('重新检查'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription sub) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgDarkest, AppTheme.bgDarkest],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bgDarkest.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_membership, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                sub.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '流量使用',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sub.formatTraffic(sub.upload + sub.download)} / ${sub.formatTraffic(sub.traffic)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '到期时间',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sub.getExpireDays()} 天',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sub.usagePercentage / 100,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(
                sub.usagePercentage > 80 ? Colors.red : Colors.green,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(VpnNode node) {
    final isSelected = _selectedNodeId == node.id;
    final isConnectedToThis = _isConnected && isSelected;
    final ping = _nodePings[node.id];
    final isHovered = _hoveredNodeId == node.id;

    // 在节点选择模式下（有回调），显示选中的节点；否则显示已连接的节点
    final shouldHighlight = widget.onNodeSelected != null ? isSelected : isConnectedToThis;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNodeId = node.id),
      onExit: (_) => setState(() => _hoveredNodeId = null),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHovered
              ? AppTheme.bgLightCard.withValues(alpha: 0.7)
              : AppTheme.bgLightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: shouldHighlight
                ? AppTheme.bgDarkest
                : (isHovered ? AppTheme.border.withValues(alpha: 0.8) : AppTheme.border),
            width: shouldHighlight ? 2 : 1,
          ),
          boxShadow: shouldHighlight
              ? [
                  BoxShadow(
                    color: AppTheme.bgDarkest.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : isHovered
                  ? [
                      BoxShadow(
                        color: AppTheme.bgDarkest.withValues(alpha: 0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
        ),
        child: InkWell(
          onTap: () {
            // 如果有节点选择回调，则使用回调（用于仪表盘选择）
            if (widget.onNodeSelected != null) {
              setState(() {
                _selectedNodeId = node.id;
              });
              widget.onNodeSelected!(node);
            } else {
              // 否则使用原有的连接逻辑
              _handleConnect(node);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Country flag (placeholder - using emoji or icon)
                _buildCountryFlag(node.country),
                const SizedBox(width: 16),
                // Node info
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLightPrimary,
                    ),
                  ),
                ),
                // Latency display
                _buildLatencyBadge(ping),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryFlag(String country) {
    // Map country codes and names to flag emojis
    const Map<String, String> countryFlags = {
      // Country codes
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
      'MY': '🇲🇾', 'MYS': '🇲🇾',
      'IN': '🇮🇳', 'IND': '🇮🇳',
      'ID': '🇮🇩', 'IDN': '🇮🇩',
      'PH': '🇵🇭', 'PHL': '🇵🇭',
      'RU': '🇷🇺', 'RUS': '🇷🇺',
      'BR': '🇧🇷', 'BRA': '🇧🇷',
      'AR': '🇦🇷', 'ARG': '🇦🇷',
      'MX': '🇲🇽', 'MEX': '🇲🇽',
      'IT': '🇮🇹', 'ITA': '🇮🇹',
      'ES': '🇪🇸', 'ESP': '🇪🇸',
      'CH': '🇨🇭', 'CHE': '🇨🇭',
      'SE': '🇸🇪', 'SWE': '🇸🇪',
      'NO': '🇳🇴', 'NOR': '🇳🇴',
      'FI': '🇫🇮', 'FIN': '🇫🇮',
      'DK': '🇩🇰', 'DNK': '🇩🇰',
      'PL': '🇵🇱', 'POL': '🇵🇱',
      'TR': '🇹🇷', 'TUR': '🇹🇷',
      'AE': '🇦🇪', 'ARE': '🇦🇪',
      'SA': '🇸🇦', 'SAU': '🇸🇦',
      'IL': '🇮🇱', 'ISR': '🇮🇱',
      'ZA': '🇿🇦', 'ZAF': '🇿🇦',
      'EG': '🇪🇬', 'EGY': '🇪🇬',
      'CN': '🇨🇳', 'CHN': '🇨🇳',
      // Chinese names
      '美国': '🇺🇸',
      '日本': '🇯🇵',
      '新加坡': '🇸🇬',
      '英国': '🇬🇧',
      '德国': '🇩🇪',
      '澳大利亚': '🇦🇺',
      '加拿大': '🇨🇦',
      '香港': '🇭🇰',
      '台湾': '🇹🇼',
      '韩国': '🇰🇷',
      '法国': '🇫🇷',
      '荷兰': '🇳🇱',
      '越南': '🇻🇳',
      // English names
      'United States': '🇺🇸',
      'Japan': '🇯🇵',
      'Singapore': '🇸🇬',
      'United Kingdom': '🇬🇧',
      'Germany': '🇩🇪',
      'Australia': '🇦🇺',
      'Canada': '🇨🇦',
      'Hong Kong': '🇭🇰',
      'Taiwan': '🇹🇼',
      'South Korea': '🇰🇷',
      'France': '🇫🇷',
      'Netherlands': '🇳🇱',
      'Vietnam': '🇻🇳',
    };

    final flag = countryFlags[country.toUpperCase()] ?? '🌐';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          flag,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildLatencyBadge(int? ping) {
    if (ping == null) {
      // Testing or not tested yet
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.textLightTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.textLightSecondary),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '测试中',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLightSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (ping == -1) {
      // Timeout or error
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: AppTheme.error),
            SizedBox(width: 4),
            Text(
              'Timeout',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Determine color based on latency
    Color latencyColor;
    if (ping < 150) {
      latencyColor = AppTheme.success;
    } else if (ping < 300) {
      latencyColor = AppTheme.warning;
    } else {
      latencyColor = AppTheme.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt, size: 16, color: latencyColor),
        const SizedBox(width: 4),
        Text(
          '${ping}ms',
          style: TextStyle(
            fontSize: 14,
            color: latencyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
