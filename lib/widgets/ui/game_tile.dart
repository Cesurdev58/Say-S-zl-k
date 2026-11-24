import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'motion.dart';

/// Harf/sayı/işlem taşı: üstte ince ışık, altta yumuşak gölge ve tutarlı köşe yarıçapı.
///
/// [onTap] verilirse dokunulduğunda hafifçe içeri göçer (`scale: 0.92`),
/// bırakıldığında yaylanarak (`easeOutBack`) yerine oturur.
/// [flat] true iken (kullanılmış/pasif taş) gölge ve parlaklık kaldırılır.
class GameTile extends StatefulWidget {
  const GameTile({
    super.key,
    required this.color,
    required this.child,
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.borderColor,
    this.flat = false,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
  });

  static const double pressedScale = 0.92;

  final Color color;
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  /// Verilmezse yarı saydam beyaz kenarlık kullanılır.
  final Color? borderColor;
  final bool flat;

  /// `null` ise taş dokunmaya tepki vermez (ve basma animasyonu yoktur).
  final VoidCallback? onTap;
  final Duration duration;

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(widget.radius);
    final Color top = widget.flat ? widget.color : Color.alphaBlend(Colors.white.withValues(alpha: 0.14), widget.color);
    Widget tile = AnimatedContainer(
      duration: Motion.of(context, widget.duration),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, widget.color]),
        border: Border.all(color: widget.borderColor ?? Colors.white.withValues(alpha: widget.flat ? 0.05 : 0.16)),
        boxShadow: widget.flat ? null : [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Center(child: widget.child),
    );

    if (widget.onTap == null) return tile;

    tile = AnimatedScale(
      scale: _pressed ? GameTile.pressedScale : 1.0,
      duration: Motion.of(context, const Duration(milliseconds: 140)),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: tile,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: tile,
    );
  }
}
