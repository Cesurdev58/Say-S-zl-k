import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GameOverDialog extends StatefulWidget {
  final int totalScore;
  final int wordScore;
  final int mathScore;
  final List<Map<String, dynamic>> missedSolutions;
  final VoidCallback onHome;
  final VoidCallback onReplay;

  const GameOverDialog({
    super.key,
    required this.totalScore,
    required this.wordScore,
    required this.mathScore,
    required this.missedSolutions,
    required this.onHome,
    required this.onReplay,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasSolutions = widget.missedSolutions.isNotEmpty;

    // --- HİLEYİ ÖNLEYEN DÜZELTME ---
    // PopScope ile sistemin (telefonun) geri tuşunu tamamen kilitliyoruz.
    return PopScope(
      canPop: false, // geri tuşunu etkisiz kılar
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.joker.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_off_rounded, color: AppColors.joker, size: 38),
                ),
                const SizedBox(height: 12),
                const Text('Oyun Bitti!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),

                _ScoreRow(label: 'Kelime Puanı:', value: '${widget.wordScore}'),
                const SizedBox(height: 6),
                _ScoreRow(label: 'İşlem Puanı:', value: '+${widget.mathScore}', isAccent: true),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOPLAM PUAN:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text('${widget.totalScore}', style: const TextStyle(color: AppColors.joker, fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // --- SLIDEBAR (ÇÖZÜMLER) ---
                if (hasSolutions) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Çözüm Rehberi (Kaydırın)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180, // Slidebar yüksekliği
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: widget.missedSolutions.length,
                      itemBuilder: (context, index) {
                        final sol = widget.missedSolutions[index];
                        if (sol['type'] == 'word') {
                          return _buildWordSolution(sol['letters'], sol['bestWord']);
                        } else {
                          return _buildMathSolution(sol['target'], sol['mathSteps']);
                        }
                      },
                    ),
                  ),
                  // Sayfa Noktaları
                  if (widget.missedSolutions.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.missedSolutions.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? AppColors.joker : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: () { Navigator.pop(context); widget.onHome(); },
                          child: const Text('Ana Menü', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAlt, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: () { Navigator.pop(context); widget.onReplay(); },
                          child: const Text('Tekrar Oyna', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordSolution(String letters, String bestWord) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.spellcheck_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text('Olası En Uzun Kelime:', style: TextStyle(color: AppColors.joker, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Harfler: $letters', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            bestWord == "SÖZLÜKTE KELİME BULUNAMADI" ? bestWord : '$bestWord (${bestWord.length} Harf)',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildMathSolution(int target, List<String> steps) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes_rounded, color: Colors.redAccent, size: 16),
                const SizedBox(width: 6),
                Text('Hedef: $target (Tam Çözüm)', style: const TextStyle(color: AppColors.joker, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.accent, size: 14),
                      const SizedBox(width: 8),
                      Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAccent;
  const _ScoreRow({required this.label, required this.value, this.isAccent = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        Text(value, style: TextStyle(color: isAccent ? AppColors.accent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}