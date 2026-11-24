import 'package:flutter/material.dart';

import 'motion.dart';

/// İçeriği değiştiğinde ölçek + yumuşak geçişle giren/çıkan yuva.
/// [child] `null` ise yuva boştur (genişlik 0). Çocuğun anahtarı (`key`) değişince geçiş oynar.
class AnimatedSlot extends StatelessWidget {
  const AnimatedSlot({super.key, this.child, this.duration = const Duration(milliseconds: 180)});

  final Widget? child;
  final Duration duration;

  /// Ölçek (hafif yaylanmalı) + opaklık geçişi.
  static Widget transition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, duration),
      transitionBuilder: transition,
      child: child ?? const SizedBox.shrink(key: ValueKey('empty-slot')),
    );
  }
}
