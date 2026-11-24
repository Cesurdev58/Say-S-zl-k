import 'package:flutter/material.dart';

import 'motion.dart';

/// Dokunulabilir alan: basılıyken hafifçe küçülür, bırakılınca yaylanarak döner.
/// `onTap` null ise tepki vermez. Ekran okuyucular için `button` olarak işaretlenir.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: Motion.of(context, const Duration(milliseconds: 140)),
          curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}
