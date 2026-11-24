import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();

  // OYUNCULARI RAM'DE HAZIR TUT (Gecikmeyi Önler)
  final AudioPlayer _clickPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _successPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _errorPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  // AYARLARI RAM'DE TUT (Diske sürekli sorma)
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isInitialized = false;

  // UYGULAMA AÇILIRKEN 1 KERE ÇALIŞACAK
  Future<void> init() async {
    if (_isInitialized) return;

    // ARKA PLANDAKİ MÜZİĞİ (Spotify, YouTube vb.) KESMEMESİ İÇİN SES ODAĞI (AUDIO CONTEXT) AYARI
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const [
          AVAudioSessionOptions.mixWithOthers,
        ],
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    await AudioPlayer.global.setAudioContext(audioContext);

    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    // Her oynatıcıya da context'i uygula ve sesleri belleğe önyükle
    await _clickPlayer.setAudioContext(audioContext);
    await _successPlayer.setAudioContext(audioContext);
    await _errorPlayer.setAudioContext(audioContext);

    await _clickPlayer.setSource(AssetSource('sounds/click.mp3'));
    await _successPlayer.setSource(AssetSource('sounds/success.mp3'));
    await _errorPlayer.setSource(AssetSource('sounds/error.mp3'));

    _isInitialized = true;
  }

  /// Titreşim ayarı (Ayarlar > Titreşim). `Haptics` bu değeri okur.
  bool get vibrationEnabled => _vibrationEnabled;

  // AYAR DEĞİŞİNCE RAM'İ GÜNCELLE
  void updateSettings(bool sound, bool vibration) {
    _soundEnabled = sound;
    _vibrationEnabled = vibration;
  }

  /// [haptic] false ise yalnızca ses çalar (titreşimi çağıran taraf `Haptics` ile verir).
  Future<void> playClick({bool haptic = true}) async {
    if (haptic && _vibrationEnabled) HapticFeedback.lightImpact();
    if (_soundEnabled) {
      try {
        if (_clickPlayer.state == PlayerState.playing) await _clickPlayer.stop();
        await _clickPlayer.resume();
      } catch (e) {}
    }
  }

  Future<void> playSuccess({bool haptic = true}) async {
    if (haptic && _vibrationEnabled) HapticFeedback.mediumImpact();
    if (_soundEnabled) {
      try {
        if (_successPlayer.state == PlayerState.playing) await _successPlayer.stop();
        await _successPlayer.resume();
      } catch (e) {}
    }
  }

  Future<void> playError({bool haptic = true}) async {
    if (haptic && _vibrationEnabled) HapticFeedback.heavyImpact();
    if (_soundEnabled) {
      try {
        if (_errorPlayer.state == PlayerState.playing) await _errorPlayer.stop();
        await _errorPlayer.resume();
      } catch (e) {}
    }
  }
}