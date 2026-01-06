import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/models/ticket.dart';
import 'package:fl_clash/soravpn_ui/services/ticket_service.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/screens/ticket/create_ticket_page.dart';
import 'package:fl_clash/soravpn_ui/screens/ticket/ticket_detail_page.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/remote_config_service.dart';
import 'package:fl_clash/soravpn_ui/screens/ticket/crisp_web_page.dart';
import 'package:crisp_chat/crisp_chat.dart';

class TicketListPage extends StatefulWidget {
  final bool isEmbedded;
  final bool showTitle;

  const TicketListPage({
    super.key,
    this.isEmbedded = false,
    this.showTitle = true,
  });

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (_tickets.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      const pageSize = 10;
      final tickets = await TicketService.getTickets(page: _page, size: pageSize);
      if (mounted) {
        setState(() {
          if (_page == 1) {
            _tickets = tickets;
          } else {
            _tickets.addAll(tickets);
          }
           if (tickets.length < pageSize) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _tickets.isEmpty
                        ? _buildEmptyState()
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (!_isLoading && _hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                setState(() {
                                  _isLoading = true;
                                  _page++;
                                });
                                _loadTickets();
                              }
                              return true;
                            },
                            child: ListView.builder(
                              itemCount: _tickets.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _tickets.length) {
                                   return const Padding(
                                     padding: EdgeInsets.all(16.0),
                                     child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                   );
                                }
                                return _buildTicketCard(_tickets[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const CreateTicketDialog(),
          );
          if (result == true) {
             _page = 1;
             _hasMore = true;
             _loadTickets();
          }
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('新建工单', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader() {
    if (!widget.showTitle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          const Text(
            '我的工单',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const Spacer(),
          // Button moved to FAB
        ],
      ),
    );
  }
  
  // _buildCreateButton removed/inline in FAB

  Widget _buildTicketCard(Ticket ticket) {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) => TicketDetailDialog(ticketId: ticket.id),
        );
        _page = 1;
        _hasMore = true;
        _loadTickets();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced vertical padding
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 15, // Slightly smaller
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(ticket.updatedAt),
                  style: const TextStyle(
                    fontSize: 12, // Smaller date
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // Tighter gap
            _buildStatusDot(ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Ticket ticket) {
    // Kept for compatibility if used elsewhere, but internally replacing with _buildStatusDot
    return _buildStatusDot(ticket);
  }

  Widget _buildStatusDot(Ticket ticket) {
    Color color;
    String text = ticket.statusText;
    
    switch (ticket.status) {
      case 0: // Pending
        color = AppTheme.primary;
        break;
      case 1: // Answered
        color = Colors.green;
        break;
      case 2: // Closed
        color = AppTheme.mutedForeground;
        break;
      default:
        color = AppTheme.mutedForeground;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Compact padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10, // Smaller font
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.muted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无工单',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您可以点击右上方按钮创建一个新的工单',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.destructive),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '未知错误',
            style: const TextStyle(color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTickets,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeTicket(int ticketId) async {
     // ... (Keep existing close logic)
     try {
       await TicketService.closeTicket(ticketId);
       _page = 1;
       _hasMore = true;
       _loadTickets();
     } catch (e) {
       // Error handling
     }
  }

  Future<void> _openCrispChat() async {
    if (system.isMobile) {
        await FlutterCrispChat.openCrispChat(config: CrispConfig(websiteID: RemoteConfigService.config!.crispId!));
    } else {
       // Web logic
         final websiteId = RemoteConfigService.config?.crispId;
         if (websiteId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CrispWebPage(websiteId: websiteId)),
            );
         }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
