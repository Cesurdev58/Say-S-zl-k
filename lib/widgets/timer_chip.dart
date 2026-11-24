import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Kalan süreyi gösteren rozet. Yalnızca kendisi yeniden çizilir; ekranın
/// geri kalanı her saniye rebuild edilmez.
class TimerChip extends StatelessWidget {
  const TimerChip({
    super.key,
    required this.seconds,
    required this.warnAt,
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.borderRadius = 12,
    this.fontSize = 12,
  });

  final ValueListenable<int> seconds;

  /// Bu değer ve altında rozet kırmızıya döner.
  final int warnAt;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: seconds,
      builder: (context, value, _) {
        final bool warn = value <= warnAt;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: warn ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF232042),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: warn ? Colors.redAccent : const Color(0xFF7C5CFC)),
          ),
          child: Text(
            '${value}s',
            style: TextStyle(
              color: warn ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        );
      },
    );
  }
}
