import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_invite_service.dart';
import 'package:fl_clash/soravpn_ui/models/xboard_invite.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/config/xboard_config.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';
import 'package:fl_clash/soravpn_ui/services/xboard_ticket_service.dart';


class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _loading = true;
  bool _isProcessing = false;
  String? _error;
  XboardInvite? _inviteData;
  final String _baseUrl = '${XboardConfig.apiBaseUrl}/#/register?code=';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    // 同时也加载用户配置以获取最新的提现方式
    // Put this FIRST to ensure it runs even if getInviteInfo fails later
    
    try {
      final data = await XboardInviteService.getInviteInfo();
      if (!mounted) return;
      setState(() {
        _inviteData = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateCode() async {
    if ((_inviteData?.codes?.length ?? 0) >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能创建5个邀请链接')),
      );
      return;
    }

    try {
      await XboardInviteService.generateInviteCode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀请码生成成功'), backgroundColor: AppTheme.success),
      );
      _loadData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _copyLink(String code) async {
    final link = '$_baseUrl$code';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已复制到剪贴板'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _inviteData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            )
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLightSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('邀请返利', style: TextStyle(color: AppTheme.textLightPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showRulesDialog,
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
            tooltip: '活动规则',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
           SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommissionCard(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildInviteCodesCard(),
                const SizedBox(height: 24),
                _buildMenuCard(),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard() {
    final balance = _inviteData?.stat?.availableBalanceYuan ?? 0.0;
    final canWithdraw = (_inviteData?.stat?.availableBalance ?? 0) >= 20000; // 200 yuan = 20000 fen
    final currency = ConfigService.currencySymbol;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2156).withOpacity(0.04), 
            blurRadius: 16, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前可用佣金', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(
                        balance.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(currency, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (!canWithdraw)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('满200元可提现', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showTransferDialog(balance),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('划转', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _handleWithdrawClick(canWithdraw, balance),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                    label: const Text('提现', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canWithdraw ? AppTheme.primary : AppTheme.bgLightSecondary,
                      foregroundColor: canWithdraw ? Colors.white : AppTheme.textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleWithdrawClick(bool canWithdraw, double balance) {
    if (!canWithdraw) {
      final remaining = (200 - balance).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('当前佣金 $balance 元，还差 $remaining 元即可提现')),
      );
      return;
    }
    _showWithdrawDialog(balance);
  }

  Future<void> _showTransferDialog(double balance) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('佣金划转'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(child: Text('划转后的余额仅用于消费使用，不可提现', style: TextStyle(fontSize: 12, color: AppTheme.primary))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '最多可划转 $balance',
                border: const OutlineInputBorder(),
                suffixText: ConfigService.currencyUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > balance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的金额')));
                return;
              }
              Navigator.pop(context);
              _performTransfer(amount);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _performTransfer(double amount) async {
    setState(() => _isProcessing = true);

    try {
      await XboardInviteService.transferCommission((amount * 100).toInt());
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('划转成功'), backgroundColor: AppTheme.success)
      );
      _loadData(); // Refresh data
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('划转失败: $e'), backgroundColor: AppTheme.error)
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showWithdrawDialog(double balance) async {

    
    if (!mounted) return;

    final accountController = TextEditingController();
    
    // 优先使用邀请数据中的提现方式，如果没有则使用全局配置，最后兜底为空
    var methods = _inviteData?.withdrawMethods ?? ConfigService.withdrawMethods;
    
    // 如果为空，尝试强制刷新一次配置
    if (methods.isEmpty) {
      await ConfigService.loadUserConfig();
      methods = _inviteData?.withdrawMethods ?? ConfigService.withdrawMethods;
    }

    String method = methods.isNotEmpty ? methods.first : '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // If methods are empty, try to reload config once
           if (methods.isEmpty) {
             // trigger reload in background if not already tried recently? 
             // Or better, just show what we have.
             // We can't await here easily without blocking UI builder.
             // Let's rely on the previous await in _performWithdraw or initial load.
             // But valid point: if init failed, we want to try again.
           }
           
           return AlertDialog(
          title: const Text('佣金提现'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (methods.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: '提现方式', border: OutlineInputBorder()),
                  items: methods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => method = v!),
                )
              else
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '提现方式',
                    hintText: '请输入提现方式 (配置为空, 请手动输入)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => method = v,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: '提现账号',
                  hintText: '请输入您的收款账号',
                  border: OutlineInputBorder(),
                ),
              ),
               const SizedBox(height: 16),
               Text('提现金额: $balance ${ConfigService.currencyUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (accountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入提现账号')));
                  return;
                }
                Navigator.pop(context);
                _performWithdraw(method, accountController.text, balance);
              },
              child: const Text('提交申请'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _performWithdraw(String method, String account, double amount) async {
    if (method.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入提现方式')));
        return;
    }
    setState(() => _isProcessing = true);
    
    try {
      // Check for open tickets first (matching website logic)
      final tickets = await XboardTicketService.getTickets();
      final hasOpenTicket = tickets.any((t) => t.status == 0);
      
      if (hasOpenTicket) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您有未关闭的工单，请先处理后再提交提现申请'), backgroundColor: AppTheme.warning)
        );
        return;
      }
      
      // Submit withdrawal via ticket system (matching website logic)
      final message = '提现方式：$method\n提现账号：$account\n提现金额：$amount 元\n\n请审核处理，谢谢！';
      
      await XboardTicketService.createTicket(
        subject: '佣金提现申请',
        level: 1,
        message: message,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提现申请已提交，请在工单中查看进度'), backgroundColor: AppTheme.success));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }



  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('活动规则', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogNoteItem('推荐的新用户首次购买可获得 ${_inviteData?.stat?.commissionRate ?? "--"}% 佣金。'),
            const SizedBox(height: 8),
            _buildDialogNoteItem('同一个邀请链接可以不限次重复使用，最多可以创建5个链接。'),
            const SizedBox(height: 8),
            _buildDialogNoteItem('佣金满200元即可提现，也可以转入到您的账户中消费。'),
            const SizedBox(height: 8),
            _buildDialogNoteItem('每周五统一处理提现申请 (周四23:59前提交)。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogNoteItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }




  Widget _buildStatsGrid() {
    final stat = _inviteData?.stat;
    final currency = ConfigService.currencySymbol;
    
    final cards = [
      {
        'label': '已注册用户数',
        'value': '${stat?.registeredCount ?? 0}',
        'unit': '人',
        'icon': Icons.group_rounded,
      },
      {
        'label': '佣金比例',
        'value': '${stat?.commissionRate ?? 0}',
        'unit': '%',
        'icon': Icons.percent_rounded,
      },
      {
        'label': '确认中的佣金',
        'value': (stat?.pendingCommissionYuan ?? 0).toStringAsFixed(2),
        'unit': currency,
        'icon': Icons.access_time_rounded,
      },
      {
        'label': '累计获得佣金',
        'value': (stat?.totalCommissionYuan ?? 0).toStringAsFixed(2),
        'unit': currency,
        'icon': Icons.monetization_on_rounded, // or Coins icon
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) {
            final width = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2156).withOpacity(0.04), 
                      blurRadius: 12, 
                      offset: const Offset(0, 4)
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Label + Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card['label'] as String, 
                            style: const TextStyle(
                              fontSize: 13, 
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(card['icon'] as IconData, size: 16, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bottom Row: Value + Unit
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            card['value'] as String,
                            style: const TextStyle(
                              fontSize: 26, 
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            card['unit'] as String,
                            style: const TextStyle(
                              fontSize: 13, 
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2156).withOpacity(0.03), 
            blurRadius: 16, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showInviteDetailsDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.list_alt_rounded, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '邀请明细',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textLightSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDetailsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
         backgroundColor: Colors.transparent,
         insetPadding: const EdgeInsets.all(24),
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
           child: Container(
             decoration: BoxDecoration(
               color: AppTheme.bgLightSecondary,
               borderRadius: BorderRadius.circular(24),
             ),
             child: Column(
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
                       const Text('邀请明细', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                     ],
                   ),
                 ),
                 Expanded(child: _InviteDetailsList()),
               ],
             ),
           ),
         ),
      ),
    );
  }

  Widget _buildInviteCodesCard() {
    final codes = _inviteData?.codes ?? [];
    final canCreate = codes.length < 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2156).withOpacity(0.04), 
            blurRadius: 16, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('邀请链接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('同一个链接可无限次使用，最多可创建5个', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: canCreate ? _generateCode : null,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('创建邀请链接', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.muted,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: codes.isEmpty
              ? _buildEmptyCodes_()
              : Column(
                  children: codes.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_baseUrl${item.code}',
                                style: const TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                  color: AppTheme.textPrimary
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(item.createdAt!),
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _copyLink(item.code),
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('复制', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCodes_() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.bgLightSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link_rounded, size: 24, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text('暂无邀请链接', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generateCode,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('创建第一个链接', style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}

class _InviteDetailsList extends StatefulWidget {
  @override
  State<_InviteDetailsList> createState() => _InviteDetailsListState();
}

class _InviteDetailsListState extends State<_InviteDetailsList> {
  bool _isLoading = true;
  List<XboardInviteDetail> _list = [];
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      const pageSize = 10;
      final data = await XboardInviteService.getInviteDetails(page: _page, pageSize: pageSize);
      if (mounted) {
        setState(() {
          if (_page == 1) {
            _list = data;
          } else {
            _list.addAll(data);
          }
          if (data.length < pageSize) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _page == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('加载失败: $_error', style: const TextStyle(color: AppTheme.error)));
    }

    if (_list.isEmpty) {
      return const Center(child: Text('暂无邀请记录', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading && _hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          setState(() {
            _isLoading = true;
            _page++;
          });
          _loadData();
        }
        return true;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _list.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _list.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
          }
          final item = _list[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                 BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)
                 )
              ]
            ),
            child: Column(
              children: [
                // Row 1: Order Amount & Commission (Desktop-like layout adjusted for mobile list)
                Row(
                  children: [
                    // Order Amount
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          const Text('订单金额: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          Text(
                            '${ConfigService.currencySymbol}${item.orderAmountYuan.toStringAsFixed(2)}', 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Commission
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on_rounded, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          const Text('佣金: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          Text(
                            '+${ConfigService.currencySymbol}${item.commissionAmountYuan.toStringAsFixed(2)}', 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Date (Right aligned or Start aligned, website has it on right but in list item it's flexible)
                // Website uses flex-col sm:flex-row. Mobile view likely stacks. 
                // Let's confirm website layout:
                // Mobile: Stacks [Order Amount, Commission] then Date below? No, website code: 
                // flex-col sm:flex-row.
                // Mobile: 
                // [Order Amount] 
                // [Commission]
                // [Date]
                // But my space is limited in dialog. Let's start with a clean row for date.
                Row(
                   children: [
                     Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                     const SizedBox(width: 4),
                     Text(_formatDate(item.createdAt), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                   ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}
