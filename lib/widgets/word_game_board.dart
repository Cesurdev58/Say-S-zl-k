import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui/animated_slot.dart';
import 'ui/error_shake.dart';
import 'ui/game_card.dart';
import 'ui/game_tile.dart';
import 'ui/motion.dart';

class WordGameBoard extends StatelessWidget {
  final List<String> availableLetters;
  final List<int> selectedIndices;
  final List<String> selectedLetters;
  final bool isPaused;
  final Function(int, String) onLetterTap;
  final Function(int) onJokerTap;

  /// Her artışında cevap alanı sallanır ve kısa süre kırmızı kenarlık gösterir.
  final ValueNotifier<int>? errorSignal;

  const WordGameBoard({
    super.key,
    required this.availableLetters,
    required this.selectedIndices,
    required this.selectedLetters,
    required this.isPaused,
    required this.onLetterTap,
    required this.onJokerTap,
    this.errorSignal,
  });

  @override
  Widget build(BuildContext context) {
    final int slotCount = availableLetters.length > selectedLetters.length ? availableLetters.length : selectedLetters.length;

    Widget answerRow = GameCard(
      borderColor: AppColors.primaryDeep.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42, minWidth: double.infinity),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: Motion.of(context, const Duration(milliseconds: 150)),
              opacity: selectedLetters.isEmpty ? 1 : 0,
              child: Text('Harflere Dokunarak Kelime Oluştur', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slotCount, (i) {
                final bool filled = i < selectedLetters.length;
                final String char = filled ? selectedLetters[i] : '';
                return AnimatedSlot(
                  child: filled
                      ? Padding(
                          key: ValueKey('slot-$i-$char'),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GameTile(
                            width: 36,
                            height: 42,
                            radius: AppRadius.sm,
                            color: AppColors.primaryDeep,
                            borderColor: AppColors.primaryBright,
                            child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        )
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
    if (errorSignal != null) {
      answerRow = ErrorShake(trigger: errorSignal!, borderRadius: AppRadius.lg, child: answerRow);
    }

    return Column(
      children: [
        answerRow,
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1
          ),
          itemCount: availableLetters.length,
          itemBuilder: (context, index) {
            String char = availableLetters[index];
            bool isUsed = selectedIndices.contains(index);

            return GameTile(
              radius: AppRadius.md + 2,
              flat: isUsed,
              color: isUsed ? AppColors.surface.withValues(alpha: 0.4) : (char == 'JOKER' ? AppColors.joker : AppColors.primaryDeep),
              onTap: isUsed || isPaused
                  ? null
                  : () {
                      if (char == 'JOKER') {
                        onJokerTap(index);
                      } else {
                        onLetterTap(index, char);
                      }
                    },
              child: Text(char, style: TextStyle(color: isUsed ? Colors.white24 : Colors.white, fontSize: char == 'JOKER' ? 11 : 20, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }
}
