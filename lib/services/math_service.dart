import 'dart:math';

/// Solo ve Çok Oyunculu modlar için birleştirilmiş, %100 çözülebilir soru garantili işlem servisi.
class MathService {
  MathService({Random? random}) : _random = random ?? Random();

  static final MathService instance = MathService();

  /// Tek basamaklı küçük sayılar (1–9).
  static const List<int> smallNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// Standart büyük sayı kümesi (Solo ve Multiplayer eşitlendi).
  static const List<int> largeNumbers = [25, 50, 75, 100];

  static const int smallNumberCount = 5;
  static const int largeNumberCount = 1;
  static const int totalNumberCount = 6;

  static const List<Map<String, dynamic>> _verifiedMathPool = [
    {'target': 487, 'numbers': [75, 6, 4, 3, 2, 8]},
    {'target': 639, 'numbers': [100, 6, 8, 5, 2, 1]},
    {'target': 367, 'numbers': [50, 7, 4, 5, 3, 1]},
    {'target': 543, 'numbers': [75, 7, 6, 4, 2, 1]},
    {'target': 823, 'numbers': [100, 8, 6, 4, 3, 1]},
    {'target': 293, 'numbers': [25, 9, 7, 8, 6, 2]},
    {'target': 419, 'numbers': [50, 8, 7, 3, 2, 1]},
    {'target': 713, 'numbers': [75, 9, 8, 5, 2, 1]},
    {'target': 589, 'numbers': [100, 5, 9, 8, 7, 2]},
    {'target': 341, 'numbers': [50, 6, 9, 5, 4, 1]},
    {'target': 667, 'numbers': [75, 8, 9, 7, 4, 2]},
    {'target': 247, 'numbers': [25, 8, 9, 5, 3, 2]},
    {'target': 917, 'numbers': [100, 9, 6, 4, 3, 1]},
    {'target': 463, 'numbers': [50, 9, 4, 5, 7, 2]},
    {'target': 529, 'numbers': [75, 7, 3, 4, 2, 1]},
  ];

  final Random _random;

