import 'package:flutter/material.dart';

/// Oyun ekranlarında kullanılan mor-lacivert gradient arka plan.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  static BoxDecoration get decoration => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF312E81),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(decoration: decoration, child: child);
  }
}

/// Oyun ekranları için ortak renk sabitleri.
abstract final class GameColors {
  static const primary = Color(0xFF7C5CFC);
  static const primaryDark = Color(0xFF4F46E5);
  static const accent = Color(0xFFA78BFA);
  static const cardGradientStart = Color(0xFF5B3FD9);
  static const cardGradientEnd = Color(0xFF1E3A8A);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFF87171);
}
