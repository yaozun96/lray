import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:fl_clash/common/system.dart';

class CrispWebPage extends StatefulWidget {
  final String websiteId;

  const CrispWebPage({super.key, required this.websiteId});

  @override
  State<CrispWebPage> createState() => _CrispWebPageState();
}

class _CrispWebPageState extends State<CrispWebPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
             setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
             setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse('https://go.crisp.chat/chat/embed/?website_id=${widget.websiteId}'));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客服支持', style: TextStyle(color: AppTheme.textLightPrimary)),
        backgroundColor: AppTheme.bgLight,
        iconTheme: const IconThemeData(color: AppTheme.textLightPrimary),
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
