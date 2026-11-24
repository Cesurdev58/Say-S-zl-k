import 'package:flutter/material.dart';

import 'ui/game_button.dart';
import 'ui/game_dialog.dart';
import '../theme/app_colors.dart';

/// Süresiz solo modda "Çözümü Göster" diyaloğu: en uzun kelime veya adım adım işlem çözümü.
class SolutionDialog extends StatelessWidget {
  const SolutionDialog({
    super.key,
    required this.isWord,
    required this.bestWord,
    required this.mathSteps,
    required this.onNext,
  });

  final bool isWord;
  final String bestWord;
  final List<String> mathSteps;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GameDialog(
      title: isWord ? 'Olası En Uzun Kelime' : 'Adım Adım Tam Çözüm',
      actions: [
        GameButton(label: 'Sonraki Soruya Geç', onPressed: onNext, fontSize: 14),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              if (isWord) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    bestWord == "SÖZLÜKTE KELİME BULUNAMADI"
                        ? "Bu harflerle sözlükte eşleşen kelime bulunamadı."
                        : "$bestWord (${bestWord.length} Harf)",
                    style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mathSteps.map((step) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppColors.accent, size: 16),
                            const SizedBox(width: 8),
                            Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
        ],
      ),
    );
  }
}
