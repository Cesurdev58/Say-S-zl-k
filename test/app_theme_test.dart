import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_colors.dart';
import 'package:kelime_islem_game/theme/app_theme.dart';

void main() {
  test('AppTheme.dark GameColors uzantısını ve marka renklerini taşır', () {
    final theme = AppTheme.dark();
    final colors = theme.extension<GameColors>();
    expect(colors, isNotNull);
    expect(theme.primaryColor, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(colors!.joker, const Color(0xFFFF9F43));
    expect(colors.surface, const Color(0xFF1D1B36));
  });

  test('sayaç stili tabular figures kullanır', () {
    final style = AppText.counter();
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('GameColors.lerp uçlarda kendisini döndürür', () {
    expect(GameColors.dark.lerp(GameColors.dark, 0.5).primary, AppColors.primary);
  });
}
