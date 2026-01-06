import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_clash/common/remote_config_service.dart';

/// 侧边导航栏
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo 和应用名称
          _buildHeader(),

          const SizedBox(height: 24),

          // 导航菜单
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: '仪表盘',
                  isSelected: selectedIndex == 0,
                ),
                _buildMenuItem(
                  context,
                  index: 1,
                  icon: Icons.shopping_cart_rounded,
                  label: '购买订阅',
                  isSelected: selectedIndex == 1,
                ),
                _buildMenuItem(
                  context,
                  index: 2,
                  icon: Icons.card_giftcard_rounded,
                  label: '邀请赚钱',
                  isSelected: selectedIndex == 2,
                ),
                _buildMenuItem(
                  context,
                  index: 4,
                  icon: Icons.person_rounded,
                  label: '我的账户',
                  isSelected: selectedIndex == 4,
                ),
                _buildMenuItem(
                  context,
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: '设置',
                  isSelected: selectedIndex == 3,
                ),
              ],
            ),
          ),

          // 版本信息 (替换原头像区域)
          const _VersionFooter(),
        ],
      ),
    );
  }

  /// 头部 Logo
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            final url = RemoteConfigService.config?.officialUrl;
            if (url != null && url.isNotEmpty) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            children: [
              // Logo 图标
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // 应用名称
              Builder(
                builder: (context) => Text(
                  'Lray',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 菜单项
  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onItemSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              // 匹配官网light mode: 选中=浅色背景+主色，未选中=透明
              color: isSelected
                ? AppTheme.primaryDark.withOpacity(0.1) // bg-primary/10
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              // 选中时添加边框效果
              border: isSelected
                ? Border.all(
                    color: AppTheme.primaryDark.withOpacity(0.2), // ring-1 ring-primary/20
                    width: 1,
                  )
                : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildUserCard removed
}

class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  String _version = '';
  bool _checking = false;
  bool _hasNewVersion = false;
  
  // Actual OSS URL
  static const String _updateUrl = 'https://wall-api.oss-cn-shenzhen.aliyuncs.com/config';

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    await _initVersion();
    if (mounted) {
      _checkUpdate(silent: true);
    }
  }

  Future<void> _initVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  Future<void> _checkUpdate({bool silent = false}) async {
    if (!silent) setState(() => _checking = true);
    
    try {
      final response = await http.get(Uri.parse(_updateUrl));
      if (response.statusCode == 200) {
        // 1. Parse outer JSON { content, signature }
        final body = utf8.decode(response.bodyBytes);
        final signedMap = jsonDecode(body);
        
        // 2. Extract and decode content
        final contentBase64 = signedMap['content'] as String?;
        if (contentBase64 == null) throw Exception('Invalid config format');
        
        final configStr = utf8.decode(base64Decode(contentBase64));
        final data = jsonDecode(configStr);
        
        // Determine platform key
        String? platformKey;
        if (Platform.isMacOS) platformKey = 'macos';
        else if (Platform.isWindows) platformKey = 'windows';
        else if (Platform.isAndroid) platformKey = 'android';
        else if (Platform.isLinux) platformKey = 'linux';
        
        if (platformKey == null) {
           if (!silent) _showSnack('当前平台不支持自动更新');
           return;
        }

        final versions = data['version'] as Map<String, dynamic>;
        String? latestVersion = versions[platformKey] as String?;
        if (latestVersion == null && data['version'] is String) {
           latestVersion = data['version'];
        }

        String? downloadUrl;
        final downloadData = data['download'];
        if (downloadData is String) {
          downloadUrl = downloadData;
        } else if (downloadData is Map) {
          downloadUrl = downloadData[platformKey];
        }

        final description = data['description'] as String?;
        
        if (latestVersion != null && downloadUrl != null) {
          if (_compareVersions(latestVersion, _version) > 0) {
             if (silent) {
                if (mounted) setState(() => _hasNewVersion = true);
             } else {
                _showUpdateDialog(latestVersion, downloadUrl, description);
             }
          } else {
             if (!silent && mounted) {
                _showSnack('已是最新版本');
             }
          }
        } else {
           if (!silent) _showSnack('无法获取版本信息');
        }
      } else {
         throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
       if (!silent) _showSnack('检查更新失败: $e');
    } finally {
      if (mounted && !silent) {
        setState(() => _checking = false);
      }
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  int _compareVersions(String v1, String v2) {
    try {
      final p1 = v1.replaceAll('v', '').split('.').map(int.parse).toList();
      final p2 = v2.replaceAll('v', '').split('.').map(int.parse).toList();
      
      for (var i = 0; i < p1.length && i < p2.length; i++) {
        if (p1[i] > p2[i]) return 1;
        if (p1[i] < p2[i]) return -1;
      }
      return p1.length.compareTo(p2.length);
    } catch (_) {
      return 0;
    }
  }

  void _showUpdateDialog(String version, String url, String? desc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, // Disable Material 3 tint
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '发现新版本 $version',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              if (desc != null) ...[
                const Text(
                  '更新内容:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('立即更新', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _checking ? null : () => _checkUpdate(silent: false),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgLightSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Version $_version',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (_checking)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else if (_hasNewVersion)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right, size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
