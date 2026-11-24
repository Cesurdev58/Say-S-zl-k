import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Nunito 400/600/700/800 ağırlıkları uygulamayla birlikte paketlenir', () async {
    for (final name in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      final data = await rootBundle.load('assets/fonts/Nunito-$name.ttf');
      expect(data.lengthInBytes, greaterThan(50000), reason: 'Nunito-$name.ttf');
      // TrueType imzası: 0x00010000
      expect(data.getUint32(0), 0x00010000, reason: 'Nunito-$name.ttf geçerli TTF değil');
    }
  });

  test('tema Nunito ailesini kullanır', () {
    expect(AppTheme.fontFamily, 'Nunito');
    expect(AppTheme.dark().textTheme.bodyMedium?.fontFamily, anyOf(isNull, 'Nunito'));
  });
}
