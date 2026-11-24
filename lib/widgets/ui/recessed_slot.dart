import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// İçe göçük (recessed) yuva: koyu zemin, üstten iç gölge ve ince kenarlık.
/// İçine taş oturacakmış hissi verir; [dashed] true ise kenarlık kesiklidir.
class RecessedSlot extends StatelessWidget {
  const RecessedSlot({
    super.key,
    this.width,
    this.height,
    this.child,
    this.radius = AppRadius.md,
    this.dashed = true,
    this.padding = EdgeInsets.zero,
  });

  final double? width;
  final double? height;
  final Widget? child;
  final double radius;
  final bool dashed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SlotBorderPainter(radius: radius, dashed: dashed),
        child: ClipRRect(
          borderRadius: br,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Zemini koyulaştıran yarı saydam siyah + üstten iç gölge
              color: Colors.black.withValues(alpha: 0.32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                stops: const [0, 0.45],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _SlotBorderPainter extends CustomPainter {
  _SlotBorderPainter({required this.radius, required this.dashed});

  final double radius;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: dashed ? 0.22 : 0.1);
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5);
    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }
    const double dash = 4;
    const double gap = 3;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SlotBorderPainter old) => old.radius != radius || old.dashed != dashed;
}
