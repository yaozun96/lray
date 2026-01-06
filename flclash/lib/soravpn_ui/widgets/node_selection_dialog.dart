import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/common.dart';
import 'package:fl_clash/common/common.dart';

/// 节点选择对话框
/// 使用 FlClash 核心的代理组结构显示节点
class NodeSelectionDialog extends StatefulWidget {
  final String? initialSelectedProxy;
  final Function(String groupName, String proxyName) onProxySelected;

  const NodeSelectionDialog({
    super.key,
    this.initialSelectedProxy,
    required this.onProxySelected,
  });

  @override
  State<NodeSelectionDialog> createState() => _NodeSelectionDialogState();
}

class _NodeSelectionDialogState extends State<NodeSelectionDialog> {
  List<Group> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _hoveredIndex;
  bool _isTestingDelay = false;

  // 选中的组名
  String? _currentGroupName;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 只有在强制刷新时才同步订阅
      if (forceRefresh) {
        print('[NodeSelectionDialog] Force refreshing: syncing subscription to FlClash...');
        await SubscribeService.syncToFlClash();
        print('[NodeSelectionDialog] Sync completed, waiting for FlClash to process...');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        // 首次加载(非强制)：只从本地获取，加快速度
        // print('[NodeSelectionDialog] Loading local groups...');
        await Future.delayed(const Duration(milliseconds: 100)); 
      }

      // 刷新 groups (只更新状态，不从网络拉取)
      await globalState.appController.updateGroups();

      final groups = globalState.appController.getCurrentGroups();
      print('[NodeSelectionDialog] Got ${groups.length} groups from FlClash core');
      for (var g in groups) {
        print('[NodeSelectionDialog] Group: ${g.name}, type: ${g.type}, proxies: ${g.all.length}');
        if (g.all.isNotEmpty) {
          print('[NodeSelectionDialog]   First proxy: ${g.all.first.name}');
        }
      }

