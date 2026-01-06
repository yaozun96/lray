import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_clash/soravpn_ui/theme/app_theme.dart';

/// 流量监控图表组件
class TrafficChart extends StatefulWidget {
  final bool isConnected;

  const TrafficChart({
    super.key,
    required this.isConnected,
  });

  @override
  State<TrafficChart> createState() => _TrafficChartState();
}

class _TrafficChartState extends State<TrafficChart> {
  final List<double> _downloadData = List.filled(50, 0);
  final List<double> _uploadData = List.filled(50, 0);
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 开始监控
  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (widget.isConnected && mounted) {
        setState(() {
          // 模拟流量数据（实际应该从系统获取真实数据）
          _downloadData.removeAt(0);
          _uploadData.removeAt(0);
          _downloadData.add(_random.nextDouble() * 100);
          _uploadData.add(_random.nextDouble() * 50);
        });
      } else if (mounted) {
        setState(() {
          // 未连接时清零
          for (int i = 0; i < _downloadData.length; i++) {
            _downloadData[i] = max(0, _downloadData[i] * 0.8);
            _uploadData[i] = max(0, _uploadData[i] * 0.8);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和图例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '实时流量监控',
                style: TextStyle(
                  color: AppTheme.textLightPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildLegend('下载', AppTheme.success),
                  const SizedBox(width: 16),
                  _buildLegend('上传', AppTheme.info),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 图表
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrafficChartPainter(
                downloadData: _downloadData,
                uploadData: _uploadData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 图例
  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLightSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// 流量图表绘制器
class _TrafficChartPainter extends CustomPainter {
  final List<double> downloadData;
  final List<double> uploadData;

  _TrafficChartPainter({
    required this.downloadData,
    required this.uploadData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格线
    _drawGrid(canvas, size);

    // 绘制下载曲线
    _drawCurve(
      canvas,
      size,
      downloadData,
      AppTheme.success,
    );

    // 绘制上传曲线
    _drawCurve(
      canvas,
      size,
      uploadData,
      AppTheme.info,
    );
  }

  /// 绘制网格线
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 绘制横线
    for (int i = 0; i <= 4; i++) {
      final y = size.height / 4 * i;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);

      // 虚线效果
      final dashedPath = _createDashedPath(path, dashWidth: 5, dashSpace: 5);
      canvas.drawPath(dashedPath, paint);
    }
  }

  /// 绘制曲线
  void _drawCurve(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    // 计算最大值
    final maxValue = data.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    // 开始绘制
    final stepX = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // 填充区域路径
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 绘制填充
    canvas.drawPath(fillPath, fillPaint);

    // 绘制曲线
    canvas.drawPath(path, paint);
  }

  /// 创建虚线路径
  Path _createDashedPath(Path source, {required double dashWidth, required double dashSpace}) {
    final path = Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        final segment = metric.extractPath(distance, distance + length);
        if (draw) {
          path.addPath(segment, Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
