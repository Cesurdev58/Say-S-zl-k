import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Katmanlı kart: ince üst kenar ışığı, belirgin kenarlık ve yumuşak alt gölge.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Verilmezse `GameColors.surface` kullanılır.
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Yumuşak alt gölgeyi açar/kapatır.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final BorderRadius br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: br,
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
        boxShadow: elevated ? [BoxShadow(color: colors.shadow, blurRadius: 14, offset: const Offset(0, 6))] : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // Üst kenar ışığı
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, colors.edgeLight, Colors.transparent]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
