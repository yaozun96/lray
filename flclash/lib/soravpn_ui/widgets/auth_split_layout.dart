import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/widgets/auth_carousel_panel.dart';

class AuthSplitLayout extends StatelessWidget {
  final Widget formChild;
  final int? carouselIndex;

  const AuthSplitLayout({
    super.key,
    required this.formChild,
    this.carouselIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 检查屏幕宽度，决定是否显示左侧面板 (响应式布局)
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 左侧面板 (深色背景 + 介绍)
          if (isWideScreen)
            Expanded(
              flex: 45,
              child: AuthCarouselPanel(fixedIndex: carouselIndex),
            ),

          // 右侧面板 (白色背景 + 表单)
          Expanded(
            flex: 55,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: formChild,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
