import 'package:flutter_test/flutter_test.dart';

/// PUAN FORMÜLLERİ — karakterizasyon.
///
/// Formüller şu an widget State'lerinin içinde satır içi yazılı olduğu için
/// (lib/screens/game_screen.dart ~308, ~440; lib/screens/multiplayer_game_screen.dart
/// ~796, ~824) doğrudan çağrılamaz. Faz 0'da lib/ dosyalarına dokunulmadığından
/// buradaki yerel fonksiyonlar, kaynak koddaki ifadelerin BİREBİR kopyasıdır.
/// Faz 1'de formüller saf fonksiyona çıkarıldığında bu kopyalar silinip testler
/// gerçek fonksiyonlara bağlanmalıdır.

// game_screen.dart: int earned = len >= 7 ? (len * 2) + 5 : len;
int soloWordScore(int len) => len >= 7 ? (len * 2) + 5 : len;
// game_screen.dart: bonusSeconds (süreli modda)
int soloWordBonusSeconds(int len) => len >= 7 ? (len * 2) + 5 : len;
// game_screen.dart: int earned = (10 - minDiff) + (remainingNumberCount * 2);
int soloMathScore(int minDiff, int numberCount) =>
    (10 - minDiff) + (numberCount * 2);
// game_screen.dart: minDiff == 0 ise 5 + remaining*2, aksi 0
int soloMathBonusSeconds(int minDiff, int numberCount) =>
    minDiff == 0 ? 5 + (numberCount * 2) : 0;
// multiplayer_game_screen.dart: int earned = word.length >= 7 ? word.length + 5 : word.length;
int multiWordScore(int len) => len >= 7 ? len + 5 : len;
// multiplayer_game_screen.dart: int earned = (10 - minDiff) + (currentNumbers.length * 2);
int multiMathScore(int minDiff, int numberCount) =>
    (10 - minDiff) + (numberCount * 2);

void main() {
  group('Solo kelime puanı', () {
    test('7 harften kısa: harf sayısı kadar', () {
      expect([2, 3, 4, 5, 6].map(soloWordScore), [2, 3, 4, 5, 6]);
    });
    test('7+ harf: 2*uzunluk + 5', () {
      expect(soloWordScore(7), 19);
      expect(soloWordScore(8), 21);
      expect(soloWordScore(9), 23);
    });
    test('bonus süre puanla aynı formül', () {
      for (var l = 2; l <= 9; l++) {
        expect(soloWordBonusSeconds(l), soloWordScore(l));
      }
    });
  });

  group('Solo işlem puanı', () {
    test('tam isabet 6 sayı ile 22 puan, +17 sn', () {
      expect(soloMathScore(0, 6), 22);
      expect(soloMathBonusSeconds(0, 6), 17);
    });
    test('fark arttıkça puan düşer', () {
      expect(soloMathScore(5, 1), 7);
      expect(soloMathScore(10, 1), 2);
    });
    test('yaklaşımda bonus süre yok', () {
      expect(soloMathBonusSeconds(1, 6), 0);
      expect(soloMathBonusSeconds(10, 6), 0);
    });
  });

  group('Çok oyunculu puan', () {
    test('kelime: 7+ harfte uzunluk + 5 (solo ile FARKLI: 2x yok)', () {
      expect(multiWordScore(6), 6);
      expect(multiWordScore(7), 12);
      expect(multiWordScore(8), 13);
      expect(multiWordScore(7), isNot(soloWordScore(7)));
    });
    test('işlem: solo ile aynı formül', () {
      expect(multiMathScore(0, 6), 22);
      expect(multiMathScore(10, 2), 4);
      for (var d = 0; d <= 10; d++) {
        expect(multiMathScore(d, 4), soloMathScore(d, 4));
      }
    });
  });
}
