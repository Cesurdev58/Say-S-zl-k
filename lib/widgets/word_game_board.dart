import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui/answer_slots.dart';
import 'ui/error_shake.dart';
import 'ui/game_card.dart';
import 'ui/game_tile.dart';

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
    Widget answerRow = GameCard(
      borderColor: AppColors.primaryDeep.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: AnswerSlots(letters: selectedLetters, slotCount: availableLetters.length),
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
