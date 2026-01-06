import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/application_setting.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show dirname, join;
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

import 'backup_and_recovery.dart';
import 'developer.dart';
import 'resources.dart';
import 'theme.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/screens/settings_screen.dart';
import 'package:fl_clash/soravpn_ui/screens/main_layout.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolViewState();
}



class _ToolViewState extends ConsumerState<ToolsView> {


  void _onAdvancedItemTap() {
    _showAdvancedModeWarning();
  }

  void _showAdvancedModeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.error),
        title: const Text('高级模式已开启'),
        content: const Text(
          '高级模式设置不适合新手使用，如无特殊用途请谨慎开启，以免影响使用体验。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 自动跳转进入
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Theme(
                    data: AppTheme.lightTheme,
                    child: const AdvancedToolsView(),
                  ),
                ),
              );
            },
            child: const Text('我了解'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: navigationItem.icon,
      title: Text(Intl.message(navigationItem.label.name)),
      subtitle: navigationItem.description != null
          ? Text(Intl.message(navigationItem.description!))
          : null,
      delegate: OpenDelegate(
        title: Intl.message(navigationItem.label.name),
        widget: navigationItem.builder(context),
        wrap: false,
      ),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (final navigationItem in navigationItems) ...[
          _buildNavigationMenuItem(navigationItem),
          navigationItems.last != navigationItem
              ? const Divider(height: 0)
              : Container(),
        ],
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    final vm2 = ref.watch(
      appSettingProvider.select(
        (state) => VM2(a: state.locale, b: state.developerMode),
      ),
    );
    final items = [
      if (system.isWindows) _LoopbackItem(),
      if (system.isAndroid) _AccessItem(),
      const PortItem(),
      if (system.isDesktop) const TUNItem(),
      if (system.isDesktop) const _AutoLaunchItem(),
      const _VersionItem(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.bgLightSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('设置', style: TextStyle(color: AppTheme.textLightPrimary)),
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: items.map((item) {
                // Add separator if not last item
                final isLast = item == items.last;
                return Column(
                  children: [
                    item,
                    if (!isLast)
                       const Divider(height: 1, indent: 64, color: AppTheme.border),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AdvancedToolsView extends StatelessWidget {
  const AdvancedToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _ResourcesItem(),
      const _ConfigItem(),
      const _SettingItem(),
      const PortItem(),
      const TUNItem(),
    ];
    
    return Theme(
      data: AppTheme.lightTheme,
      child: CommonScaffold(
        title: '高级模式',
        body: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) => items[index],
          padding: const EdgeInsets.only(bottom: 20),
        ),
      ),
    );
  }
}

class _LocaleItem extends ConsumerWidget {
  const _LocaleItem();

  String _getLocaleString(Locale? locale) {
    if (locale == null) return appLocalizations.defaultText;
    return Intl.message(locale.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final subTitle = locale ?? appLocalizations.defaultText;
    final currentLocale = utils.getLocaleForString(locale);
    return ListItem<Locale?>.options(
      leading: const Icon(Icons.language_outlined),
      title: Text(appLocalizations.language),
      subtitle: Text(Intl.message(subTitle)),
      delegate: OptionsDelegate(
        title: appLocalizations.language,
        options: [null, ...AppLocalizations.delegate.supportedLocales],
        onChanged: (Locale? locale) {
          ref
              .read(appSettingProvider.notifier)
              .updateState(
                (state) => state.copyWith(locale: locale?.toString()),
              );
        },
        textBuilder: (locale) => _getLocaleString(locale),
        value: currentLocale,
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.style),
      title: Text(appLocalizations.theme),
      subtitle: Text(appLocalizations.themeDesc),
      delegate: OpenDelegate(
        title: appLocalizations.theme,
        widget: const ThemeView(),
      ),
    );
  }
}

class _BackupItem extends StatelessWidget {
  const _BackupItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.cloud_sync),
      title: Text(appLocalizations.backupAndRecovery),
      subtitle: Text(appLocalizations.backupAndRecoveryDesc),
      delegate: OpenDelegate(
        title: appLocalizations.backupAndRecovery,
        widget: const BackupAndRecovery(),
      ),
    );
  }
}

class _HotkeyItem extends StatelessWidget {
  const _HotkeyItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.keyboard),
      title: Text(appLocalizations.hotkeyManagement),
      subtitle: Text(appLocalizations.hotkeyManagementDesc),
      delegate: OpenDelegate(
        title: appLocalizations.hotkeyManagement,
        widget: const HotKeyView(),
      ),
    );
  }
}

