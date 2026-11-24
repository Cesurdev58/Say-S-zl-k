import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Düşük maliyetli kutlama konfetisi.
///
/// Kasmayı azaltmak için: az parçacık (10–12), kısa yayılım süresi (550ms),
/// küçük ve basit (dikdörtgen) parçacıklar, hızlı düşüş (yerçekimi yüksek →
/// parçacıklar ekrandan çabuk çıkıp silinir) ve tek patlama (`emissionFrequency: 0`).
/// Her yayıcı kendi `RepaintBoundary`'sinde çizilir.
class GameConfetti extends StatelessWidget {
  const GameConfetti({
    super.key,
    required this.controller,
    this.blastDirection,
    this.numberOfParticles = 10,
    this.alignment = Alignment.center,
  });

  /// Yayılım süresi (kısa tutulur).
  static const Duration duration = Duration(milliseconds: 550);

  static ConfettiController newController() => ConfettiController(duration: duration);

  final ConfettiController controller;

  /// Verilmezse her yöne (explosive) saçılır.
  final double? blastDirection;
  final int numberOfParticles;
  final Alignment alignment;

  static const List<Color> _colors = [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple];

  /// Çok basit, küçük dikdörtgen parçacık.
  static Path _lightParticle(Size size) => Path()..addRect(Rect.fromLTWH(-size.width, 0, size.width, size.height));

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: ConfettiWidget(
            confettiController: controller,
            blastDirectionality: blastDirection == null ? BlastDirectionality.explosive : BlastDirectionality.directional,
            blastDirection: blastDirection ?? pi,
            emissionFrequency: 0,
            numberOfParticles: numberOfParticles,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.45,
            minimumSize: const Size(7, 4),
            maximumSize: const Size(11, 6),
            createParticlePath: _lightParticle,
            colors: _colors,
          ),
        ),
      ),
    );
  }
}
