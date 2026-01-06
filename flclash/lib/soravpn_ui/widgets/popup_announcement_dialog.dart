import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/announcement_service.dart';

/// 弹窗公告对话框
class PopupAnnouncementDialog extends StatelessWidget {
  final Announcement announcement;

  const PopupAnnouncementDialog({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgLightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.bgDarkest,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

            // 发布时间
            Text(
              announcement.formattedDate,
              style: const TextStyle(
                color: AppTheme.textLightTertiary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            const Divider(color: AppTheme.border, height: 1),

            const SizedBox(height: 16),

            // 内容区域（可滚动）
            Flexible(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: announcement.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: AppTheme.textLightSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    h1: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    h2: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    h3: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    h4: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    h5: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    h6: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    strong: const TextStyle(
                      color: AppTheme.textLightPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    em: const TextStyle(
                      color: AppTheme.textLightSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    a: const TextStyle(
                      color: AppTheme.bgDarkest,
                      decoration: TextDecoration.underline,
                    ),
                    code: TextStyle(
                      color: AppTheme.bgDarkestLight,
                      backgroundColor: AppTheme.bgLightSecondary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    listBullet: const TextStyle(
                      color: AppTheme.textLightSecondary,
                    ),
                    blockquote: const TextStyle(
                      color: AppTheme.textLightSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: AppTheme.bgLightSecondary,
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.bgDarkest.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 确定按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '我知道了',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
