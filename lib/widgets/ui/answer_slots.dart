import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'animated_slot.dart';
import 'game_tile.dart';
import 'recessed_slot.dart';

/// Cevap satırı: her harf için içe göçük bir yuva; seçilen harfler yuvaya
/// ölçek + yumuşak geçişle oturur, silinince çıkar.
class AnswerSlots extends StatelessWidget {
  const AnswerSlots({
    super.key,
    required this.letters,
    required this.slotCount,
    this.tileColor = AppColors.primaryDeep,
    this.maxSlotWidth = 40,
    this.slotHeight = 48,
    this.gap = 6,
  });

  final List<String> letters;

  /// Gösterilecek yuva sayısı (genellikle dağıtılan taş sayısı).
  final int slotCount;
  final Color tileColor;
  final double maxSlotWidth;
  final double slotHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final int n = slotCount > letters.length ? slotCount : letters.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dar ekranlarda yuvalar küçülür; taşma olmaz.
        final double avail = constraints.maxWidth.isFinite ? constraints.maxWidth : n * (maxSlotWidth + gap);
        final double w = ((avail - gap * (n - 1)) / n).clamp(24.0, maxSlotWidth).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(n, (i) {
            final bool filled = i < letters.length;
            final String char = filled ? letters[i] : '';
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
              child: RecessedSlot(
                width: w,
                height: slotHeight,
                radius: AppRadius.sm,
                padding: const EdgeInsets.all(2),
                child: AnimatedSlot(
                  child: filled
                      ? GameTile(
                          key: ValueKey('slot-$i-$char'),
                          radius: AppRadius.sm - 2,
                          color: tileColor,
                          borderColor: AppColors.primaryBright,
                          child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
