import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/services/user_service.dart';
import 'package:fl_clash/soravpn_ui/services/subscribe_service.dart';
import 'package:fl_clash/soravpn_ui/screens/order_list_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/invite_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/account_security_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/store_screen.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/models/models.dart';
import 'dart:ui';
import 'package:fl_clash/soravpn_ui/models/xboard_user.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_user_service.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_subscribe.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_order_service.dart';
import 'package:fl_clash/soravpn_ui/screens/dialogs/payment_method_dialog.dart';
import '../widgets/recharge_dialog.dart';
import 'package:fl_clash/common/remote_config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/ticket/ticket_list_page.dart';
import 'order_detail_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String orderNo, bool fromCreate)? onNavigateToOrder;

  const SettingsScreen({super.key, this.onNavigateToOrder});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userInfo;
  Subscription? _subscription;
  String _currencySymbol = '¥';
  int _currentIndex = 0; // 0: Home, 1: Orders, 2: Account, 3: Invite

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = <Future>[
        AuthService.getUserInfo(), // Fetch fresh data from server
        SubscribeService.getSubscriptionList(),
        UserService.getSiteConfig(),
      ];

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _userInfo = results[0] as Map<String, dynamic>?;
          final subs = results[1] as List<Subscription>;
          _subscription = subs.isNotEmpty ? subs.first : null;
          
          final siteConfig = results[2] as Map<String, dynamic>;
           final c = siteConfig['currency'] ?? siteConfig['common']?['currency'] ?? {};
           _currencySymbol = (c['symbol'] ?? '¥').toString();
           
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           print('Load settings data error: $e');
           _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgLightSecondary,
        body: Center(child: CircularProgressIndicator()),
      );
    }


    return Scaffold(
      backgroundColor: AppTheme.bgLightSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('我的账户', style: TextStyle(color: AppTheme.textLightPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
           children: [
             _buildProfileHeader(),
             const SizedBox(height: 24),
             _buildMenuCard(),

           ],
         ),
      ),
    );
  }

  void _showContentDialog(String title, Widget content, {double? height}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: height ?? 600,
          ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.bgLightSecondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   decoration: const BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       IconButton(
                         onPressed: () => Navigator.pop(context),
                         icon: const Icon(Icons.close),
                       ),
                     ],
                   ),
                 ),
                 Flexible(
                   fit: FlexFit.loose,
                   child: ClipRRect(
                     borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                     child: content
                   ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final email = _userInfo?['email'] ?? 'User';
    final balance = _userInfo?['balance'] ?? 0;
    final planName = _subscription?.subscribe?.name ?? '无订阅';
    
    String expiryText = '长期有效';
    final expireTime = _subscription?.expireTime;
    if (expireTime != null && expireTime > 0) {
       final date = DateTime.fromMillisecondsSinceEpoch(expireTime * 1000);
       expiryText = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} 到期';
    } else if (_subscription == null) {
       expiryText = '未订阅';
    }
    
    String? avatarUrl = _userInfo?['avatar_url'];
    if (avatarUrl == null && email.isNotEmpty) {
      final bytes = utf8.encode(email.trim().toLowerCase());
      final digest = md5.convert(bytes);
      avatarUrl = 'https://www.gravatar.com/avatar/$digest?d=404';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 12, 
             offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        children: [
           // 1. Top Row: Avatar, Email, Balance, Recharge
           Row(
             children: [
                Container(
                  width: 48, 
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: avatarUrl != null 
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primary,
                                alignment: Alignment.center,
                                child: Text(
                                  email.isNotEmpty ? email[0].toUpperCase() : 'U', 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                                ),
                              );
                            },
                          )
                        : Container(
                             color: AppTheme.primary,
                             alignment: Alignment.center,
                             child: Text(
                               email.isNotEmpty ? email[0].toUpperCase() : 'U', 
                               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                             ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                         email,
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.foreground),
                         overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),
                ),
                // Balance and Recharge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_currencySymbol ${(balance / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.foreground),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6), // rose-100
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECDD3)), // rose-200
                          ),
                          child: const Text(
                            '最高赠50%',
                            style: TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () {
                               showDialog(
                                 context: context,
                                 builder: (dialogContext) => RechargeDialog(
                                   onOrderCreated: (tradeNo) {
                                     if (widget.onNavigateToOrder != null) {
                                       widget.onNavigateToOrder!(tradeNo, true);
                                     } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => OrderDetailScreen(
                                               orderNo: tradeNo,
                                               fromCreate: true,
                                            ),
                                          ),
                                        );
                                     }
                                   },
                                 ),
                               );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('充值', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
             ],
           ),
           
           const SizedBox(height: 16),
           const Divider(color: AppTheme.border, height: 1),
           const SizedBox(height: 16),
           
           // 2. Plan Info
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    const Text('当前套餐', style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                    const SizedBox(height: 4),
                    Text(planName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.foreground)),
                 ],
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    const Text('有效期至', style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                    const SizedBox(height: 4),
                    Text(expiryText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.foreground)),
                 ],
               ),
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
             color: const Color(0xFF0F2156).withOpacity(0.03), 
             blurRadius: 16, 
             offset: const Offset(0, 4)
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.data_usage_rounded,
            title: '流量明细',
            onTap: () => _showContentDialog(
              '流量明细', 
              _TrafficUsageView(userInfo: _userInfo ?? {}), 
              height: 400
            ),
          ),
          const Divider(height: 1, indent: 64),
          _buildMenuItem(
            icon: Icons.description_rounded, // Better match for "Orders"
            title: '我的订单',
            onTap: () => _showContentDialog('我的订单', const OrderListScreen(isEmbedded: true, showTitle: false), height: 600),
          ),
          const Divider(height: 1, indent: 64),
          _buildMenuItem(
            icon: Icons.confirmation_number_rounded, // Better match for "Tickets"
            title: '我的工单',
            onTap: () => _showContentDialog('我的工单', const TicketListPage(isEmbedded: true, showTitle: false), height: 600),
          ),
          const Divider(height: 1, indent: 64),
          _buildMenuItem(
            icon: Icons.lock_reset_rounded, // Keep lock reset
            title: '修改密码',
            onTap: () => _showContentDialog('修改密码', const AccountSecurityScreen(isEmbedded: true)),
          ),
          
          Container(height: 8, color: const Color(0xFFF8FAFC)), // Spacer
          
           _buildMenuItem(
            icon: Icons.telegram,
            title: '加入Telegram',
            onTap: () async {
              final url = RemoteConfigService.config?.telegramUrl ?? 'https://t.me/lray_io'; 
              if (await canLaunchUrl(Uri.parse(url))) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
          const Divider(height: 1, indent: 64),
           _buildMenuItem(
            icon: Icons.language,
            title: '官网',
            onTap: () async {
               final url = RemoteConfigService.config?.officialUrl ?? 'https://lray.dlgisea.com';
               if (await canLaunchUrl(Uri.parse(url))) {
                 launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
               }
            },
          ),
          // Removed Official Site to match screenshot
          const Divider(height: 1, indent: 64),
           _buildMenuItem(
            icon: Icons.logout_rounded,
            title: '退出登录',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: const Text('退出登录'),
                   content: const Text('确定要退出当前账号吗？'),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context),
                       child: const Text('取消', style: TextStyle(color: Colors.grey)),
                     ),
                     TextButton(
                       onPressed: () {
                         Navigator.pop(context);
                         _handleLogout();
                       },
                       child: const Text('退出', style: TextStyle(color: Colors.red)),
                     ),
                   ],
                 ),
               );
            },
          ),
        ],
      ),
    );
  }
  


  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primary).withOpacity(0.1), // Dynamic bg opacity
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(Icons.chevron_right, size: 18, color: textColor?.withOpacity(0.5) ?? AppTheme.textLightSecondary),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTrafficItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _TrafficUsageView extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  
  const _TrafficUsageView({required this.userInfo});

  @override
  State<_TrafficUsageView> createState() => _TrafficUsageViewState();
}