class _LoopbackItem extends StatelessWidget {
  const _LoopbackItem();

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.lock),
      title: Text(appLocalizations.loopback),
      subtitle: Text(appLocalizations.loopbackDesc),
      onTap: () {
        windows?.runas(
          '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
          '',
        );
      },
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list),
      title: Text(appLocalizations.accessControl),
      subtitle: Text(appLocalizations.accessControlDesc),
      delegate: OpenDelegate(
        title: appLocalizations.appAccessControl,
        widget: const AccessView(),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.edit),
      title: Text(appLocalizations.basicConfig),
      subtitle: Text(appLocalizations.basicConfigDesc),
      delegate: OpenDelegate(
        title: appLocalizations.basicConfig,
        widget: Theme(
          data: AppTheme.lightTheme,
          child: CommonScaffold(
            title: appLocalizations.basicConfig,
            body: const ConfigView(),
          ),
        ),
        wrap: false,
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.settings),
      title: Text(appLocalizations.application),
      subtitle: Text(appLocalizations.applicationDesc),
      delegate: OpenDelegate(
        title: appLocalizations.application,
        widget: Theme(
          data: AppTheme.lightTheme,
          child: CommonScaffold(
            title: appLocalizations.application,
            body: const ApplicationSettingView(),
          ),
        ),
        wrap: false,
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem();

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.gavel),
      title: Text(appLocalizations.disclaimer),
      onTap: () async {
        final isDisclaimerAccepted = await globalState.appController
            .showDisclaimer();
        if (!isDisclaimerAccepted) {
          globalState.appController.handleExit();
        }
      },
    );
  }
}



class _DeveloperItem extends StatelessWidget {
  const _DeveloperItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.developer_board),
      title: Text(appLocalizations.developerMode),
      delegate: OpenDelegate(
        title: appLocalizations.developerMode,
        widget: const DeveloperView(),
      ),
    );
  }
}

class _ResourcesItem extends StatelessWidget {
  const _ResourcesItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list),
      title: Text(appLocalizations.resources),
      subtitle: Text(appLocalizations.resourcesDesc),
      delegate: OpenDelegate(
        title: appLocalizations.resources,
        widget: Theme(
          data: AppTheme.lightTheme,
          child: const ResourcesView(),
        ),
        wrap: false, // ResourcesView already has CommonScaffold
      ),
    );
  }
}



class _VersionItem extends StatefulWidget {
  const _VersionItem();

  @override
  State<_VersionItem> createState() => _VersionItemState();
}

class _VersionItemState extends State<_VersionItem> {
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
        // Fallback logic
        String? latestVersion = versions[platformKey] as String?;
        if (latestVersion == null && data['version'] is String) {
           latestVersion = data['version'];
        }

        // Handle download url
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
        surfaceTintColor: Colors.white,
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
    return ListItem(
      leading: const Icon(Icons.info_outline),
      title: const Text('软件版本'),
      subtitle: Text('当前版本: $_version'),
      trailing: _checking 
        ? const SizedBox(
            width: 16, 
            height: 16, 
            child: CircularProgressIndicator(strokeWidth: 2)
          )
        : _hasNewVersion
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _checking ? null : () => _checkUpdate(silent: false),
    );
  }
}

class _AutoLaunchItem extends ConsumerWidget {
  const _AutoLaunchItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLaunch = ref.watch(
      appSettingProvider.select((state) => state.autoLaunch),
    );
    return ListItem.switchItem(
      leading: const Icon(Icons.power_settings_new),
      title: Text(appLocalizations.autoLaunch),
      subtitle: Text(appLocalizations.autoLaunchDesc),
      delegate: SwitchDelegate(
        value: autoLaunch,
        onChanged: (value) {
          ref.read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(autoLaunch: value));
        },
      ),
    );
  }
}
