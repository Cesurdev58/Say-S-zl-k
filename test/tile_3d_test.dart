import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/ui/answer_slots.dart';
import 'package:kelime_islem_game/widgets/ui/game_tile.dart';
import 'package:kelime_islem_game/widgets/ui/recessed_slot.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: Center(child: child)));

/// Taş yüzünün (gradyanlı kutu) ekrandaki üst kenarı.
double _faceTop(WidgetTester t) {
  final face = find.descendant(
    of: find.byType(GameTile),
    matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null),
  );
  return t.getTopLeft(face.first).dy;
}

void main() {
  test('dudak rengi taş renginden koyudur', () {
    const base = Color(0xFF5A4FCF);
    final lip = GameTile.lipColor(base);
    expect(HSLColor.fromColor(lip).lightness, lessThan(HSLColor.fromColor(base).lightness));
    expect(GameTile.lipHeight, 4);
    expect(GameTile.pressDepth, 3);
  });

  testWidgets('taş toplam boyutunu korur: yüz = yükseklik - 4px dudak', (tester) async {
    await tester.pumpWidget(_host(const GameTile(width: 52, height: 52, color: Color(0xFF5A4FCF), child: Text('A'))));
    expect(tester.getSize(find.byType(GameTile)), const Size(52, 52));
    final face = find.descendant(
      of: find.byType(GameTile),
      matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null),
    );
    expect(tester.getSize(face.first).height, 48);
  });

  testWidgets('basılınca yüz 3px aşağı iner, bırakılınca yerine döner', (tester) async {
    await tester.pumpWidget(_host(GameTile(width: 52, height: 52, color: const Color(0xFF5A4FCF), onTap: () {}, child: const Text('A'))));
    final double rest = _faceTop(tester);
    final g = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pumpAndSettle();
    // AnimatedScale (0.92) yüzü merkeze doğru da küçültür; ölçeği ayrıştırıp yalnızca iniş miktarını ölçüyoruz.
    final double scaledRest = tester.getCenter(find.byType(GameTile)).dy - (tester.getCenter(find.byType(GameTile)).dy - rest) * GameTile.pressedScale;
    expect(_faceTop(tester) - scaledRest, closeTo(GameTile.pressDepth * GameTile.pressedScale, 0.6));
    await g.up();
    await tester.pumpAndSettle();
    expect(_faceTop(tester), closeTo(rest, 0.1));
  });

  testWidgets('flat taş gömülüdür: dudak görünmez', (tester) async {
    await tester.pumpWidget(_host(const GameTile(width: 52, height: 52, color: Color(0xFF5A4FCF), flat: true, child: Text('A'))));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(find.descendant(of: find.byType(GameTile), matching: find.byType(AnimatedOpacity))).opacity, 0);
  });

  testWidgets('AnswerSlots: harf sayısı kadar yuva çizer, doluları taşla gösterir', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(width: 320, child: AnswerSlots(letters: ['K', 'A'], slotCount: 8))));
    await tester.pumpAndSettle();
    expect(find.byType(RecessedSlot), findsNWidgets(8));
    expect(find.byType(GameTile), findsNWidgets(2));
    expect(find.text('K'), findsOneWidget);
  });

  testWidgets('AnswerSlots dar ekranda taşmaz', (tester) async {
    await tester.pumpWidget(_host(const SizedBox(width: 260, child: AnswerSlots(letters: ['K'], slotCount: 8))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AnswerSlots)).width, lessThanOrEqualTo(260));
  });

  testWidgets('RecessedSlot çocuğu gösterir (kesikli ve düz)', (tester) async {
    await tester.pumpWidget(_host(const Column(mainAxisSize: MainAxisSize.min, children: [
      RecessedSlot(width: 40, height: 48, child: Text('x')),
      RecessedSlot(width: 40, height: 48, dashed: false, child: Text('y')),
    ])));
    expect(find.text('x'), findsOneWidget);
    expect(find.text('y'), findsOneWidget);
  });
}
