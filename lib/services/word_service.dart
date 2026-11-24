import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum WordValidationResult {
  valid('Tebrikler! Geçerli kelime.'),
  notFound('Kelime sözlükte bulunamadı!'),
  invalidLetters('Kullanılan harfler verilen taşlarla uyuşmuyor!');

  final String message;
  const WordValidationResult(this.message);
}

// Arka plan iş parçacığında (Isolate) çalışacak üst seviye JSON ayrıştırıcı fonksiyon
Set<String> _parseDictionaryIsolate(String rawData) {
  final dynamic decoded = json.decode(rawData);
  List<dynamic> rawList = [];

  if (decoded is List) {
    rawList = decoded;
  } else if (decoded is Map && decoded.containsKey('words') && decoded['words'] is List) {
    rawList = decoded['words'];
  }

  Set<String> extractedWords = {};

  for (var item in rawList) {
    String wordStr = '';

    if (item is Map && item.containsKey('word')) {
      wordStr = item['word'].toString();
    } else if (item is Map && item.containsKey('madde')) {
      wordStr = item['madde'].toString();
    } else if (item is String) {
      wordStr = item;
    }

    wordStr = wordStr
        .trim()
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ç', 'Ç')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ö', 'Ö')
        .replaceAll('ş', 'Ş')
        .replaceAll('ü', 'Ü')
        .toUpperCase();

    if (wordStr.length >= 2 && !wordStr.contains(' ')) {
      extractedWords.add(wordStr);
    }
  }

  return extractedWords;
}

class WordService {
  WordService._privateConstructor();
  static final WordService instance = WordService._privateConstructor();

  final Random _random = Random();
  Set<String> _dictionary = {};
  final Map<int, List<String>> _wordsByLength = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  int get wordCount => _dictionary.length;
  bool get isLoaded => _isLoaded;

