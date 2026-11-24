import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'count_up_text.dart';

/// Hedef sayı "skor tabelası / enerji çekirdeği": dış parlama (glow), çift
/// kenarlık ve iri, tabular rakamlı sayı. Yeni hedefte 0'dan sayarak belirir.
class TargetCore extends StatelessWidget {
  const TargetCore({super.key, required this.value, this.numberSize = 46});

  final int value;
  final double numberSize;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(AppRadius.xl - 2);
    return Semantics(
      label: 'Hedef sayı $value',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 26, spreadRadius: 1),
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 44, spreadRadius: 2),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: const RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [AppColors.primaryBright, AppColors.primaryDeep, Color(0xFF2A1F7A)],
                stops: [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: Colors.black.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _led(),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HEDEF SAYI',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3),
                      ),
                      // Yeni tur: hedef sayı 0'dan hedefe sayarak belirir.
                      CountUpText(
                        key: ValueKey('target-$value'),
                        value: value,
                        fromZero: true,
                        style: AppText.counter(fontSize: numberSize, fontWeight: FontWeight.w900).copyWith(
                          letterSpacing: 3,
                          height: 1.1,
                          shadows: [
                            Shadow(color: AppColors.accent.withValues(alpha: 0.9), blurRadius: 16),
                            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  _led(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _led() => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.8), blurRadius: 8)],
        ),
      );
}
