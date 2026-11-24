import 'package:flutter/material.dart';

import '../widgets/ui/motion.dart';

/// Yumuşak fade + hafif aşağıdan kayma sayfa geçişi.
/// Cihazda "animasyonları azalt" açıksa geçiş efekti uygulanmaz.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  static final Animatable<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(position: animation.drive(_slide), child: child),
    );
  }
}
