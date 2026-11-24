import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ui/motion.dart';
import '../theme/app_colors.dart';

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
          duration: Motion.of(context, const Duration(milliseconds: 300)),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: warn ? Colors.redAccent.withValues(alpha: 0.3) : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: warn ? Colors.redAccent : AppColors.primary),
          ),
          child: Text(
            '${value}s',
            style: AppText.counter(color: warn ? Colors.redAccent : Colors.white, fontSize: fontSize),
          ),
        );
      },
    );
  }
}
