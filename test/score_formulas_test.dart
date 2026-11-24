import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/score_calculator.dart';

/// Puan formülleri karakterizasyon testleri (gerçek ScoreCalculator'a bağlı).

void main() {
  group('Solo kelime puanı', () {
    test('7 harften kısa: harf sayısı kadar', () {
      expect([2, 3, 4, 5, 6].map(ScoreCalculator.soloWordScore), [2, 3, 4, 5, 6]);
    });
    test('7+ harf: 2*uzunluk + 5', () {
      expect(ScoreCalculator.soloWordScore(7), 19);
      expect(ScoreCalculator.soloWordScore(8), 21);
      expect(ScoreCalculator.soloWordScore(9), 23);
    });
    test('bonus süre puanla aynı formül', () {
      for (var l = 2; l <= 9; l++) {
        expect(ScoreCalculator.soloWordBonusSeconds(l), ScoreCalculator.soloWordScore(l));
      }
    });
  });

  group('Solo işlem puanı', () {
    test('tam isabet 6 sayı ile 22 puan, +17 sn', () {
      expect(ScoreCalculator.mathScore(0, 6), 22);
      expect(ScoreCalculator.soloMathBonusSeconds(0, 6), 17);
    });
    test('fark arttıkça puan düşer', () {
      expect(ScoreCalculator.mathScore(5, 1), 7);
      expect(ScoreCalculator.mathScore(10, 1), 2);
    });
    test('yaklaşımda bonus süre yok', () {
      expect(ScoreCalculator.soloMathBonusSeconds(1, 6), 0);
      expect(ScoreCalculator.soloMathBonusSeconds(10, 6), 0);
    });
  });

  group('Çok oyunculu puan', () {
    test('kelime: 7+ harfte uzunluk + 5 (solo ile FARKLI: 2x yok)', () {
      expect(ScoreCalculator.multiWordScore(6), 6);
      expect(ScoreCalculator.multiWordScore(7), 12);
      expect(ScoreCalculator.multiWordScore(8), 13);
      expect(ScoreCalculator.multiWordScore(7), isNot(ScoreCalculator.soloWordScore(7)));
    });
    test('işlem: solo ile aynı formül', () {
      expect(ScoreCalculator.mathScore(0, 6), 22);
      expect(ScoreCalculator.mathScore(10, 2), 4);
      for (var d = 0; d <= 10; d++) {
        expect(ScoreCalculator.mathScore(d, 4), ScoreCalculator.mathScore(d, 4));
      }
    });
  });
}
