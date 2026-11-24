import 'package:flutter/material.dart';
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
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.background.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isWord ? 'Olası En Uzun Kelime' : 'Adım Adım Tam Çözüm', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAlt,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onNext,
                  child: const Text('Sonraki Soruya Geç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
