import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui/animated_slot.dart';
import 'ui/count_up_text.dart';
import 'ui/error_shake.dart';
import 'ui/game_tile.dart';
import 'ui/motion.dart';
import 'ui/recessed_slot.dart';

class MathGameBoard extends StatelessWidget {
  final int targetNumber;
  final List<String> historySteps;
  final List<int> currentNumbers;
  final int? firstNumIndex;
  final String? selectedOp;
  final bool isPaused;
  final Function(int, int) onNumberTap;
  final Function(String) onOperatorTap;

  /// Her artışında işlem adımları alanı sallanır ve kısa süre kırmızı kenarlık gösterir.
  final ValueNotifier<int>? errorSignal;

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
    this.errorSignal,
  });

  @override
  Widget build(BuildContext context) {
    // 6 sayıyla en fazla 5 işlem adımı yapılabilir.
    final int stepSlots = historySteps.length > 5 ? historySteps.length : 5;

    Widget history = RecessedSlot(
      height: 44,
      radius: 12,
      dashed: false,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: Motion.of(context, const Duration(milliseconds: 150)),
            opacity: historySteps.isEmpty ? 1 : 0,
            child: Text('İşlem adımları burada görünecek', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
          ),
          ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(stepSlots, (i) {
              final bool filled = i < historySteps.length;
              final String step = filled ? historySteps[i] : '';
              return AnimatedSlot(
                child: filled
                    ? Container(
                        key: ValueKey('step-$i-$step'),
                        margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      )
                    : null,
              );
            }),
          ),
        ],
      ),
    );
    if (errorSignal != null) {
      history = ErrorShake(trigger: errorSignal!, borderRadius: 12, child: history);
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GameTile(
            color: context.gameColors.target,
            radius: AppRadius.lg,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text('HEDEF SAYI', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  // Yeni tur: hedef sayı 0'dan hedefe sayarak belirir.
                  CountUpText(
                    key: ValueKey('target-$targetNumber'),
                    value: targetNumber,
                    fromZero: true,
                    style: AppText.counter(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        history,
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: Motion.of(context, const Duration(milliseconds: 200)),
          transitionBuilder: AnimatedSlot.transition,
          child: Wrap(
            key: ValueKey('numbers-${currentNumbers.join(',')}'),
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(currentNumbers.length, (index) {
              int num = currentNumbers[index];
              bool isSelected = firstNumIndex == index;
              return GameTile(
                width: 52,
                height: 52,
                color: isSelected ? context.gameColors.joker : context.gameColors.surfaceRaised,
                borderColor: isSelected ? context.gameColors.joker : Colors.white12,
                onTap: isPaused ? null : () => onNumberTap(index, num),
                child: Text('$num', style: AppText.counter(fontSize: 18)),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['+', '-', '*', '/'].map((op) {
            bool isSelected = selectedOp == op;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: firstNumIndex == null ? 0.4 : 1.0,
                child: GameTile(
                  width: 46,
                  height: 46,
                  radius: AppRadius.md - 2,
                  color: isSelected ? context.gameColors.joker : context.gameColors.primaryDeep,
                  onTap: firstNumIndex == null || isPaused ? null : () => onOperatorTap(op),
                  child: Text(op == '*' ? '×' : (op == '/' ? '÷' : op), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