class _TrafficUsageViewState extends State<_TrafficUsageView> {
  bool _isLoading = true;
  List<TrafficRecord> _records = [];
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      const pageSize = 10;
      final logs = await XboardUserService.getTrafficLog(page: _page, pageSize: pageSize);
      if (mounted) {
        setState(() {
          if (_page == 1) {
            _records = logs;
          } else {
            _records.addAll(logs);
          }
          if (logs.length < pageSize) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String recordAt) {
    // Try parse as timestamp (seconds)
    final ts = int.tryParse(recordAt);
    if (ts != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    }
    // Try parse as ISO string
    final date = DateTime.tryParse(recordAt);
    if (date != null) {
      return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    }
    return recordAt;
  }

  String _formatRate(int? rate) {
    if (rate == null) return '1.0x';
    return '${rate}x';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '流量明细仅保留近一个月数据以供查询',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        
        // Logs Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('记录时间', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('上传', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('下载', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 1, child: Text('倍率', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
              Expanded(flex: 2, child: Text('总计', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
        ),
        const Divider(height: 1),

        // Logs List
        Expanded(
          child: _isLoading && _page == 1
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)))
              : _records.isEmpty
                ? const Center(child: Text('暂无流量记录', style: TextStyle(color: Colors.grey)))
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!_isLoading && _hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                        setState(() {
                          _isLoading = true;
                          _page++;
                        });
                        _loadLogs();
                      }
                      return true;
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _records.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == _records.length) {
                           return const Padding(
                             padding: EdgeInsets.all(16.0),
                             child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                           );
                        }
                        final record = _records[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(_formatDate(record.recordAt), style: const TextStyle(fontSize: 13))),
                              Expanded(flex: 2, child: Text(XboardUser.formatTraffic(record.u), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                              Expanded(flex: 2, child: Text(XboardUser.formatTraffic(record.d), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                              Expanded(flex: 1, child: Text(_formatRate(record.serverRate), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                              Expanded(flex: 2, child: Text(XboardUser.formatTraffic(record.u + record.d), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}
