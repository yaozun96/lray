import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/screens/auth_wrapper.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:fl_clash/soravpn_ui/services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载全局配置（包括货币信息）
  await ConfigService.loadGlobalConfig();

  runApp(const SoraVPNApp());
}

class SoraVPNApp extends StatelessWidget {
  const SoraVPNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lray',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
