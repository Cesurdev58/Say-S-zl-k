import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/word_service.dart';

/// WordService karakterizasyon testleri: mevcut davranışı kilitler.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = WordService.instance;

  setUpAll(() async {
    await service.loadOfflineDictionary();
  });

  group('WordService sözlük yükleme', () {
    test('assets/words_tr.json yüklenir (yedek sözlüğe düşmez)', () {
      expect(service.isLoaded, isTrue);
      expect(service.wordCount, greaterThan(1000));
    });

    test('ikinci yükleme çağrısı güvenlidir', () async {
      final before = service.wordCount;
      await service.loadOfflineDictionary();
      expect(service.wordCount, before);
    });
  });

  group('WordService.generateLetters', () {
    test('8 taş: 3 sesli + 4 sessiz + JOKER', () {
      const vowels = {'A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'};
      for (var i = 0; i < 100; i++) {
        final letters = service.generateLetters();
        expect(letters.length, 8);
        expect(letters.where((l) => l == 'JOKER').length, 1);
        expect(letters.last, 'JOKER');
        final rest = letters.where((l) => l != 'JOKER').toList();
        expect(rest.where(vowels.contains).length, 3);
        expect(rest.where((l) => !vowels.contains(l)).length, 4);
      }
    });

    test('sesli harfler tekrar etmez, sessizler en fazla 2 kez gelir', () {
      const vowels = {'A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'};
      for (var i = 0; i < 100; i++) {
        final letters = service.generateLetters();
        final counts = <String, int>{};
        for (final l in letters.where((l) => l != 'JOKER')) {
          counts[l] = (counts[l] ?? 0) + 1;
        }
        for (final e in counts.entries) {
          expect(e.value, vowels.contains(e.key) ? 1 : lessThanOrEqualTo(2));
        }
      }
    });
  });

  group('WordService.validateWord', () {
    test('sözlükte olan ve harflerle kurulabilen kelime geçerlidir', () {
      final r = service.validateWord(
          'kalem', ['K', 'A', 'L', 'E', 'M', 'T', 'R', 'JOKER']);
      expect(r, WordValidationResult.valid);
    });

    test('büyük/küçük harf ve İ/ı dönüşümü yapılır', () {
      const letters = ['K', 'İ', 'T', 'A', 'P', 'R', 'S', 'JOKER'];
      expect(service.validateWord('kitap', letters), WordValidationResult.valid);
      expect(service.validateWord('KİTAP', letters), WordValidationResult.valid);
    });

    test('baştaki/sondaki boşluk kırpılır', () {
      expect(service.validateWord('  kalem ', ['K', 'A', 'L', 'E', 'M', 'T', 'R', 'S']),
          WordValidationResult.valid);
    });

    test('çok kısa girdi notFound döner', () {
      expect(service.validateWord('a', ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']),
          WordValidationResult.notFound);
      expect(service.validateWord('', ['A']), WordValidationResult.notFound);
    });

    test('sözlükte olmayan kelime notFound döner', () {
      expect(
          service.validateWord('xqzvw', ['X', 'Q', 'Z', 'V', 'W', 'A', 'B', 'C']),
          WordValidationResult.notFound);
    });

    test('sözlükte var ama harfler yetmiyorsa invalidLetters döner', () {
      expect(service.validateWord('kalem', ['K', 'A', 'L', 'B', 'C', 'D', 'F', 'G']),
          WordValidationResult.invalidLetters);
    });

    test('aynı harf taşı iki kez kullanılamaz', () {
      expect(service.validateWord('kalem', ['K', 'A', 'L', 'E', 'E', 'B', 'C', 'D']),
          WordValidationResult.invalidLetters);
    });

    test('JOKER herhangi bir harfin yerine geçer ama yalnızca bir kez', () {
      expect(service.validateWord('kalem', ['K', 'A', 'L', 'E', 'JOKER', 'B', 'C', 'D']),
          WordValidationResult.valid);
      expect(service.validateWord('kalem', ['K', 'A', 'L', 'JOKER', 'B', 'C', 'D', 'F']),
          WordValidationResult.invalidLetters);
    });
  });

  group('WordService.findLongestWord', () {
    test('en uzun kelimeyi bulur ve sonuç geçerlidir', () {
      final letters = ['K', 'A', 'L', 'E', 'M', 'T', 'R', 'JOKER'];
      final best = service.findLongestWord(letters);
      expect(best, isNotEmpty);
      expect(service.validateWord(best, letters), WordValidationResult.valid);
      expect(best.length, greaterThanOrEqualTo(5));
    });

    test('sonuç deterministiktir', () {
      final letters = ['K', 'A', 'L', 'E', 'M', 'T', 'R', 'JOKER'];
      expect(service.findLongestWord(letters), service.findLongestWord(letters));
    });

    test('çözüm yoksa boş string döner', () {
      expect(service.findLongestWord(['X']), '');
    });

    test('findLongestWordAsync (isolate) senkron sonuçla birebir aynıdır', () async {
      final letters = ['K', 'A', 'L', 'E', 'M', 'T', 'R', 'JOKER'];
      expect(await service.findLongestWordAsync(letters), service.findLongestWord(letters));
      expect(await service.findLongestWordAsync(['X']), '');
    });
  });

  group('WordValidationResult', () {
    test('mesajlar (UI metinleri) sabit kalır', () {
      expect(WordValidationResult.valid.message, 'Tebrikler! Geçerli kelime.');
      expect(WordValidationResult.notFound.message, 'Kelime sözlükte bulunamadı!');
      expect(WordValidationResult.invalidLetters.message,
          'Kullanılan harfler verilen taşlarla uyuşmuyor!');
    });
  });
}
