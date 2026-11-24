import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/ui/game_button.dart';
import 'package:kelime_islem_game/widgets/ui/game_control_bar.dart';

Widget _app(Widget bar, {double textScale = 1.0}) => MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: w!),
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.all(20), child: bar))),
    );

/// Solo (süresiz) ekrandaki 4 eylemli çubuğun aynısı.
Widget _soloBar(List<String> taps) => GameControlBar(items: [
      GameBarItem(flex: 2, child: GameButton(label: 'Sil', icon: Icons.backspace_rounded, stacked: true, variant: GameButtonVariant.secondary, fontSize: 11, onPressed: () => taps.add('sil'))),
      GameBarItem(flex: 2, child: GameButton(label: 'Temizle', icon: Icons.delete_sweep_rounded, stacked: true, variant: GameButtonVariant.secondary, fontSize: 11, onPressed: () => taps.add('temizle'))),
      GameBarItem(flex: 3, child: GameButton(label: 'Cevabı Göster', icon: Icons.lightbulb_rounded, stacked: true, variant: GameButtonVariant.accent, fontSize: 11, onPressed: () => taps.add('cevap'))),
      GameBarItem(flex: 4, child: GameButton(label: 'Onayla', icon: Icons.check_rounded, emphasized: true, fontSize: 14, onPressed: () => taps.add('onayla'))),
    ]);

/// Çok oyunculu ekrandaki çubuğun aynısı.
Widget _multiBar(List<String> taps) => GameControlBar(items: [
      GameBarItem(flex: 2, child: GameButton(label: 'Sil', icon: Icons.backspace_rounded, stacked: true, variant: GameButtonVariant.secondary, fontSize: 11, onPressed: () => taps.add('sil'))),
      GameBarItem(flex: 2, child: GameButton(label: 'Temizle', icon: Icons.delete_sweep_rounded, stacked: true, variant: GameButtonVariant.secondary, fontSize: 11, onPressed: () => taps.add('temizle'))),
      GameBarItem(flex: 2, child: GameButton(label: 'Pas (3)', icon: Icons.skip_next_rounded, stacked: true, fontSize: 11, variant: GameButtonVariant.warning, onPressed: () => taps.add('pas'))),
      GameBarItem(flex: 4, child: GameButton(label: 'Gönder', icon: Icons.send_rounded, emphasized: true, fontSize: 14, variant: GameButtonVariant.accent, onPressed: () => taps.add('gonder'))),
    ]);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('tüm eylemler aynı yükseklikte ve en az 48dp dokunma alanında', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_soloBar([])));
    final heights = tester.widgetList<GameButton>(find.byType(GameButton)).map((b) => tester.getSize(find.byWidget(b)).height).toSet();
    expect(heights, {56.0});
    expect(GameButton.minHeight, 48);
  });

  testWidgets('üst ayırıcı ışık çizgisi var (1px, saydam uçlu gradyan)', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_soloBar([])));
    final line = tester.widgetList<Container>(find.descendant(of: find.byType(GameControlBar), matching: find.byType(Container))).firstWhere(
          (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).gradient is LinearGradient && c.constraints?.maxHeight == 1,
        );
    final gradient = (line.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors.first, Colors.transparent);
    expect(gradient.colors.last, Colors.transparent);
    expect(gradient.colors[1].a, greaterThan(0.1));
  });

  testWidgets('"Onayla" vurgulu: diğerlerinden geniş, ikonlu ve çift katmanlı parlama', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_soloBar([])));
    final confirm = find.widgetWithText(GameButton, 'Onayla');
    final sil = find.widgetWithText(GameButton, 'Sil');
    expect(tester.getSize(confirm).width, greaterThan(tester.getSize(sil).width * 1.8));
    expect(find.descendant(of: confirm, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
    final glow = tester.widgetList<DecoratedBox>(find.descendant(of: confirm, matching: find.byType(DecoratedBox))).where((d) => d.decoration is BoxDecoration && ((d.decoration as BoxDecoration).boxShadow?.length ?? 0) >= 2);
    expect(glow, isNotEmpty);
    // Vurgusuz düğmede tek gölge
    final plain = tester.widgetList<DecoratedBox>(find.descendant(of: find.widgetWithText(GameButton, 'Cevabı Göster'), matching: find.byType(DecoratedBox))).where((d) => d.decoration is BoxDecoration && ((d.decoration as BoxDecoration).boxShadow?.length ?? 0) >= 2);
    expect(plain, isEmpty);
  });

  testWidgets('dar düğmelerde ikon etiketin üstünde (dikey yerleşim)', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(_soloBar([])));
    final icon = tester.getCenter(find.descendant(of: find.widgetWithText(GameButton, 'Sil'), matching: find.byIcon(Icons.backspace_rounded)));
    final label = tester.getCenter(find.descendant(of: find.widgetWithText(GameButton, 'Sil'), matching: find.text('Sil')));
    expect(icon.dy, lessThan(label.dy));
    expect((icon.dx - label.dx).abs(), lessThan(1));
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('solo çubuğu 360dp ve ${(scale * 100).round()}% yazıda taşmaz, dokunmalar iletilir', (tester) async {
      _phone(tester);
      final taps = <String>[];
      await tester.pumpWidget(_app(_soloBar(taps), textScale: scale));
      expect(tester.takeException(), isNull);
      for (final l in ['Sil', 'Temizle', 'Cevabı Göster', 'Onayla']) {
        await tester.tap(find.widgetWithText(GameButton, l).hitTestable(), warnIfMissed: false);
      }
      expect(taps, ['sil', 'temizle', 'cevap', 'onayla']);
    });

    testWidgets('çok oyunculu çubuğu 360dp ve ${(scale * 100).round()}% yazıda taşmaz', (tester) async {
      _phone(tester);
      final taps = <String>[];
      await tester.pumpWidget(_app(_multiBar(taps), textScale: scale));
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(GameButton, 'Gönder'));
      await tester.tap(find.widgetWithText(GameButton, 'Pas (3)'));
      expect(taps, ['gonder', 'pas']);
    });
  }

  testWidgets('devre dışı düğme (onPressed null) dokunmayı iletmez ve soluk görünür', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const GameControlBar(items: [
      GameBarItem(child: GameButton(label: 'Pas (0)', icon: Icons.skip_next_rounded, stacked: true, variant: GameButtonVariant.warning, onPressed: null)),
    ])));
    expect(tester.widget<Opacity>(find.descendant(of: find.byType(GameButton), matching: find.byType(Opacity))).opacity, lessThan(1));
  });
}
