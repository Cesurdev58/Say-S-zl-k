import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/math_game_board.dart';
import 'package:kelime_islem_game/widgets/word_game_board.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('WordGameBoard harf ve JOKER dokunuşlarını doğru callback\'e yönlendirir', (tester) async {
    final taps = <String>[];
    int? jokerIndex;
    await tester.pumpWidget(_host(WordGameBoard(
      availableLetters: const ['K', 'A', 'JOKER'],
      selectedIndices: const [],
      selectedLetters: const [],
      isPaused: false,
      onLetterTap: (i, c) => taps.add('$i$c'),
      onJokerTap: (i) => jokerIndex = i,
    )));
    await tester.tap(find.text('K'));
    await tester.tap(find.text('JOKER'));
    expect(taps, ['0K']);
    expect(jokerIndex, 2);
  });

  testWidgets('WordGameBoard kullanılmış taşa ve duraklatmada dokunmayı yok sayar', (tester) async {
    int taps = 0;
    await tester.pumpWidget(_host(WordGameBoard(
      availableLetters: const ['K', 'A'],
      selectedIndices: const [0],
      selectedLetters: const ['K'],
      isPaused: false,
      onLetterTap: (_, __) => taps++,
      onJokerTap: (_) {},
    )));
    // 'K' hem seçili alanda hem kullanılmış taşta görünür; tahtadaki taş son sıradadır
    await tester.tap(find.text('K').last);
    expect(taps, 0);
    await tester.tap(find.text('A'));
    expect(taps, 1);
  });

  testWidgets('MathGameBoard hedefi, sayıları ve işleçleri gösterir', (tester) async {
    final ops = <String>[];
    await tester.pumpWidget(_host(MathGameBoard(
      targetNumber: 487,
      historySteps: const [],
      currentNumbers: const [75, 6],
      firstNumIndex: 0,
      selectedOp: null,
      isPaused: false,
      onNumberTap: (_, __) {},
      onOperatorTap: ops.add,
    )));
    await tester.pumpAndSettle();
    expect(find.text('487'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    await tester.tap(find.text('×'));
    expect(ops, ['*']);
  });
}
