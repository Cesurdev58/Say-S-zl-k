import 'package:flutter/material.dart';

class MathGameBoard extends StatelessWidget {
  final int targetNumber;
  final List<String> historySteps;
  final List<int> currentNumbers;
  final int? firstNumIndex;
  final String? selectedOp;
  final bool isPaused;
  final Function(int, int) onNumberTap;
  final Function(String) onOperatorTap;

  const MathGameBoard({
    super.key,
    required this.targetNumber,
    required this.historySteps,
    required this.currentNumbers,
    required this.firstNumIndex,
    required this.selectedOp,
    required this.isPaused,
    required this.onNumberTap,
    required this.onOperatorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF5A4FCF), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Text('HEDEF SAYI', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text('$targetNumber', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity, height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: const Color(0xFF1D1B36), borderRadius: BorderRadius.circular(12)),
          child: historySteps.isEmpty
              ? Center(child: Text('İşlem adımları burada görünecek', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)))
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: historySteps.map((step) => Container(
                        margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF232042), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      )).toList(),
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
          children: List.generate(currentNumbers.length, (index) {
            int num = currentNumbers[index];
            bool isSelected = firstNumIndex == index;
            return GestureDetector(
              onTap: isPaused ? null : () => onNumberTap(index, num),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF9F43) : const Color(0xFF232042),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFFFF9F43) : Colors.white12),
                ),
                child: Center(child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['+', '-', '*', '/'].map((op) {
            bool isSelected = selectedOp == op;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: firstNumIndex == null || isPaused ? null : () => onOperatorTap(op),
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: firstNumIndex == null ? 0.4 : 1.0,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF9F43) : const Color(0xFF5A4FCF), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(op == '*' ? '×' : (op == '/' ? '÷' : op), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}