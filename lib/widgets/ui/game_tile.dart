import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'motion.dart';

/// Fiziksel tuş gibi 3D taş: yüzeyde hafif dikey gradyan, altta 4px koyu "dudak".
///
/// [onTap] verilirse basıldığında taş 3px aşağı iner (dudak 4px'ten 1px'e düşer)
/// ve `scale: 0.92`'ye göçer; bırakılınca `easeOutBack` ile yaylanarak yerine oturur.
/// [flat] true iken (kullanılmış/pasif taş) taş yuvasına tamamen gömülü, düzdür.
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

  /// Basılmamış taşın altındaki koyu dudağın kalınlığı.
  static const double lipHeight = 4;

  /// Basılınca taşın aşağı inme miktarı.
  static const double pressDepth = 3;

  static const double pressedScale = 0.92;

  final Color color;
  final Widget child;

  /// Verilen yükseklik dudak dahil toplam yüksekliktir (yüz = height - 4).
  final double? width;
  final double? height;
  final double radius;

  /// Verilmezse yarı saydam beyaz kenarlık kullanılır.
  final Color? borderColor;
  final bool flat;

  /// `null` ise taş dokunmaya tepki vermez (ve basma animasyonu yoktur).
  final VoidCallback? onTap;
  final Duration duration;

  /// Dudak rengi: taş renginin koyu tonu.
  static Color lipColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).withSaturation((hsl.saturation * 1.05).clamp(0.0, 1.0)).toColor().withValues(alpha: base.a);
  }

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
    const double lip = GameTile.lipHeight;
    final BorderRadius br = BorderRadius.circular(widget.radius);
    final bool flat = widget.flat;
    final bool down = _pressed && widget.onTap != null;

    // Yüzün üstten kayma miktarı: normal 0, basılı 3, gömülü (flat) 4.
    final double offsetY = flat ? lip : (down ? GameTile.pressDepth : 0);
    final Color top = flat ? widget.color : Color.alphaBlend(Colors.white.withValues(alpha: 0.18), widget.color);
    final Color bottom = flat ? widget.color : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), widget.color);
    final Duration d = Motion.of(context, widget.duration);

    final Widget face = AnimatedContainer(
      duration: d,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
        border: Border.all(color: widget.borderColor ?? Colors.white.withValues(alpha: flat ? 0.05 : 0.2)),
      ),
      child: Center(child: widget.child),
    );

    Widget tile = Stack(
      children: [
        // Koyu dudak katmanı (yüzün 4px altında başlar; üst kenarı hiç görünmez).
        Positioned(
          left: 0,
          right: 0,
          top: lip,
          bottom: 0,
          child: AnimatedOpacity(
            duration: d,
            opacity: flat ? 0 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GameTile.lipColor(widget.color),
                borderRadius: br,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))],
              ),
            ),
          ),
        ),
        AnimatedPadding(
          duration: d,
          curve: down ? Curves.easeOut : Curves.easeOutBack,
          padding: EdgeInsets.only(top: offsetY, bottom: lip - offsetY),
          child: face,
        ),
      ],
    );

    if (widget.width != null || widget.height != null) {
      tile = SizedBox(width: widget.width, height: widget.height, child: tile);
    }

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
