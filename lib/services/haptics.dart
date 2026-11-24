import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_service.dart';

/// Olaya özel dokunsal geri bildirim. Ayarlardaki titreşim anahtarına uyar;
/// ses ([AudioService]) ile bağımsız çağrılabilir.
abstract final class Haptics {
  /// Titreşimin açık olup olmadığını okur. Testlerde değiştirilebilir.
  @visibleForTesting
  static bool Function() enabledReader = () => AudioService.instance.vibrationEnabled;

  static bool get _enabled => enabledReader();

  /// Harf/sayı/işlem seçimi ve silme.
  static void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Geçerli kelime veya hedefe yaklaşma; tam isabette ([exact]) daha güçlü.
  static void success({bool exact = false}) {
    if (!_enabled) return;
    exact ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
  }

  /// Yanlış / geçersiz hamle.
  static void error() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  /// Son saniyelerde her saniye hafif vuruş.
  static void tick() {
    if (_enabled) HapticFeedback.lightImpact();
  }
}
