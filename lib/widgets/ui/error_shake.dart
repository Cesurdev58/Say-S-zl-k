import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

/// [trigger] her arttığında çocuğu yatay sallar ve kısa süre kırmızı kenarlık gösterir.
/// Hareket azaltma açıksa sallanma yapılmaz, yalnızca kenarlık vurgusu görünür.
class ErrorShake extends StatefulWidget {
  const ErrorShake({
    super.key,
    required this.trigger,
    required this.child,
    this.borderRadius = 18,
    this.amplitude = 10,
  });

  final ValueListenable<int> trigger;
  final Widget child;
  final double borderRadius;
  final double amplitude;

  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -1.0, end: 1.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: -0.8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -0.8, end: 0.6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_onTrigger);
  }

  @override
  void didUpdateWidget(ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_onTrigger);
      widget.trigger.addListener(_onTrigger);
    }
  }

  void _onTrigger() {
    if (mounted) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = Motion.reduced(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double dx = reduced ? 0 : _offset.value * widget.amplitude;
        final double flash = _controller.isAnimating ? (1 - _controller.value) : 0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Stack(
            children: [
              child!,
              if (flash > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: flash), width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
