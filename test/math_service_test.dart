import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/math_service.dart';

/// MathService karakterizasyon testleri.
void main() {
  group('MathService sabitleri', () {
    test('sayı kümeleri ve adetler', () {
      expect(MathService.smallNumbers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(MathService.largeNumbers, [25, 50, 75, 100]);
      expect(MathService.smallNumberCount, 5);
      expect(MathService.largeNumberCount, 1);
      expect(MathService.totalNumberCount, 6);
    });
  });

  group('MathService.generatePuzzle', () {
    test('6 sayı: 1 büyük + 5 küçük, hedef 100–999 aralığında', () {
      final service = MathService(random: Random(7));
      for (var i = 0; i < 100; i++) {
        final p = service.generatePuzzle();
        expect(p.numbers.length, 6);
        expect(p.target, inInclusiveRange(180, 999));
        expect(p.numbers.where(MathService.largeNumbers.contains).length, 1);
        expect(p.numbers.where(MathService.smallNumbers.contains).length, 5);
      }
    });

    test('aynı küçük sayı en fazla 2 kez gelir', () {
      final service = MathService(random: Random(11));
      for (var i = 0; i < 100; i++) {
        final p = service.generatePuzzle();
        final counts = <int, int>{};
        for (final n in p.numbers.where(MathService.smallNumbers.contains)) {
          counts[n] = (counts[n] ?? 0) + 1;
        }
        expect(counts.values.every((c) => c <= 2), isTrue);
      }
    });

    test('aynı seed aynı bulmacayı üretir (deterministik)', () {
      final a = MathService(random: Random(3)).generatePuzzle();
      final b = MathService(random: Random(3)).generatePuzzle();
      expect(a.target, b.target);
      expect(a.numbers, b.numbers);
    });

    test('usedSignatures tekrarı engeller ve imza kaydeder', () {
      final service = MathService(random: Random(5));
      final used = <String>{};
      final sigs = <String>{};
      for (var i = 0; i < 30; i++) {
        final p = service.generatePuzzle(usedSignatures: used);
        final sig = '${p.target}_${(List<int>.from(p.numbers)..sort()).join(',')}';
        expect(sigs.add(sig), isTrue, reason: 'tekrar eden bulmaca: $sig');
      }
      expect(used.length, 30);
    });
  });

  group('MathService.applyOperation', () {
    final s = MathService(random: Random(1));

    test('toplama ve çarpma', () {
      expect(s.applyOperation(3, 4, MathOperation.add), 7);
      expect(s.applyOperation(3, 4, MathOperation.multiply), 12);
    });

    test('çıkarma yalnızca pozitif sonuç verir', () {
      expect(s.applyOperation(10, 3, MathOperation.subtract), 7);
      expect(s.applyOperation(5, 5, MathOperation.subtract), isNull);
      expect(s.applyOperation(3, 5, MathOperation.subtract), isNull);
    });

    test('bölme yalnızca tam bölünmede ve pozitif bölenle çalışır', () {
      expect(s.applyOperation(10, 5, MathOperation.divide), 2);
      expect(s.applyOperation(10, 3, MathOperation.divide), isNull);
      expect(s.applyOperation(10, 0, MathOperation.divide), isNull);
    });
  });

  group('MathService yardımcıları', () {
    final s = MathService(random: Random(1));

    test('closestDistance', () {
      expect(s.closestDistance([10, 25, 100], 237), 137);
      expect(s.closestDistance([], 237), 0);
      expect(s.closestDistance([237, 5], 237), 0);
    });

    test('hasReachedTarget', () {
      expect(s.hasReachedTarget([237, 50], 237), isTrue);
      expect(s.hasReachedTarget([236, 50], 237), isFalse);
    });

    test('MathOperation sembolleri', () {
      expect(MathOperation.add.symbol, '+');
      expect(MathOperation.subtract.symbol, '-');
      expect(MathOperation.multiply.symbol, '×');
      expect(MathOperation.divide.symbol, '÷');
    });
  });
}
