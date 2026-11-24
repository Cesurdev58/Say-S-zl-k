import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

/// "EFSANE!" gibi övgü metni. [trigger] her arttığında bir kez oynar.
///
/// Performans için: ağır (yüksek `blurRadius`'lu) gölgeler yoktur, yalnızca
/// bulanıklıksız tek bir sert gölge kullanılır; metin bir kez çizilip
/// `RepaintBoundary` içinde yalnızca ölçek/opaklık/kayma dönüşümüyle animasyonlanır.
/// Hareket azaltma açıksa sadece yumuşak bir solma uygulanır.
class PraiseOverlay extends StatefulWidget {
  const PraiseOverlay({
    super.key,
    required this.trigger,
    this.words = defaultWords,
    this.alignment = const Alignment(0, -0.2),
  });

  static const List<String> defaultWords = ['MÜKEMMEL!', 'HARİKA!', 'ZEKİCE!', 'EFSANE!', 'ZAFER!'];

  final ValueListenable<int> trigger;
  final List<String> words;
  final Alignment alignment;

  @override
  State<PraiseOverlay> createState() => _PraiseOverlayState();
}

class _PraiseOverlayState extends State<PraiseOverlay> with SingleTickerProviderStateMixin {
  static const TextStyle _style = TextStyle(
    color: Colors.amber,
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    // Tek, bulanıklıksız sert gölge (ucuz); eski blurRadius 20/10 gölgeleri kaldırıldı.
    shadows: [Shadow(color: Colors.black54, offset: Offset(0, 3))],
  );

  final Random _random = Random();
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
  ]).animate(_controller);

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
  ]).animate(_controller);

  late final Animation<double> _lift = Tween<double>(begin: 0, end: -22).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  String _word = '';

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_play);
  }

  @override
  void didUpdateWidget(PraiseOverlay old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      old.trigger.removeListener(_play);
      widget.trigger.addListener(_play);
    }
  }

  void _play() {
    if (!mounted) return;
    setState(() => _word = widget.words[_random.nextInt(widget.words.length)]);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_play);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = Motion.reduced(context);
    return IgnorePointer(
      child: Align(
        alignment: widget.alignment,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            // Metin yalnızca _word değişince yeniden kurulur; kare başına değil.
            child: Text(_word, textAlign: TextAlign.center, style: _style),
            builder: (context, child) {
              // Başlamadan önce ve bittikten sonra hiçbir katman çizilmez.
              if (_controller.isDismissed || _controller.isCompleted) return const SizedBox.shrink();
              Widget w = child!;
              if (!reduced) {
                w = Transform.translate(offset: Offset(0, _lift.value), child: Transform.scale(scale: _scale.value, child: w));
              }
              return Opacity(opacity: _opacity.value, child: w);
            },
          ),
        ),
      ),
    );
  }
}
