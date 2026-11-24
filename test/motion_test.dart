import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/math_game_board.dart';
import 'package:kelime_islem_game/widgets/ui/animated_slot.dart';
import 'package:kelime_islem_game/widgets/ui/count_up_text.dart';
import 'package:kelime_islem_game/widgets/ui/error_shake.dart';
import 'package:kelime_islem_game/widgets/ui/game_tile.dart';
import 'package:kelime_islem_game/widgets/word_game_board.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
      home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
    );

double _scale(WidgetTester t) => t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  pageTransitionTests();
  group('GameTile basma animasyonu', () {
    testWidgets('basılıyken 0.92, bırakılınca 1.0 ve onTap çalışır', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(GameTile(width: 50, height: 50, color: Colors.purple, onTap: () => taps++, child: const Text('A'))));
      expect(_scale(tester), 1.0);
      final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
      await tester.pump();
      expect(_scale(tester), GameTile.pressedScale);
      expect(GameTile.pressedScale, 0.92);
      await gesture.up();
      await tester.pump();
      expect(_scale(tester), 1.0);
      expect(taps, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('onTap yoksa AnimatedScale kullanılmaz', (tester) async {
      await tester.pumpWidget(_host(const GameTile(width: 50, height: 50, color: Colors.purple, child: Text('A'))));
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('hareket azaltma açıkken süre sıfırdır', (tester) async {
      await tester.pumpWidget(_host(reduce: true, GameTile(width: 50, height: 50, color: Colors.purple, onTap: () {}, child: const Text('A'))));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration, Duration.zero);
    });
  });

  group('Cevap satırı geçişleri', () {
    testWidgets('seçilen harf animasyonla girer ve çıkar', (tester) async {
      final letters = ['K', 'A', 'L'];
      Widget board(List<String> sel) => _host(WordGameBoard(
            availableLetters: letters,
            selectedIndices: List.generate(sel.length, (i) => i),
            selectedLetters: sel,
            isPaused: false,
            onLetterTap: (_, __) {},
            onJokerTap: (_) {},
          ));
      await tester.pumpWidget(board([]));
      await tester.pumpWidget(board(['K']));
      await tester.pump(const Duration(milliseconds: 90));
      // Geçiş sürerken giren taş ölçeklenir (1'den küçük)
      expect(find.byType(ScaleTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('K'), findsNWidgets(2)); // cevap satırı + tahta taşı

      await tester.pumpWidget(board([]));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('K'), findsNWidgets(2), reason: 'çıkan taş geçiş boyunca görünür kalır');
      await tester.pumpAndSettle();
      expect(find.text('K'), findsOneWidget);
    });

    testWidgets('AnimatedSlot hareket azaltmada anında değişir', (tester) async {
      await tester.pumpWidget(_host(reduce: true, const AnimatedSlot(child: Text('x', key: ValueKey('x')))));
      expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, Duration.zero);
    });
  });

  group('Hata sallanması', () {
    testWidgets('tetiklenince yatay kayar, kırmızı kenarlık çıkar ve sonunda yerine döner', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(ErrorShake(trigger: signal, child: const SizedBox(width: 100, height: 40, child: Text('cevap')))));
      final base = tester.getCenter(find.text('cevap'));
      signal.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getCenter(find.text('cevap')).dx, isNot(base.dx));
      expect(find.byType(DecoratedBox), findsWidgets);
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.text('cevap')).dx, closeTo(base.dx, 0.01));
    });

    testWidgets('hareket azaltmada kayma olmaz', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(reduce: true, ErrorShake(trigger: signal, child: const SizedBox(width: 100, height: 40, child: Text('cevap')))));
      final base = tester.getCenter(find.text('cevap'));
      signal.value++;
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getCenter(find.text('cevap')).dx, base.dx);
      await tester.pumpAndSettle();
    });

    testWidgets('MathGameBoard errorSignal ile sallanır', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(MathGameBoard(
        targetNumber: 100,
        historySteps: const ['1 + 2 = 3'],
        currentNumbers: const [3, 5],
        firstNumIndex: null,
        selectedOp: null,
        isPaused: false,
        onNumberTap: (_, __) {},
        onOperatorTap: (_) {},
        errorSignal: signal,
      )));
      await tester.pumpAndSettle();
      final base = tester.getCenter(find.text('1 + 2 = 3'));
      signal.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getCenter(find.text('1 + 2 = 3')).dx, isNot(base.dx));
      await tester.pumpAndSettle();
    });
  });

  group('Sayaç animasyonu', () {
    testWidgets('fromZero: 0\'dan hedefe sayar', (tester) async {
      await tester.pumpWidget(_host(const CountUpText(value: 487, fromZero: true, style: TextStyle())));
      expect(find.text('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, inInclusiveRange(1, 486));
      await tester.pumpAndSettle();
      expect(find.text('487'), findsOneWidget);
    });

    testWidgets('değer değişince eski değerden yenisine sayar', (tester) async {
      Widget w(int v) => _host(CountUpText(value: v, style: const TextStyle()));
      await tester.pumpWidget(w(10));
      expect(find.text('10'), findsOneWidget);
      await tester.pumpWidget(w(30));
      await tester.pump(const Duration(milliseconds: 250));
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, inInclusiveRange(11, 29));
      await tester.pumpAndSettle();
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('hareket azaltmada anında hedef değeri gösterir', (tester) async {
      await tester.pumpWidget(_host(reduce: true, const CountUpText(value: 487, fromZero: true, style: TextStyle())));
      await tester.pump();
      expect(find.text('487'), findsOneWidget);
    });
  });
}

void pageTransitionTests() {
  Widget app({required bool reduce, required TargetPlatform platform}) => MaterialApp(
        theme: AppTheme.dark().copyWith(platform: platform),
        builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Text('ikinci')))),
              child: const Text('git'),
            ),
          ),
        ),
      );

  group('Sayfa geçişleri', () {
    testWidgets('Android: fade + kayma uygulanır', (tester) async {
      await tester.pumpWidget(app(reduce: false, platform: TargetPlatform.android));
      await tester.tap(find.text('git'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fade = tester.widgetList<FadeTransition>(find.descendant(of: find.byType(MaterialApp), matching: find.byType(FadeTransition)));
      expect(fade.any((f) => f.opacity.value > 0 && f.opacity.value < 1), isTrue);
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('ikinci'), findsOneWidget);
    });

    testWidgets('hareket azaltma açıkken geçiş efekti yoktur', (tester) async {
      await tester.pumpWidget(app(reduce: true, platform: TargetPlatform.android));
      await tester.tap(find.text('git'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final fades = tester.widgetList<FadeTransition>(find.descendant(of: find.byType(Navigator), matching: find.byType(FadeTransition)));
      expect(fades.where((f) => f.opacity.value > 0 && f.opacity.value < 1), isEmpty);
      await tester.pumpAndSettle();
    });

    testWidgets('iOS: Cupertino geçişi (geri kaydırma) korunur', (tester) async {
      await tester.pumpWidget(app(reduce: false, platform: TargetPlatform.iOS));
      await tester.tap(find.text('git'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPageTransition), findsOneWidget);
    });
  });
}
