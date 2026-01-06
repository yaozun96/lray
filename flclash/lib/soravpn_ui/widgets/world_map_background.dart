import 'package:flutter/material.dart';

/// 世界地图背景 - 使用图片，支持节点区域呼吸灯效果
class WorldMapBackground extends StatefulWidget {
  final double opacity;
  final String? connectedNodeCountry; // 当前连接的节点国家代码

  const WorldMapBackground({
    super.key,
    this.opacity = 0.15,
    this.connectedNodeCountry,
  });

  @override
  State<WorldMapBackground> createState() => _WorldMapBackgroundState();
}

class _WorldMapBackgroundState extends State<WorldMapBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 国家/地区代码到地图位置的映射 (相对坐标: 0.0 - 1.0)
  // 根据实际点阵地图布局调整坐标
  static const Map<String, Offset> _countryPositions = {
    // 亚洲
    'CN': Offset(0.70, 0.38), // 中国 - 地图中右偏上
    'HK': Offset(0.72, 0.42), // 香港 - 中国东南
    'TW': Offset(0.74, 0.43), // 台湾 - 中国东南沿海
    'JP': Offset(0.82, 0.36), // 日本 - 地图右侧偏上
    'KR': Offset(0.76, 0.38), // 韩国 - 中国和日本之间
    'SG': Offset(0.72, 0.52), // 新加坡 - 东南亚南端
    'IN': Offset(0.64, 0.44), // 印度 - 亚洲中部偏左
    'TH': Offset(0.69, 0.47), // 泰国 - 东南亚
    'VN': Offset(0.71, 0.47), // 越南 - 东南亚
    'MY': Offset(0.71, 0.51), // 马来西亚 - 东南亚南部
    'PH': Offset(0.75, 0.47), // 菲律宾 - 东南亚东部
    'ID': Offset(0.73, 0.54), // 印度尼西亚 - 东南亚最南

    // 北美
    'US': Offset(0.18, 0.40), // 美国 - 地图左侧中上
    'CA': Offset(0.18, 0.28), // 加拿大 - 地图左侧上部
    'MX': Offset(0.16, 0.48), // 墨西哥 - 北美南部

    // 欧洲
    'GB': Offset(0.46, 0.30), // 英国 - 欧洲西北
    'FR': Offset(0.48, 0.33), // 法国 - 欧洲西部
    'DE': Offset(0.50, 0.30), // 德国 - 欧洲中部
    'NL': Offset(0.49, 0.29), // 荷兰 - 欧洲西北
    'IT': Offset(0.50, 0.35), // 意大利 - 欧洲南部
    'ES': Offset(0.46, 0.36), // 西班牙 - 欧洲西南
    'SE': Offset(0.50, 0.24), // 瑞典 - 欧洲北部
    'NO': Offset(0.49, 0.22), // 挪威 - 欧洲最北
    'RU': Offset(0.58, 0.26), // 俄罗斯 - 欧亚大陆北部

    // 大洋洲
    'AU': Offset(0.82, 0.78), // 澳大利亚 - 地图右下角
    'NZ': Offset(0.90, 0.82), // 新西兰 - 地图最右下

    // 南美
    'BR': Offset(0.28, 0.60), // 巴西 - 南美东部
    'AR': Offset(0.26, 0.72), // 阿根廷 - 南美南端
    'CL': Offset(0.24, 0.68), // 智利 - 南美西南

    // 中东
    'AE': Offset(0.58, 0.44), // 阿联酋 - 中东东部
    'TR': Offset(0.54, 0.36), // 土耳其 - 中东西北
    'SA': Offset(0.56, 0.46), // 沙特阿拉伯 - 中东中部

    // 非洲
    'ZA': Offset(0.52, 0.72), // 南非 - 非洲最南
    'EG': Offset(0.52, 0.40), // 埃及 - 非洲北部
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.connectedNodeCountry != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WorldMapBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectedNodeCountry != oldWidget.connectedNodeCountry) {
      if (widget.connectedNodeCountry != null) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 地图背景
        Opacity(
          opacity: widget.opacity,
          child: Image.asset(
            'assets/images/world_map.png',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // 呼吸灯效果
        if (widget.connectedNodeCountry != null)
          _buildBreathingLight(widget.connectedNodeCountry!),
      ],
    );
  }

  /// 构建呼吸灯效果
  Widget _buildBreathingLight(String countryCode) {
    print('[WorldMapBackground] Country code: $countryCode (uppercase: ${countryCode.toUpperCase()})');
    final position = _countryPositions[countryCode.toUpperCase()];
    print('[WorldMapBackground] Position for $countryCode: $position');
    if (position == null) {
      // 如果没有找到对应的国家位置，使用默认位置（地图中心）
      print('[WorldMapBackground] No position found for country: $countryCode');
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // 计算实际位置
        final left = width * position.dx - 40; // 减去光点半径的一半
        final top = height * position.dy - 40;

        return Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: _pulseAnimation.value * 0.6),
                      blurRadius: 30 * _pulseAnimation.value,
                      spreadRadius: 10 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: _pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
