import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui/game_card.dart';
import 'ui/game_tile.dart';

class WordGameBoard extends StatelessWidget {
  final List<String> availableLetters;
  final List<int> selectedIndices;
  final List<String> selectedLetters;
  final bool isPaused;
  final Function(int, String) onLetterTap;
  final Function(int) onJokerTap;

  const WordGameBoard({
    super.key,
    required this.availableLetters,
    required this.selectedIndices,
    required this.selectedLetters,
    required this.isPaused,
    required this.onLetterTap,
    required this.onJokerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameCard(
          borderColor: AppColors.primaryDeep.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42, minWidth: double.infinity),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: selectedLetters.isEmpty
                ? [Text('Harflere Dokunarak Kelime Oluştur', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12))]
                : selectedLetters.map((char) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GameTile(
                        width: 36, height: 42,
                        radius: AppRadius.sm,
                        color: AppColors.primaryDeep,
                        borderColor: AppColors.primaryBright,
                        child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )).toList(),
            ),
          ),
        ),
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

            return InkWell(
              onTap: isUsed || isPaused ? null : () {
                if (char == 'JOKER') {
                  onJokerTap(index);
                } else {
                  onLetterTap(index, char);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: GameTile(
                radius: AppRadius.md + 2,
                flat: isUsed,
                color: isUsed ? AppColors.surface.withValues(alpha: 0.4) : (char == 'JOKER' ? AppColors.joker : AppColors.primaryDeep),
                child: Text(char, style: TextStyle(color: isUsed ? Colors.white24 : Colors.white, fontSize: char == 'JOKER' ? 11 : 20, fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ],
    );
  }
}