  String _toTrUpperCase(String text) {
    return text
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ç', 'Ç')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ö', 'Ö')
        .replaceAll('ş', 'Ş')
        .replaceAll('ü', 'Ü')
        .toUpperCase();
  }

  // Eşzamanlı çağrılarda sözlüğün iki kez yüklenmesini önleyen kilitli yapı
  Future<void> loadOfflineDictionary() {
    if (_isLoaded) return Future.value();
    return _loadFuture ??= _loadDictionaryInternal().whenComplete(() {
      _loadFuture = null;
    });
  }

  Future<void> _loadDictionaryInternal() async {
    if (_isLoaded) return;
    try {
      final String rawData = await rootBundle.loadString('assets/words_tr.json');
      final Set<String> extractedWords = await compute(_parseDictionaryIsolate, rawData);

      if (extractedWords.isNotEmpty) {
        _dictionary = extractedWords;
        _buildLengthBuckets();
        _isLoaded = true;

        if (kDebugMode) {
          print('Sözlük başarıyla yüklendi! Toplam kelime sayısı: ${_dictionary.length}');
        }
      } else {
        throw const FormatException('Geçerli kelime listesi ayıklanamadı!');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SÖZLÜK YÜKLEME HATASI: $e');
        print(stackTrace);
      }
      _dictionary = {'KELİME', 'İŞLEM', 'OYUN', 'FLUTTER', 'TÜRKÇE', 'DİŞ', 'KALEM', 'KİTAP'};
      _buildLengthBuckets();
      // Hata durumunda tekrar tekrar yükleme denemesi yapıp UI'ı yormaması için işaretlenir
      _isLoaded = true;
    }
  }

  void _buildLengthBuckets() {
    _wordsByLength.clear();
    for (final String w in _dictionary) {
      final int len = w.length;
      if (len <= 10) {
        _wordsByLength.putIfAbsent(len, () => []).add(w);
      }
    }
    // Deterministik "en iyi kelime" gösterimi için alfabetik sırala
    for (final List<String> bucket in _wordsByLength.values) {
      bucket.sort();
    }
  }

  /// Klasik yarışma formatı: 3 sesli + 4 sessiz + 1 JOKER (Toplam 8 taş)
  List<String> generateLetters() {
    final List<String> vowels = ['A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'];
    final List<String> consonants = [
      'B', 'B', 'C', 'Ç', 'D', 'D', 'F', 'G', 'Ğ', 'H',
      'K', 'K', 'L', 'L', 'M', 'M', 'N', 'N', 'P', 'R',
      'R', 'S', 'S', 'Ş', 'T', 'T', 'V', 'Y', 'Y', 'Z'
    ];

    List<String> result = [];
    vowels.shuffle(_random);
    result.addAll(vowels.take(3));

    consonants.shuffle(_random);
    result.addAll(consonants.take(4));

    result.shuffle(_random);
    result.add('JOKER');
    return result;
  }

  WordValidationResult validateWord(String word, List<String> availableLetters) {
    final String trimmed = word.trim();
    if (trimmed.length < 2) return WordValidationResult.notFound;

    String formattedWord = _toTrUpperCase(trimmed);

    if (!_dictionary.contains(formattedWord)) {
      return WordValidationResult.notFound;
    }

    List<String> tempLetters = availableLetters.map((e) => _toTrUpperCase(e)).toList();
    int jokerCount = tempLetters.where((l) => l == 'JOKER').length;
    tempLetters.removeWhere((l) => l == 'JOKER');

    for (int i = 0; i < formattedWord.length; i++) {
      String char = formattedWord[i];
      if (tempLetters.contains(char)) {
        tempLetters.remove(char);
      } else if (jokerCount > 0) {
        jokerCount--;
      } else {
        return WordValidationResult.invalidLetters;
      }
    }

    return WordValidationResult.valid;
  }

  String findLongestWord(List<String> availableLetters) =>
      _findLongestWordIn(_wordsByLength, availableLetters);

  /// [findLongestWord] ile aynı algoritma; arama ana thread'i bloklamasın diye
  /// isolate'te çalışır.
  Future<String> findLongestWordAsync(List<String> availableLetters) {
    return compute(
      _findLongestWordIsolate,
      _LongestWordRequest(_wordsByLength, List<String>.from(availableLetters)),
    );
  }
}

class _LongestWordRequest {
  const _LongestWordRequest(this.wordsByLength, this.letters);
  final Map<int, List<String>> wordsByLength;
  final List<String> letters;
}

String _findLongestWordIsolate(_LongestWordRequest request) =>
    _findLongestWordIn(request.wordsByLength, request.letters);

String _trUpper(String text) {
  return text
      .replaceAll('i', 'İ')
      .replaceAll('ı', 'I')
      .replaceAll('ç', 'Ç')
      .replaceAll('ğ', 'Ğ')
      .replaceAll('ö', 'Ö')
      .replaceAll('ş', 'Ş')
      .replaceAll('ü', 'Ü')
      .toUpperCase();
}

String _findLongestWordIn(Map<int, List<String>> wordsByLength, List<String> availableLetters) {
  int jokerCount = availableLetters.where((l) => l == 'JOKER').length;
  List<String> baseLetters = availableLetters
      .where((l) => l != 'JOKER')
      .map((e) => _trUpper(e))
      .toList();

  int maxLen = availableLetters.length;

  for (int len = maxLen; len >= 2; len--) {
    final List<String>? bucket = wordsByLength[len];
    if (bucket == null || bucket.isEmpty) continue;

    for (final String word in bucket) {
      List<String> temp = List.from(baseLetters);
      int jCount = jokerCount;
      bool possible = true;

      for (int i = 0; i < word.length; i++) {
        String char = word[i];
        if (temp.contains(char)) {
          temp.remove(char);
        } else if (jCount > 0) {
          jCount--;
        } else {
          possible = false;
          break;
        }
      }

      if (possible) {
        return word;
      }
    }
  }

  return '';
}
