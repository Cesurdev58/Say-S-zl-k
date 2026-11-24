import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/theme/app_colors.dart';
import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/game_background.dart';
import 'package:kelime_islem_game/widgets/ui/target_core.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark(), home: child);

void main() {
  testWidgets('GameBackground: lacivertten mora gradyan ve çocuğu çizer', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(backgroundColor: Colors.transparent, body: GameBackground(child: Center(child: Text('içerik'))))));
    expect(find.text('içerik'), findsOneWidget);
    final gradient = GameBackground.decoration.gradient as LinearGradient;
    expect(gradient.colors, [AppColors.atmosphereTop, AppColors.atmosphereMid, AppColors.atmosphereBottom]);
    // Statik arka plan, animasyonlu çocuktan ayrı bir RepaintBoundary'de
    expect(find.descendant(of: find.byType(GameBackground), matching: find.byType(RepaintBoundary)), findsWidgets);
  });

  testWidgets('GameBackground içindeki sayfa tam ekranı kaplar', (tester) async {
    await tester.pumpWidget(_host(const GameBackground(child: SizedBox.expand(child: Text('x')))));
    expect(tester.getSize(find.byType(GameBackground)), tester.view.physicalSize / tester.view.devicePixelRatio);
  });

  testWidgets('TargetCore: glow, etiket ve hedef sayıyı sayarak gösterir', (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: Center(child: TargetCore(value: 487)))));
    expect(find.text('HEDEF SAYI'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('487'), findsOneWidget);
    final shadowed = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((d) => d.decoration is BoxDecoration && ((d.decoration as BoxDecoration).boxShadow?.length ?? 0) >= 2);
    expect(shadowed, isNotEmpty, reason: 'dış parlama (glow) gölgeleri');
    final number = tester.widget<Text>(find.text('487'));
    expect(number.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(number.style!.fontSize, greaterThanOrEqualTo(40));
  });

  testWidgets('TargetCore yeni hedefte yeniden 0\'dan sayar', (tester) async {
    int target = 100;
    late StateSetter set;
    await tester.pumpWidget(_host(Scaffold(body: StatefulBuilder(builder: (context, s) {
      set = s;
      return TargetCore(value: target);
    }))));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
    set(() => target = 250);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('250'), findsOneWidget);
  });
}
