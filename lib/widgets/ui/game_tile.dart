import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Harf/sayı/işlem taşı: üstte ince ışık, altta yumuşak gölge ve tutarlı köşe yarıçapı.
///
/// [flat] true iken (kullanılmış/pasif taş) gölge ve parlaklık kaldırılır.
class GameTile extends StatelessWidget {
  const GameTile({
    super.key,
    required this.color,
    required this.child,
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.borderColor,
    this.flat = false,
    this.duration = const Duration(milliseconds: 150),
  });

  final Color color;
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  /// Verilmezse yarı saydam beyaz kenarlık kullanılır.
  final Color? borderColor;
  final bool flat;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    final Color top = flat ? color : Color.alphaBlend(Colors.white.withValues(alpha: 0.14), color);
    return AnimatedContainer(
      duration: duration,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, color]),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: flat ? 0.05 : 0.16)),
        boxShadow: flat ? null : [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Center(child: child),
    );
  }
}
