import 'package:flutter/cupertino.dart';

/// A minimal line-and-area sparkline for a metric's recent history (e.g.
/// CPU or memory usage over the last N samples).
///
/// Values are auto-scaled to their own min/max within this sparkline, so
/// short-term variation stays visible regardless of the metric's absolute
/// level - the current reading is already shown as text next to it.
class TrendSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const TrendSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // Not enough history yet - draw a flat baseline so the space isn't
      // empty while the first samples come in.
      final y = size.height * 0.7;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 2,
      );
      return;
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 1e-6
        ? 1.0
        : maxValue - minValue;

    final dx = size.width / (values.length - 1);
    Offset pointAt(int index) {
      final normalized = (values[index] - minValue) / range;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      return Offset(dx * index, y);
    }

    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    final fillPath = Path()
      ..moveTo(pointAt(0).dx, size.height)
      ..lineTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      linePath.lineTo(point.dx, point.dy);
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.08));
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
