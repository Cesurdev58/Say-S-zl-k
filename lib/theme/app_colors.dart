import 'package:flutter/material.dart';

/// Ham renk paleti (const). Mevcut koyu mor oyun kimliğiyle birebir aynıdır.
///
/// `const` bağlamlarda kullanılabilir. Bağlama göre okunacak anlamsal renkler
/// için `GameColors` ThemeExtension'ını (`context.gameColors`) tercih edin.
abstract final class AppColors {
  // Yüzey katmanları (en derinden en yükseğe)
  static const Color background = Color(0xFF131127);
  static const Color surface = Color(0xFF1D1B36);
  static const Color surfaceHigh = Color(0xFF232042);
  static const Color surfaceGradientTop = Color(0xFF2D2A59);
  static const Color surfaceGradientBottom = Color(0xFF1A1836);

  // Marka / vurgu
  static const Color primary = Color(0xFF7C5CFC);
  static const Color primaryDeep = Color(0xFF5A4FCF);
  static const Color primaryAlt = Color(0xFF6C5CE7);
  static const Color primaryBright = Color(0xFF8C7CFF);
  static const Color violet = Color(0xFF5B3FD9);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color lavender = Color(0xFFA78BFA);

  // Anlamsal renkler
  static const Color accent = Color(0xFF00CEC9); // turkuaz: ikincil vurgu
  static const Color joker = Color(0xFFFF9F43);
  static const Color rose = Color(0xFFFD79A8); // sayısal mod / ceza vurgusu
  static const Color sky = Color(0xFF74B9FF);
  static const Color mint = Color(0xFF55EFC4);
  static const Color correct = Color(0xFF34D399);
  static const Color wrong = Color(0xFFF87171);

  // Atmosferik arka plan: derin gece lacivertinden koyu mora
  static const Color atmosphereTop = Color(0xFF070B22);
  static const Color atmosphereMid = Color(0xFF141044);
  static const Color atmosphereBottom = Color(0xFF2B1760);

  // Eski oyun arka plan gradyanı
  static const Color gradientTop = Color(0xFF0F172A);
  static const Color gradientMid = Color(0xFF1E1B4B);
  static const Color gradientBottom = Color(0xFF312E81);
}
