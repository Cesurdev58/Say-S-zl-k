import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/timer_chip.dart';
import 'package:kelime_islem_game/widgets/ui/game_button.dart';
import 'package:kelime_islem_game/widgets/ui/game_card.dart';
import 'package:kelime_islem_game/widgets/ui/game_control_bar.dart';
import 'package:kelime_islem_game/widgets/ui/game_dialog.dart';
import 'package:kelime_islem_game/widgets/ui/game_hud.dart';
import 'package:kelime_islem_game/widgets/ui/game_tile.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('GameButton en az 48dp yüksekliktedir ve dokunmayı iletir', (tester) async {
    int taps = 0;
    await tester.pumpWidget(_host(SizedBox(width: 160, child: GameButton(label: 'Sil', fontSize: 12, onPressed: () => taps++))));
    expect(tester.getSize(find.byType(GameButton)).height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('Sil'));
    expect(taps, 1);
  });

  testWidgets('GameButton devre dışıyken dokunma iletilmez', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(width: 160, child: GameButton(label: 'Gönder', onPressed: null))));
    await tester.tap(find.text('Gönder'), warnIfMissed: false);
    expect(tester.widget<Opacity>(find.descendant(of: find.byType(GameButton), matching: find.byType(Opacity))).opacity, lessThan(1));
  });

  testWidgets('GameButton tüm varyantları çizer', (tester) async {
    await tester.pumpWidget(_host(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final v in GameButtonVariant.values) SizedBox(width: 160, child: GameButton(label: v.name, variant: v, onPressed: () {})),
      ],
    )));
    for (final v in GameButtonVariant.values) {
      expect(find.text(v.name), findsOneWidget);
    }
  });

  testWidgets('GameCard içeriği gösterir', (tester) async {
    await tester.pumpWidget(_host(const GameCard(child: Text('kart'))));
    expect(find.text('kart'), findsOneWidget);
  });

  testWidgets('GameTile içeriği gösterir (düz ve yükseltilmiş)', (tester) async {
    await tester.pumpWidget(_host(const Row(mainAxisSize: MainAxisSize.min, children: [
      GameTile(width: 40, height: 40, color: Colors.purple, child: Text('A')),
      GameTile(width: 40, height: 40, color: Colors.purple, flat: true, child: Text('B')),
    ])));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('GameDialog başlık, içerik ve eylemleri gösterir', (tester) async {
    await tester.pumpWidget(_host(const GameDialog(
      title: 'Başlık',
      actions: [GameButton(label: 'Tamam', onPressed: null)],
      child: Text('içerik'),
    )));
    expect(find.text('Başlık'), findsOneWidget);
    expect(find.text('içerik'), findsOneWidget);
    expect(find.text('Tamam'), findsOneWidget);
  });

  testWidgets('showGameConfirmDialog onay/vazgeç sonuçlarını döndürür ve kancaları çağırır', (tester) async {
    bool? result;
    int confirmHooks = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showGameConfirmDialog(context,
                  title: 'T', message: 'M', cancelLabel: 'Vazgeç', confirmLabel: 'Çık', onConfirm: () => confirmHooks++);
            },
            child: const Text('aç'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(confirmHooks, 0);

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çık'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(confirmHooks, 1);
  });

  testWidgets('GameHud geri tuşu ve sağ eylemleri çalışır', (tester) async {
    bool back = false;
    await tester.pumpWidget(_host(GameHud(title: 'Soru: 1/5', onBack: () => back = true, trailing: const [Text('sağ')])));
    expect(find.text('Soru: 1/5'), findsOneWidget);
    expect(find.text('sağ'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(back, isTrue);
  });

  testWidgets('GameControlBar eylemleri esnek genişlikle yerleştirir', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(
      width: 300,
      child: GameControlBar(items: [
        GameBarItem(flex: 1, child: Text('a')),
        GameBarItem(flex: 2, child: Text('b')),
      ]),
    )));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('TimerChip değer değişince yalnızca kendini günceller ve uyarı eşiğinde kırmızıya döner', (tester) async {
    final notifier = ValueNotifier<int>(7);
    await tester.pumpWidget(_host(TimerChip(seconds: notifier, warnAt: 5)));
    expect(find.text('7s'), findsOneWidget);
    Text label() => tester.widget<Text>(find.byType(Text));
    expect(label().style!.color, Colors.white);
    expect(label().style!.fontFeatures, contains(const FontFeature.tabularFigures()));
    notifier.value = 5;
    await tester.pump();
    expect(find.text('5s'), findsOneWidget);
    expect(label().style!.color, Colors.redAccent);
  });
}
