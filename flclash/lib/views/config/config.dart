import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/models/config.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

class ConfigView extends StatefulWidget {
  const ConfigView({super.key});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      ListItem.open(
        title: Text(appLocalizations.general),
        subtitle: Text(appLocalizations.generalDesc),
        leading: const Icon(Icons.build),
        delegate: OpenDelegate(
          title: appLocalizations.general,
          widget: Theme(
            data: AppTheme.lightTheme,
            child: CommonScaffold(
              title: appLocalizations.general,
              body: generateListView(generalItems),
            ),
          ),
          blur: false,
          wrap: false,
        ),
      ),
      ListItem.open(
        title: Text(appLocalizations.network),
        subtitle: Text(appLocalizations.networkDesc),
        leading: const Icon(Icons.vpn_key),
        delegate: OpenDelegate(
          title: appLocalizations.network,
          blur: false,
          actions: [
            Consumer(
              builder: (_, ref, _) {
                return IconButton(
                  onPressed: () async {
                    final res = await globalState.showMessage(
                      title: appLocalizations.reset,
                      message: TextSpan(text: appLocalizations.resetTip),
                    );
                    if (res != true) {
                      return;
                    }
                    ref
                        .read(vpnSettingProvider.notifier)
                        .updateState(
                          (state) => defaultVpnProps.copyWith(
                            accessControl: state.accessControl,
                          ),
                        );
                    ref
                        .read(patchClashConfigProvider.notifier)
                        .updateState(
                          (state) => state.copyWith(tun: defaultTun),
                        );
                  },
                  tooltip: appLocalizations.reset,
                  icon: const Icon(Icons.replay),
                );
              },
            ),
          ],
          widget: Theme(
            data: AppTheme.lightTheme,
            child: CommonScaffold(
              title: appLocalizations.network,
              actions: [
                Consumer(
                  builder: (_, ref, _) {
                    return IconButton(
                      onPressed: () async {
                        final res = await globalState.showMessage(
                          title: appLocalizations.reset,
                          message: TextSpan(text: appLocalizations.resetTip),
                        );
                        if (res != true) {
                          return;
                        }
                        ref
                            .read(vpnSettingProvider.notifier)
                            .updateState(
                              (state) => defaultVpnProps.copyWith(
                                accessControl: state.accessControl,
                              ),
                            );
                        ref
                            .read(patchClashConfigProvider.notifier)
                            .updateState(
                              (state) => state.copyWith(tun: defaultTun),
                            );
                      },
                      tooltip: appLocalizations.reset,
                      icon: const Icon(Icons.replay),
                    );
                  },
                ),
              ],
              body: const NetworkListView(),
            ),
          ),
          wrap: false,
        ),
      ),
      ListItem.open(
        title: const Text('DNS'),
        subtitle: Text(appLocalizations.dnsDesc),
        leading: const Icon(Icons.dns),
        delegate: OpenDelegate(
          title: 'DNS',
          actions: [
            Consumer(
              builder: (_, ref, _) {
                return IconButton(
                  onPressed: () async {
                    final res = await globalState.showMessage(
                      title: appLocalizations.reset,
                      message: TextSpan(text: appLocalizations.resetTip),
                    );
                    if (res != true) {
                      return;
                    }
                    ref
                        .read(patchClashConfigProvider.notifier)
                        .updateState(
                          (state) => state.copyWith(dns: defaultDns),
                        );
                  },
                  tooltip: appLocalizations.reset,
                  icon: const Icon(Icons.replay),
                );
              },
            ),
          ],
          widget: Theme(
            data: AppTheme.lightTheme,
            child: CommonScaffold(
              title: 'DNS',
              actions: [
                Consumer(
                  builder: (_, ref, _) {
                    return IconButton(
                      onPressed: () async {
                        final res = await globalState.showMessage(
                          title: appLocalizations.reset,
                          message: TextSpan(text: appLocalizations.resetTip),
                        );
                        if (res != true) {
                          return;
                        }
                        ref
                            .read(patchClashConfigProvider.notifier)
                            .updateState(
                              (state) => state.copyWith(dns: defaultDns),
                            );
                      },
                      tooltip: appLocalizations.reset,
                      icon: const Icon(Icons.replay),
                    );
                  },
                ),
              ],
              body: const DnsListView(),
            ),
          ),
          blur: false,
          wrap: false,
        ),
      ),
    ];
    return generateListView(items.separated(const Divider(height: 0)).toList());
  }
}
