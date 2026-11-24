/// Oyun puanı ve bonus süre formülleri (saf fonksiyonlar).
///
/// Değerler yayındaki oyunla birebir aynıdır; değiştirmeyin.
class ScoreCalculator {
  const ScoreCalculator._();

  /// Solo mod kelime puanı: 7+ harfte `2*len+5`, aksi halde `len`.
  static int soloWordScore(int len) => len >= 7 ? (len * 2) + 5 : len;

  /// Solo mod süreli oyunda kelime için kazanılan bonus saniye.
  static int soloWordBonusSeconds(int len) => len >= 7 ? (len * 2) + 5 : len;

  /// Çok oyunculu kelime puanı: 7+ harfte `len+5`, aksi halde `len`.
  static int multiWordScore(int len) => len >= 7 ? len + 5 : len;

  /// Solo ve çok oyunculu işlem puanı.
  static int mathScore(int minDiff, int numberCount) =>
      (10 - minDiff) + (numberCount * 2);

  /// Solo süreli işlem bonus saniyesi: yalnızca tam isabette.
  static int soloMathBonusSeconds(int minDiff, int numberCount) =>
      minDiff == 0 ? 5 + (numberCount * 2) : 0;
}
