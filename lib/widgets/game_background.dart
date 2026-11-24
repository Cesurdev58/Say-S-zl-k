import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Oyun ekranlarında kullanılan mor-lacivert gradient arka plan.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  static BoxDecoration get decoration => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientTop,
            AppColors.gradientMid,
            AppColors.gradientBottom,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(decoration: decoration, child: child);
  }
}
