class SolutionResult {
  final int target;
  final int achievedNumber;
  final List<String> steps;

  SolutionResult({
    required this.target,
    required this.achievedNumber,
    required this.steps,
  });

  bool get isExact => target == achievedNumber;
  int get difference => (target - achievedNumber).abs();
}

class NumberSolverService {
  NumberSolverService._privateConstructor();
  static final NumberSolverService instance = NumberSolverService._privateConstructor();

  /// Verilen sayılar ve hedef ile en yakın ve en kısa adımlı çözümü bulur
  SolutionResult findBestSolution(List<int> numbers, int target) {
    SolutionResult? bestResult;

    void solve(List<int> currentNumbers, List<String> currentSteps) {
      // Tam çözüm zaten bulunduysa ve mevcut adım sayısı daha kısa değilse dallanmayı kes
      if (bestResult != null &&
          bestResult!.isExact &&
          currentSteps.length >= bestResult!.steps.length) {
        return;
      }

      for (int i = 0; i < currentNumbers.length; i++) {
        int num = currentNumbers[i];
        int diff = (target - num).abs();

        if (bestResult == null ||
            diff < bestResult!.difference ||
            (diff == bestResult!.difference && currentSteps.length < bestResult!.steps.length)) {
          bestResult = SolutionResult(
            target: target,
            achievedNumber: num,
            steps: List<String>.from(currentSteps),
          );
        }

        if (diff == 0) return;
      }

      if (currentNumbers.length <= 1) return;

      for (int i = 0; i < currentNumbers.length; i++) {
        for (int j = i + 1; j < currentNumbers.length; j++) {
          int a = currentNumbers[i];
          int b = currentNumbers[j];

          // Büyük sayıyı her zaman 'big' olarak al (simetrik tekrarları önler)
          int big = a >= b ? a : b;
          int small = a >= b ? b : a;

          List<int> nextNumbers = [];
          for (int k = 0; k < currentNumbers.length; k++) {
            if (k != i && k != j) nextNumbers.add(currentNumbers[k]);
          }

          // 1. Toplama
          final int sum = big + small;
          solve([...nextNumbers, sum], [...currentSteps, '$big + $small = $sum']);

          // 2. Çıkarma (Yalnızca pozitif tam sayı sonuçlar; 8 - 4 = 4 dahil tüm geçerli çıkarmalar)
          if (big - small > 0) {
            final int diffVal = big - small;
            solve([...nextNumbers, diffVal], [...currentSteps, '$big - $small = $diffVal']);
          }

          // 3. Çarpma (1 ile çarpmak sayıyı değiştirmediği için en kısa çözümde atlanır)
          if (big > 1 && small > 1) {
            final int prod = big * small;
            solve([...nextNumbers, prod], [...currentSteps, '$big × $small = $prod']);
          }

          // 4. Bölme (Kalansız bölünenler ve 1'den büyük bölenler)
          if (small > 1 && big % small == 0) {
            final int quot = big ~/ small;
            solve([...nextNumbers, quot], [...currentSteps, '$big ÷ $small = $quot']);
          }
        }
      }
    }

    solve(numbers, []);
    return bestResult ??
        SolutionResult(target: target, achievedNumber: 0, steps: const ['Çözüm bulunamadı']);
  }

  /// Doğrudan adım listesini döndüren yardımcı metot
  List<String> solveSteps(List<int> numbers, int target) {
    final res = findBestSolution(numbers, target);
    return res.steps.isEmpty ? ['Çözüm bulunamadı'] : res.steps;
  }
}