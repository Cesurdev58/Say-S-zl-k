import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/number_solver_service.dart';

/// NumberSolverService karakterizasyon testleri.
void main() {
  final solver = NumberSolverService.instance;

  test('hedef zaten listede: 0 adımlı tam çözüm', () {
    final r = solver.findBestSolution([100, 5, 3], 100);
    expect(r.isExact, isTrue);
    expect(r.steps, isEmpty);
    expect(r.difference, 0);
  });

  test('tek işlemle tam çözüm', () {
    final r = solver.findBestSolution([100, 5, 3], 105);
    expect(r.isExact, isTrue);
    expect(r.steps, ['100 + 5 = 105']);
  });

  test('en kısa tam çözümü seçer', () {
    final r = solver.findBestSolution([25, 4, 2], 100);
    expect(r.isExact, isTrue);
    expect(r.steps, ['25 × 4 = 100']);
  });

  test('çok adımlı tam çözüm', () {
    final r = solver.findBestSolution([75, 6, 4, 3, 2, 8], 487);
    expect(r.isExact, isTrue);
    expect(r.achievedNumber, 487);
    expect(r.steps, isNotEmpty);
  });

  test('tam çözüm yoksa en yakın sonucu döner', () {
    final r = solver.findBestSolution([1, 1], 10);
    expect(r.isExact, isFalse);
    expect(r.achievedNumber, 2);
    expect(r.difference, 8);
    expect(r.steps, ['1 + 1 = 2']);
  });

  test('boş liste için "Çözüm bulunamadı"', () {
    final r = solver.findBestSolution([], 10);
    expect(r.achievedNumber, 0);
    expect(r.steps, ['Çözüm bulunamadı']);
  });

  test('solveSteps: adım yoksa "Çözüm bulunamadı" döner', () {
    expect(solver.solveSteps([100, 5], 100), ['Çözüm bulunamadı']);
    expect(solver.solveSteps([100, 5], 105), ['100 + 5 = 105']);
  });

  test('havuz bulmacalarının hepsi çözülebilir', () {
    const pool = [
      (487, [75, 6, 4, 3, 2, 8]),
      (639, [100, 6, 8, 5, 2, 1]),
      (293, [25, 9, 7, 8, 6, 2]),
    ];
    for (final (target, nums) in pool) {
      expect(solver.findBestSolution(nums, target).isExact, isTrue,
          reason: '$target / $nums');
    }
  });
}
