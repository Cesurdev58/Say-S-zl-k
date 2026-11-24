import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/ui/game_confetti.dart';
import 'package:kelime_islem_game/widgets/ui/game_sheet.dart';
import 'package:kelime_islem_game/widgets/ui/motion.dart';
import 'package:kelime_islem_game/widgets/ui/praise_overlay.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
      home: Scaffold(body: Stack(children: [child])),
    );

void main() {
  group('PraiseOverlay', () {
    testWidgets('tetiklenmeden görünmez; tetiklenince bir övgü gösterip 1 sn sonra kaybolur', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(PraiseOverlay(trigger: signal)));
      for (final w in PraiseOverlay.defaultWords) {
        expect(find.text(w), findsNothing);
      }
      signal.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final shown = PraiseOverlay.defaultWords.where((w) => find.text(w).evaluate().isNotEmpty);
      expect(shown.length, 1);
      final opacity = tester.widget<Opacity>(find.descendant(of: find.byType(PraiseOverlay), matching: find.byType(Opacity)));
      expect(opacity.opacity, greaterThan(0.9));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(Opacity), findsNothing, reason: 'animasyon bitince katman tamamen kalkar');
    });

    testWidgets('ağır gölge yok: yalnızca bulanıklıksız tek gölge, RepaintBoundary içinde', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(PraiseOverlay(trigger: signal, words: const ['EFSANE!'])));
      signal.value++;
      await tester.pump();
      final text = tester.widget<Text>(find.text('EFSANE!'));
      final shadows = text.style!.shadows!;
      expect(shadows.length, 1);
      expect(shadows.every((s) => s.blurRadius == 0), isTrue);
      expect(find.ancestor(of: find.text('EFSANE!'), matching: find.byType(RepaintBoundary)), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('her tetikte yeniden oynar', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(PraiseOverlay(trigger: signal, words: const ['HARİKA!'])));
      signal.value++;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing);
      signal.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('HARİKA!'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('hareket azaltmada ölçek/kayma yok, yalnızca solma', (tester) async {
      final signal = ValueNotifier<int>(0);
      await tester.pumpWidget(_host(reduce: true, PraiseOverlay(trigger: signal, words: const ['ZAFER!'])));
      signal.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final scaleTransforms = tester.widgetList<Transform>(find.descendant(of: find.byType(PraiseOverlay), matching: find.byType(Transform)));
      expect(scaleTransforms, isEmpty);
      await tester.pumpAndSettle();
    });
  });

  group('GameConfetti', () {
    testWidgets('hafif ayarlar: ≤12 parçacık, tek patlama, küçük basit parçacıklar', (tester) async {
      final controller = GameConfetti.newController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(Positioned.fill(child: GameConfetti(controller: controller, numberOfParticles: 12, alignment: Alignment.topCenter))));
      final w = tester.widget<ConfettiWidget>(find.byType(ConfettiWidget));
      expect(w.numberOfParticles, inInclusiveRange(10, 12));
      expect(w.emissionFrequency, 0);
      expect(w.maximumSize.width, lessThanOrEqualTo(12));
      expect(w.createParticlePath, isNotNull);
      expect(w.createParticlePath!(const Size(8, 5)).getBounds().height, 5);
      expect(find.ancestor(of: find.byType(ConfettiWidget), matching: find.byType(RepaintBoundary)), findsWidgets);
      expect(controller.duration.inMilliseconds, inInclusiveRange(500, 600));
    });

    testWidgets('oynatılınca parçacık çizer ve süre bitince temizlenir (çökme yok)', (tester) async {
      final controller = GameConfetti.newController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(Positioned.fill(child: GameConfetti(controller: controller, blastDirection: -1))));
      controller.play();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      controller.stop();
      await tester.pump();
    });
  });

  group('Motion.afterFrame', () {
    testWidgets('eylem hemen değil, sonraki kare çizilince çalışır', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));
      bool ran = false;
      Motion.afterFrame(() => ran = true);
      expect(ran, isFalse);
      await tester.pump();
      expect(ran, isTrue);
    });
  });

  group('GameSheet', () {
    testWidgets('24px üst köşe, ortalanmış tutamaç ve içerik', (tester) async {
      await tester.pumpWidget(_host(const Align(alignment: Alignment.bottomCenter, child: GameSheet(child: Text('içerik')))));
      final decoration = tester.widget<Container>(find.descendant(of: find.byType(GameSheet), matching: find.byType(Container)).first).decoration as BoxDecoration;
      expect(decoration.borderRadius, const BorderRadius.vertical(top: Radius.circular(24)));
      expect(GameSheet.radius, 24);
      expect(find.text('içerik'), findsOneWidget);
      final handle = find.byType(SheetHandle);
      expect(handle, findsOneWidget);
      expect(tester.getCenter(handle).dx, closeTo(tester.getCenter(find.byType(GameSheet)).dx, 0.5));
      expect(tester.getSize(find.descendant(of: handle, matching: find.byType(Container))).width, 44);
    });

    testWidgets('heightFactor ekran yüksekliğinin oranını kaplar ve Expanded içerik çalışır', (tester) async {
      await tester.pumpWidget(_host(const Align(
        alignment: Alignment.bottomCenter,
        child: GameSheet(heightFactor: 0.6, child: Column(children: [Text('başlık'), Expanded(child: Center(child: Text('liste')))])),
      )));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(tester.getSize(find.byType(GameSheet)).height, closeTo(screen.height * 0.6, 0.5));
      expect(find.text('liste'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showModalBottomSheet içinde açılır ve klavye payını ekler', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const GameSheet(child: Text('panel'))),
              child: const Text('aç'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('panel'), findsOneWidget);
      expect(find.byType(SheetHandle), findsOneWidget);
    });
  });
}
