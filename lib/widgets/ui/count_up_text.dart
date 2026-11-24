import 'package:flutter/material.dart';

import 'motion.dart';

/// Sayıyı kısa bir sayaç animasyonuyla gösterir.
///
/// [value] değişince eski değerden yenisine sayar. [fromZero] true ise ilk
/// gösterimde 0'dan başlar (yeni hedef sayı turu gibi).
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.fromZero = false,
    this.duration = const Duration(milliseconds: 500),
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final bool fromZero;
  final Duration duration;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: fromZero ? 0 : value, end: value),
      duration: Motion.of(context, duration),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v$suffix', style: style),
    );
  }
}
