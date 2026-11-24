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
