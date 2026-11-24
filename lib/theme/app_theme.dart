import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'page_transitions.dart';

/// Oyuna özgü anlamsal renkler ve yüzey katmanları.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHigh,
    required this.primary,
    required this.primaryDeep,
    required this.accent,
    required this.joker,
    required this.target,
    required this.correct,
    required this.wrong,
    required this.edgeLight,
    required this.shadow,
  });

  /// Sayfa zemini (en derin katman).
  final Color background;

  /// Kart / diyalog yüzeyi.
  final Color surface;

  /// Kartın üstündeki yükseltilmiş öğeler (taş, çip).
  final Color surfaceRaised;
  final Color surfaceHigh;

  final Color primary;
  final Color primaryDeep;
  final Color accent;

  /// JOKER taşı ve seçili sayı vurgusu.
  final Color joker;

  /// Hedef sayı kartı.
  final Color target;

  final Color correct;
  final Color wrong;

  /// Yüzeylerin üst kenarındaki ince ışık çizgisi.
  final Color edgeLight;

  /// Yumuşak alt gölge rengi.
  final Color shadow;

  static const GameColors dark = GameColors(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceRaised: AppColors.surfaceHigh,
    surfaceHigh: AppColors.surfaceHigh,
    primary: AppColors.primary,
    primaryDeep: AppColors.primaryDeep,
    accent: AppColors.accent,
    joker: AppColors.joker,
    target: AppColors.primaryDeep,
    correct: AppColors.correct,
    wrong: AppColors.wrong,
    edgeLight: Color(0x1FFFFFFF), // %12 beyaz
    shadow: Color(0x66000000), // %40 siyah
  );

  @override
  GameColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceHigh,
    Color? primary,
    Color? primaryDeep,
    Color? accent,
    Color? joker,
    Color? target,
    Color? correct,
    Color? wrong,
    Color? edgeLight,
    Color? shadow,
  }) {
    return GameColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      accent: accent ?? this.accent,
      joker: joker ?? this.joker,
      target: target ?? this.target,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      edgeLight: edgeLight ?? this.edgeLight,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      primary: l(primary, other.primary),
      primaryDeep: l(primaryDeep, other.primaryDeep),
      accent: l(accent, other.accent),
      joker: l(joker, other.joker),
      target: l(target, other.target),
      correct: l(correct, other.correct),
      wrong: l(wrong, other.wrong),
      edgeLight: l(edgeLight, other.edgeLight),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension GameThemeContext on BuildContext {
  GameColors get gameColors => Theme.of(this).extension<GameColors>() ?? GameColors.dark;
}

/// Ortak köşe yarıçapları (tutarlılık için).
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

/// Tipografi yardımcıları.
abstract final class AppText {
  /// Rakamların genişliğini sabitler: süre/puan sayaçları titremez, sıçramaz.
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  /// Süre ve puan sayaçları için stil.
  static TextStyle counter({
    Color color = Colors.white,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: tabularFigures,
    );
  }
}

abstract final class AppTheme {
  static const String fontFamily = 'Nunito';

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      tertiary: AppColors.joker,
      error: AppColors.wrong,
      surface: AppColors.surface,
      onSurface: Colors.white,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: Color(0x1FFFFFFF),
    );

    // Başlık/gövde hiyerarşisi; mevcut ekranlardaki boyutlarla uyumlu.
    const textTheme = TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      // Sayaçlar: sabit genişlikli rakamlar
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFeatures: AppText.tabularFigures),
    );

    return ThemeData(
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      textTheme: textTheme,
      // Açık temadaki varsayılan SnackBar görünümü korunur (rengi verilmeyenler için).
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      // iOS'ta geri kaydırma hareketi korunur; diğer platformlarda fade + hafif kayma.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        },
      ),
      extensions: const [GameColors.dark],
    );
  }
}
