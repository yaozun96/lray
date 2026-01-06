import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 世界地图背景 V2 - 使用 flutter_map 显示真实地图
class WorldMapBackgroundV2 extends StatefulWidget {
  final double opacity;
  final String? connectedNodeCountry; // 当前连接的节点国家代码

  const WorldMapBackgroundV2({
    super.key,
    this.opacity = 0.15,
    this.connectedNodeCountry,
  });

  @override
  State<WorldMapBackgroundV2> createState() => _WorldMapBackgroundV2State();
}

class _WorldMapBackgroundV2State extends State<WorldMapBackgroundV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 国家/地区代码到经纬度坐标的映射
  static const Map<String, LatLng> _countryCoordinates = {
    // 亚洲
    'CN': LatLng(35.8617, 104.1954), // 中国 - 北京附近
    'HK': LatLng(22.3193, 114.1694), // 香港
    'TW': LatLng(23.6978, 120.9605), // 台湾
    'JP': LatLng(36.2048, 138.2529), // 日本 - 东京附近
    'KR': LatLng(37.5665, 126.9780), // 韩国 - 首尔
    'SG': LatLng(1.3521, 103.8198), // 新加坡
    'IN': LatLng(20.5937, 78.9629), // 印度
    'TH': LatLng(15.8700, 100.9925), // 泰国
    'VN': LatLng(14.0583, 108.2772), // 越南
    'MY': LatLng(4.2105, 101.9758), // 马来西亚
    'PH': LatLng(12.8797, 121.7740), // 菲律宾
    'ID': LatLng(-0.7893, 113.9213), // 印度尼西亚

    // 北美
    'US': LatLng(37.0902, -95.7129), // 美国
    'CA': LatLng(56.1304, -106.3468), // 加拿大
    'MX': LatLng(23.6345, -102.5528), // 墨西哥

    // 欧洲
    'GB': LatLng(55.3781, -3.4360), // 英国
    'FR': LatLng(46.2276, 2.2137), // 法国
    'DE': LatLng(51.1657, 10.4515), // 德国
    'NL': LatLng(52.1326, 5.2913), // 荷兰
    'IT': LatLng(41.8719, 12.5674), // 意大利
    'ES': LatLng(40.4637, -3.7492), // 西班牙
    'SE': LatLng(60.1282, 18.6435), // 瑞典
    'NO': LatLng(60.4720, 8.4689), // 挪威
    'RU': LatLng(61.5240, 105.3188), // 俄罗斯

    // 大洋洲
    'AU': LatLng(-25.2744, 133.7751), // 澳大利亚
    'NZ': LatLng(-40.9006, 174.8860), // 新西兰

    // 南美
    'BR': LatLng(-14.2350, -51.9253), // 巴西
    'AR': LatLng(-38.4161, -63.6167), // 阿根廷
    'CL': LatLng(-35.6751, -71.5430), // 智利

    // 中东
    'AE': LatLng(23.4241, 53.8478), // 阿联酋
    'TR': LatLng(38.9637, 35.2433), // 土耳其
    'SA': LatLng(23.8859, 45.0792), // 沙特阿拉伯

    // 非洲
    'ZA': LatLng(-30.5595, 22.9375), // 南非
    'EG': LatLng(26.8206, 30.8025), // 埃及
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
  void didUpdateWidget(WorldMapBackgroundV2 oldWidget) {
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
    final connectedLocation = widget.connectedNodeCountry != null
        ? _countryCoordinates[widget.connectedNodeCountry!.toUpperCase()]
        : null;
        
    print('[WorldMap] Received country: ${widget.connectedNodeCountry}, coordinates found: ${connectedLocation != null}');

    return Opacity(
      opacity: widget.opacity,
      child: FlutterMap(
        options: MapOptions(
          // 世界地图居中 - 偏向北半球，避免显示南极
          initialCenter: const LatLng(35.0, 15.0),
          initialZoom: 1.6,
          minZoom: 1.5,
          maxZoom: 3.0,
          // 禁用交互,作为静态背景
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
          // 限制相机范围，避免显示南极和北极
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(-40.0, -180.0), // 西南角 - 不显示南极（南纬40度以南）
              const LatLng(70.0, 180.0),   // 东北角 - 减少北极区域
            ),
          ),
        ),
        children: [
          // 地图瓦片层 - 使用 CartoDB 灰度样式（无标签），符合性冷淡风格
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.soravpn.app',
            maxNativeZoom: 19,
          ),

          // 呼吸灯标记层
          if (connectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: connectedLocation,
                  width: 60,
                  height: 60,
                  child: _buildBreathingLight(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建呼吸灯效果
  Widget _buildBreathingLight() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // 简洁的呼吸灯：实心圆 + 单层淡出圆环
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 外圈：淡出的脉冲圆环
              Container(
                width: 40 * _pulseAnimation.value,
                height: 40 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.3 * (1 - _pulseAnimation.value)),
                ),
              ),
              // 内圈：固定的实心点
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