      if (mounted) {
        // 保存所有组，包括隐藏的，以便在展开节点时能找到对应的子组
        final allGroups = groups.where((g) => g.name != 'GLOBAL').toList();

        setState(() {
          _groups = allGroups;
          _isLoading = false;

          // 默认选中第一个 Selector 类型的组，或者名为 Proxy/节点选择 的组
          // 但在设置默认值时，我们要找一个"可见"的组
          if (_currentGroupName == null && allGroups.isNotEmpty) {
             final visibleGroups = allGroups.where((g) => g.hidden != true).toList();
             
             if (visibleGroups.isNotEmpty) {
                final proxyGroup = visibleGroups.firstWhere(
                  (g) => g.name == 'Proxy' || g.name == '节点选择' || g.name == '代理',
                  orElse: () => visibleGroups.firstWhere(
                    (g) => g.type == GroupType.Selector,
                    orElse: () => visibleGroups.first,
                  ),
                );
                _currentGroupName = proxyGroup.name;
             } else {
                _currentGroupName = allGroups.first.name;
             }
          }
        });
      }
    } catch (e) {
      print('[NodeSelectionDialog] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 获取当前选中组的节点列表（过滤掉信息提示节点）
  /// 获取当前选中组的节点列表（过滤掉信息提示节点）
  List<Proxy> get _currentProxies {
    if (_currentGroupName == null || _groups.isEmpty) return [];
    
    final group = _groups.firstWhere(
      (g) => g.name == _currentGroupName,
      orElse: () => _groups.first,
    );

    // 直接返回所有节点，不过滤，确保和 FlClash 原版一致
    return group.all;
  }

  /// 获取当前选中组
  Group? get _currentGroup {
    if (_currentGroupName == null || _groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.name == _currentGroupName,
      orElse: () => _groups.first,
    );
  }

  /// 测试当前组所有节点的延迟
  Future<void> _testAllDelays() async {
    if (_isTestingDelay) return;
    final proxies = _currentProxies;
    if (proxies.isEmpty) return;

    setState(() => _isTestingDelay = true);

    try {
      await delayTest(proxies);
    } finally {
      if (mounted) {
        setState(() => _isTestingDelay = false);
      }
    }
  }

  /// 获取组类型的显示名称
  String _getGroupTypeName(GroupType type) {
    switch (type) {
      case GroupType.Selector:
        return 'SELECT';
      case GroupType.URLTest:
        return '自动选择';
      case GroupType.Fallback:
        return '故障转移';
      case GroupType.LoadBalance:
        return '负载均衡';
      case GroupType.Relay:
        return '链式代理';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          height: 550,
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '选择节点',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textLightPrimary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _isTestingDelay || _isLoading ? null : _testAllDelays,
                          icon: _isTestingDelay
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.bolt_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: '测速',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _isLoading ? null : () => _loadGroups(forceRefresh: true),
                          icon: _isLoading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: '刷新',
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Group tabs (像 FlClash 那样显示组类型)
              if (_groups.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final visibleGroups = _groups.where((g) => g.hidden != true).toList();
                    return Container(
                      height: 44,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.border)),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: visibleGroups.length,
                        itemBuilder: (context, index) {
                          final group = visibleGroups[index];
                          final isSelected = group.name == _currentGroupName;
                          final typeName = _getGroupTypeName(group.type);
                          return GestureDetector(
                            onTap: () => setState(() => _currentGroupName = group.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected ? AppTheme.primaryDark : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                // 如果组名和类型名不同，显示组名；否则显示类型名
                                group.name == typeName ? typeName : group.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? AppTheme.primaryDark : AppTheme.textLightSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                ),
              ],

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: AppTheme.textLightSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadGroups, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(
        child: Text('暂无可用节点，请先同步订阅', style: TextStyle(color: AppTheme.textLightSecondary)),
      );
    }

    final proxies = _currentProxies;
    final group = _currentGroup;
    final currentSelected = group?.now ?? '';

    if (proxies.isEmpty) {
      return const Center(
        child: Text('该组暂无节点', style: TextStyle(color: AppTheme.textLightSecondary)),
      );
    }

    // 过滤掉套餐信息节点
    final filteredProxies = proxies.where((p) {
      final name = p.name;
      return !name.contains('剩余流量') && !name.contains('套餐到期') && !name.contains('距离下次重置');
    }).toList();

    if (filteredProxies.isEmpty) {
      return const Center(
        child: Text('该组暂无节点', style: TextStyle(color: AppTheme.textLightSecondary)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // 改为单列显示
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 5.5, // 调整宽高比以适应单列宽卡片 (宽度变宽了，高度相对要维持，所以比例变大)
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final proxy = filteredProxies[index];
                final isStrategy = proxy.type == 'URLTest' || proxy.type == 'Fallback' || proxy.name.contains('自动') || proxy.name.contains('故障');
                
                if (isStrategy) {
                  return _buildStrategyCard(proxy, currentSelected);
                } else {
                  return _buildNodeCard(proxy, currentSelected);
                }
              },
              childCount: filteredProxies.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyCard(Proxy proxy, String currentSelected) {
    final isSelected = proxy.name == currentSelected || proxy.name == _currentGroupName; 
    final isActive = proxy.name == currentSelected;

    // 尝试查找对应的 Group 对象以获取当前选中的节点 (now)
    final group = _groups.firstWhere(
      (g) => g.name == proxy.name, 
      orElse: () => Group(
        type: GroupType.Selector, 
        all: [], 
        name: proxy.name,
        now: proxy.now,
      ),
    );
    
    String subtitle = proxy.type;
    if (group.now != null && group.now!.isNotEmpty) {
      subtitle += '(${group.now})';
    }

    return GestureDetector(
      onTap: () async {
         if (_currentGroupName != null) {
           await globalState.appController.changeProxy(
             groupName: _currentGroupName!,
             proxyName: proxy.name,
           );
           widget.onProxySelected(_currentGroupName!, proxy.name);
           if (mounted) Navigator.of(context).pop();
         }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppTheme.bgLightSecondary : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.primaryDark : AppTheme.border,
            width: isActive ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 第一行：名称 + 延迟
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCountryFlag(proxy.name),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          proxy.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isActive ? AppTheme.primaryDark : AppTheme.textLightPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDelayText(proxy),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // 第二行：副标题 (类型+选中节点)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLightSecondary,
              ),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCard(Proxy proxy, String currentSelected) {
    final isSelected = proxy.name == currentSelected;
    
    return GestureDetector(
      onTap: () async {
        if (_currentGroupName != null) {
          await globalState.appController.changeProxy(
            groupName: _currentGroupName!,
            proxyName: proxy.name,
          );
          widget.onProxySelected(_currentGroupName!, proxy.name);
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bgLightSecondary : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 第一行：名称 + 延迟
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       _buildCountryFlag(proxy.name),
                       const SizedBox(width: 6),
                       Flexible(
                         child: Text(
                           proxy.name,
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 14,
                             color: isSelected ? AppTheme.primaryDark : AppTheme.textLightPrimary,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDelayText(proxy),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // 第二行：类型
            Text(
              proxy.type,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLightSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDelayText(Proxy proxy) {
    return Consumer(
      builder: (context, ref, _) {
        final delay = ref.watch(
          getDelayProvider(proxyName: proxy.name, testUrl: null),
        );
        if (delay == null) return const SizedBox.shrink();
        if (delay == 0) {
           return const SizedBox(
             width: 10, height: 10, 
             child: CircularProgressIndicator(strokeWidth: 1.5)
           );
        }
        return Text(
          delay > 0 ? '$delay ms' : 'Timeout',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: utils.getDelayColor(delay),
          ),
        );
      },
    );
  }

  Widget _buildCountryFlag(String proxyName) {
    // 简化版国旗构建，图标稍微调小一点适应网格
    final lowerName = proxyName.toLowerCase();
    String countryCode = 'XX';

    if (lowerName.contains('香港') || lowerName.contains('hk') || lowerName.contains('hong')) {
      countryCode = 'hk';
    } else if (lowerName.contains('台湾') || lowerName.contains('tw') || lowerName.contains('taiwan')) {
      countryCode = 'tw';
    } else if (lowerName.contains('日本') || lowerName.contains('jp') || lowerName.contains('japan')) {
      countryCode = 'jp';
    } else if (lowerName.contains('新加坡') || lowerName.contains('sg') || lowerName.contains('singapore')) {
      countryCode = 'sg';
    } else if (lowerName.contains('美国') || lowerName.contains('us') || lowerName.contains('america')) {
      countryCode = 'us';
    } else if (lowerName.contains('韩国') || lowerName.contains('kr') || lowerName.contains('korea')) {
      countryCode = 'kr';
    } else if (lowerName.contains('英国') || lowerName.contains('uk') || lowerName.contains('britain')) {
      countryCode = 'gb';
    } else if (lowerName.contains('德国') || lowerName.contains('de') || lowerName.contains('germany')) {
      countryCode = 'de';
    } else if (lowerName.contains('法国') || lowerName.contains('fr') || lowerName.contains('france')) {
      countryCode = 'fr';
    } else if (lowerName.contains('越南') || lowerName.contains('vn') || lowerName.contains('vietnam')) {
      countryCode = 'vn';
    } else if (lowerName.contains('泰国') || lowerName.contains('th') || lowerName.contains('thailand')) {
      countryCode = 'th';
    } else if (lowerName.contains('澳') || lowerName.contains('au') || lowerName.contains('australia')) {
      countryCode = 'au';
    } else if (lowerName.contains('auto') || lowerName.contains('自动')) {
      countryCode = 'AUTO';
    }

    if (countryCode == 'AUTO') {
      return const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primaryDark);
    }
    if (countryCode == 'XX') {
      return const Icon(Icons.public, size: 16, color: AppTheme.textLightSecondary);
    }

    // 使用 flagcdn 获取国旗图标
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        'https://flagcdn.com/w40/$countryCode.png',
        width: 20,
        height: 15,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
           return const Icon(Icons.public, size: 16, color: AppTheme.textLightSecondary);
        },
      ),
    );
  }
}
