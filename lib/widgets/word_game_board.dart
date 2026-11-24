import 'package:flutter/material.dart';

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
        Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF5A4FCF).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: selectedLetters.isEmpty
                ? [Text('Harflere Dokunarak Kelime Oluştur', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12))]
                : selectedLetters.map((char) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 36, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A4FCF), 
                        borderRadius: BorderRadius.circular(10), 
                        border: Border.all(color: const Color(0xFF8C7CFF))
                      ),
                      child: Center(child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    )).toList(),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isUsed ? const Color(0xFF1D1B36).withValues(alpha: 0.4) : (char == 'JOKER' ? const Color(0xFFFF9F43) : const Color(0xFF5A4FCF)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(char, style: TextStyle(color: isUsed ? Colors.white24 : Colors.white, fontSize: char == 'JOKER' ? 11 : 20, fontWeight: FontWeight.bold))),
              ),
            );
          },
        ),
      ],
    );
  }
}