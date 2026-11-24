import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Oyun sonunda "Kaçırılan Çözümler" listesindeki tek bir kart.
///
/// [solution] anahtarları: kelime için `type`, `letters`, `bestWord`;
/// işlem için `type`, `target`, `mathSteps`.
class MissedSolutionTile extends StatelessWidget {
  const MissedSolutionTile({super.key, required this.solution});

  final Map<String, dynamic> solution;

  @override
  Widget build(BuildContext context) {
    final sol = solution;
    final bool isWord = sol['type'] == 'word';
    return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                            child: isWord
                                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Harfler: ${sol['letters']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                    Text('${sol['bestWord']} (${sol['bestWord'].length} Harf)',
                                        style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold))
                                  ])
                                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Hedef: ${sol['target']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                    ...(sol['mathSteps'] as List<String>).map((step) =>
                                        Text(step, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)))
                                  ]),
                          );
  }
}
