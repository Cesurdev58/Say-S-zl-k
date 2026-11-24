import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/math_service.dart';
import 'package:kelime_islem_game/services/word_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordService', () {
    late WordService service;

    setUp(() async {
      service = WordService(random: Random(42));
      await service.init();
    });

    test('toTurkishUpper handles I/İ correctly', () {
      expect(WordService.toTurkishUpper('istanbul'), 'İSTANBUL');
      expect(WordService.toTurkishUpper('ırmak'), 'IRMAK');
      expect(WordService.toTurkishUpper('şişe'), 'ŞİŞE');
    });

    test('toTurkishLower handles I/İ correctly', () {
      expect(WordService.toTurkishLower('İSTANBUL'), 'istanbul');
      expect(WordService.toTurkishLower('IRMAK'), 'ırmak');
      expect(WordService.toTurkishLower('ŞİŞE'), 'şişe');
    });

    test('isValidWord performs O(1) dictionary lookup', () {
      expect(service.isValidWord('KELİME'), isTrue);
      expect(service.isValidWord('kelime'), isTrue);
      expect(service.isValidWord('XYZZY'), isFalse);
      expect(service.isValidWord('AB'), isFalse);
    });

    test('generateLetters follows official composition rules', () {
      for (var i = 0; i < 50; i++) {
        final letters = service.generateLetters();
        expect(letters.length, WordService.officialLetterCount);
        expect(
          WordService.countVowels(letters),
          greaterThanOrEqualTo(WordService.vowelCount),
        );
        expect(
          letters.length - WordService.countVowels(letters),
          greaterThanOrEqualTo(WordService.consonantCount),
        );
        expect(
          WordService.maxLetterRepeat(letters),
          lessThanOrEqualTo(WordService.maxSameLetterCount),
        );
      }
    });

    test('validateWord accepts word formable from letters', () {
      final letters = ['K', 'E', 'L', 'İ', 'M', 'E', 'A', 'R'];
      final result = service.validateWord('KELİME', letters);
      expect(result, WordValidationResult.valid);
    });

    test('validateWord rejects too short words', () {
      final result =
          service.validateWord('AB', ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']);
      expect(result, WordValidationResult.tooShort);
    });
  });

  group('MathService', () {
    final service = MathService(random: Random(7));

    test('generatePuzzle follows official number rules', () {
      for (var i = 0; i < 30; i++) {
        final puzzle = service.generatePuzzle();
        expect(puzzle.target, inInclusiveRange(100, 999));
        expect(puzzle.numbers.length, MathService.totalNumberCount);

        final small = puzzle.numbers
            .where((n) => MathService.smallNumbers.contains(n))
            .length;
        final large = puzzle.numbers
            .where((n) => MathService.largeNumbers.contains(n))
            .length;

        expect(small, MathService.smallNumberCount);
        expect(large, MathService.largeNumberCount);
      }
    });

    test('closestDistance returns minimum absolute difference', () {
      expect(service.closestDistance([10, 25, 100], 237), 137);
      expect(service.hasReachedTarget([237, 50], 237), isTrue);
    });

    test('divide requires exact division', () {
      expect(service.applyOperation(10, 3, MathOperation.divide), isNull);
      expect(service.applyOperation(10, 5, MathOperation.divide), 2);
    });
  });
}
