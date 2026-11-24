import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Atmosferik ekran arka planı: derin gece lacivertinden koyu mora yumuşak
/// gradyan ve üstte hafif bir ışık hâlesi. Statik katman `RepaintBoundary`
/// içindedir; üstteki animasyonlar arka planı yeniden çizdirmez.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  static const BoxDecoration decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.atmosphereTop, AppColors.atmosphereMid, AppColors.atmosphereBottom],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: decoration),
              // Üstten yumuşak ışık hâlesi
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -1.0),
                    radius: 1.1,
                    colors: [Color(0x337C5CFC), Color(0x00000000)],
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
