import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/announcement_service.dart';
import 'package:fl_clash/soravpn_ui/services/auth_service.dart';
import 'package:fl_clash/soravpn_ui/screens/auth_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:fl_clash/common/remote_config_service.dart';

/// 公告列表对话框
class AnnouncementDialog extends StatefulWidget {
  const AnnouncementDialog({super.key});

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  bool _isLoading = true;
  List<Announcement> _announcements = [];
  String? _error;
  Set<int> _expandedIds = {}; // 记录哪些公告是展开状态

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcements = await AnnouncementService.getAnnouncements(
        page: 1,
        size: 99,
        // 不传递 pinnedOnly 和 popupOnly 参数，获取所有公告
      );

      if (mounted) {
        setState(() {
          // 过滤掉弹窗类公告，只显示列表类公告
          _announcements = announcements.where((a) => !a.popup).toList();
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
    return Dialog(
      backgroundColor: AppTheme.bgLightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppTheme.bgDarkest,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '系统公告',
                  style: const TextStyle(
                    color: AppTheme.textLightPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppTheme.textLightSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 公告数量
            if (!_isLoading && _error == null)
              Text(
                '共 ${_announcements.length} 条公告',
                style: const TextStyle(
                  color: AppTheme.textLightTertiary,
                  fontSize: 12,
                ),
              ),

             // Official URL Card
             if (!_isLoading && _error == null)
                _buildOfficialUrlCard(),

            const SizedBox(height: 16),

            const Divider(color: AppTheme.border, height: 1),

            const SizedBox(height: 16),

            // 内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.bgDarkest,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!.contains('TOKEN_EXPIRED') ? '登录已过期' : '加载失败',
              style: const TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!.contains('TOKEN_EXPIRED')
                ? '您的登录状态已过期，请重新登录'
                : _error!,
              style: const TextStyle(
                color: AppTheme.textLightTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_error!.contains('TOKEN_EXPIRED'))
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // 关闭对话框
                  await AuthService.logout(); // 清除登录状态
                  if (context.mounted) {
                    // 导航回登录页面
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => AuthWrapper()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                ),
                child: const Text('重新登录'),
              )
            else
              TextButton(
                onPressed: _loadAnnouncements,
                child: const Text('重试'),
              ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.textLightTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无公告',
              style: TextStyle(
                color: AppTheme.textLightSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final announcement = _announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final isExpanded = _expandedIds.contains(announcement.id);

    return Container(
      decoration: BoxDecoration(
        color: announcement.pinned
            ? AppTheme.bgDarkest.withValues(alpha: 0.05)
            : AppTheme.bgLightSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: announcement.pinned
              ? AppTheme.bgDarkest.withValues(alpha: 0.2)
              : AppTheme.border,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedIds.remove(announcement.id);
            } else {
              _expandedIds.add(announcement.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // 标题行
                Row(
                  children: [
                    // 置顶标签
                    if (announcement.pinned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDarkest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '置顶',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),


                    // 标题
                    Expanded(
                      child: Row(
                         children: [
                           // NEW 标签 (14天内)
                           if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(announcement.createdAt > 10000000000 ? announcement.createdAt : announcement.createdAt * 1000)).inDays < 14)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               margin: const EdgeInsets.only(right: 8),
                               decoration: BoxDecoration(
                                 color: AppTheme.error,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: const Text(
                                 'NEW',
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 10,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ),
                           Flexible(
                             child: Text(
                               announcement.title,
                               style: const TextStyle(
                                 color: AppTheme.textLightPrimary,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w600,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 时间
                    Text(
                      announcement.formattedDate,
                      style: const TextStyle(
                        color: AppTheme.textLightTertiary,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 展开/折叠图标
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppTheme.textLightSecondary,
                      size: 20,
                    ),
                  ],
                ),

                // 展开时显示内容
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 12),

                  // 内容 (Markdown)
                  Html(
                    data: announcement.content,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: AppTheme.textLightSecondary,
                        fontSize: FontSize(13),
                        lineHeight: LineHeight(1.5),
                        fontFamily: 'sans-serif',
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      "h1": Style(
                        color: AppTheme.textLightPrimary,
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.w600,
                        margin: Margins.only(bottom: 12),
                      ),
                      "h2": Style(
                        color: AppTheme.textLightPrimary,
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.w600,
                        margin: Margins.only(top: 12, bottom: 8),
                      ),
                      "h3": Style(
                        color: AppTheme.textLightPrimary,
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.w600,
                        margin: Margins.only(top: 10, bottom: 8),
                      ),
                      "a": Style(
                        color: AppTheme.bgDarkest,
                        textDecoration: TextDecoration.underline,
                      ),
                      "img": Style(
                        width: Width(100, Unit.percent),
                        height: Height.auto(),
                        padding: HtmlPaddings.only(top: 8, bottom: 8),
                      ),
                      "blockquote": Style(
                         margin: Margins.symmetric(horizontal: 0, vertical: 8),
                         padding: HtmlPaddings.only(left: 12),
                         border: Border(left: BorderSide(color: AppTheme.bgDarkest.withValues(alpha: 0.5), width: 3)),
                         fontStyle: FontStyle.italic,
                         color: AppTheme.textLightSecondary,
                      ),
                      "pre": Style(
                        backgroundColor: AppTheme.bgLightSecondary,
                        padding: HtmlPaddings.all(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      "code": Style(
                         backgroundColor: AppTheme.bgLightSecondary,
                         fontFamily: 'monospace',
                         fontSize: FontSize(12),
                      ),
                    },
                    onLinkTap: (url, _, __) async {
                      if (url != null && await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildOfficialUrlCard() {
    final url = RemoteConfigService.config?.officialUrl ?? '';
    if (url.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.03),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: AppTheme.primary.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.public, size: 18, color: AppTheme.primary),
           ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '最新官网地址',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textLightTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLightPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                 Clipboard.setData(ClipboardData(text: url));
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('已复制官网地址'),
                       duration: Duration(seconds: 1),
                     ),
                   );
                 }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textLightSecondary),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                 launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.textLightSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