  /// Verilen sayılardan gerçek 3-4 işlemle türetilmiş, kısayol korumalı bulmaca üretir.
  MathPuzzle generatePuzzle({Set<String>? usedSignatures}) {
    for (int attempts = 0; attempts < 600; attempts++) {
      int bigNum = largeNumbers[_random.nextInt(largeNumbers.length)];
      List<int> smalls = List.generate(
        smallNumberCount,
        (_) => smallNumbers[_random.nextInt(smallNumbers.length)],
      );

      var counts = <int, int>{};
      for (var n in smalls) {
        counts[n] = (counts[n] ?? 0) + 1;
      }
      if (counts.values.any((count) => count >= 3)) continue;

      List<int> initialNumbers = [bigNum, ...smalls];
      List<int> currentPool = List<int>.from(initialNumbers);
      int requiredSteps = _random.nextInt(2) + 3; // Gerçek 3 veya 4 adım
      int successfulSteps = 0;
      int stepAttempts = 0;

      while (successfulSteps < requiredSteps && stepAttempts < 20 && currentPool.length >= 2) {
        stepAttempts++;
        int idx1 = _random.nextInt(currentPool.length);
        int val1 = currentPool.removeAt(idx1);
        int idx2 = _random.nextInt(currentPool.length);
        int val2 = currentPool.removeAt(idx2);

        int a = val1 >= val2 ? val1 : val2;
        int b = val1 >= val2 ? val2 : val1;

        int op = _random.nextInt(4);
        int? result;

        if (op == 0) {
          result = a + b;
        } else if (op == 1) {
          if (a - b > 0) result = a - b;
        } else if (op == 2) {
          if (a * b <= 3000) result = a * b;
        } else if (op == 3) {
          if (b != 0 && a % b == 0) result = a ~/ b;
        }

        if (result == null) {
          currentPool.addAll([a, b]);
          continue;
        }

        currentPool.add(result);
        successfulSteps++;
      }

      if (successfulSteps < requiredSteps) continue;

      currentPool.sort();
      int newTarget = currentPool.last;

      if (newTarget >= 180 && newTarget <= 999) {
        if (newTarget % 10 != 0 && newTarget % 25 != 0 && newTarget % 50 != 0) {
          bool isTooEasy = false;

          // 1 hamlelik kısayol kontrolü
          for (int s in smalls) {
            if ((newTarget - (bigNum * s)).abs() <= 12) {
              isTooEasy = true;
              break;
            }
          }

          // 2 hamlelik kısayol kontrolü
          if (!isTooEasy) {
            for (int i = 0; i < smalls.length; i++) {
              for (int j = i + 1; j < smalls.length; j++) {
                int s1 = smalls[i];
                int s2 = smalls[j];

                if ((newTarget - (bigNum * (s1 + s2))).abs() <= 12 ||
                    (newTarget - (bigNum * (s1 * s2))).abs() <= 12 ||
                    (newTarget - ((bigNum * s1) + s2)).abs() <= 12 ||
                    (newTarget - ((bigNum * s1) - s2)).abs() <= 12) {
                  isTooEasy = true;
                  break;
                }
              }
              if (isTooEasy) break;
            }
          }

          if (!isTooEasy) {
            String sig = '${newTarget}_${(List<int>.from(initialNumbers)..sort()).join(',')}';
            if (usedSignatures == null || !usedSignatures.contains(sig)) {
              usedSignatures?.add(sig);
              initialNumbers.shuffle(_random);
              return MathPuzzle(target: newTarget, numbers: initialNumbers);
            }
          }
        }
      }
    }

    // 600 denemede çıkmadıysa doğrulanmış %100 çözülebilir havuzdan seç
    if (usedSignatures != null) {
      for (final item in _verifiedMathPool) {
        final int target = item['target'] as int;
        final List<int> nums = List<int>.from(item['numbers'] as List);
        final String sig = '${target}_${(List<int>.from(nums)..sort()).join(',')}';
        if (!usedSignatures.contains(sig)) {
          usedSignatures.add(sig);
          nums.shuffle(_random);
          return MathPuzzle(target: target, numbers: nums);
        }
      }
    }

    final fallback = _verifiedMathPool[_random.nextInt(_verifiedMathPool.length)];
    final List<int> fallbackNums = List<int>.from(fallback['numbers'] as List)..shuffle(_random);
    return MathPuzzle(target: fallback['target'] as int, numbers: fallbackNums);
  }

  /// Havuzdaki sayılardan hedefe en yakın mesafeyi döndürür.
  int closestDistance(List<int> numbers, int target) {
    if (numbers.isEmpty) return 0;
    return numbers.map((n) => (n - target).abs()).reduce(min);
  }

  /// Hedef sayıya ulaşılıp ulaşılmadığını kontrol eder.
  bool hasReachedTarget(List<int> numbers, int target) => numbers.contains(target);

  /// İki sayı ve işlemle sonucu hesaplar. Negatif/sıfır çıkarma veya kalanlı bölmede null döner.
  int? applyOperation(int a, int b, MathOperation operation) {
    switch (operation) {
      case MathOperation.add:
        return a + b;
      case MathOperation.subtract:
        if (a - b <= 0) return null;
        return a - b;
      case MathOperation.multiply:
        return a * b;
      case MathOperation.divide:
        if (b <= 0 || a % b != 0) return null;
        return a ~/ b;
    }
  }
}

class MathPuzzle {
  const MathPuzzle({required this.target, required this.numbers});

  final int target;
  final List<int> numbers;
}

enum MathOperation {
  add,
  subtract,
  multiply,
  divide;

  String get symbol {
    switch (this) {
      case MathOperation.add:
        return '+';
      case MathOperation.subtract:
        return '-';
      case MathOperation.multiply:
        return '×';
      case MathOperation.divide:
        return '÷';
    }
  }
}