import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/models/user_profile.dart';
import 'package:kelime_islem_game/theme/app_theme.dart';
import 'package:kelime_islem_game/widgets/home/hero_mode_card.dart';
import 'package:kelime_islem_game/widgets/home/mode_grid_card.dart';
import 'package:kelime_islem_game/widgets/profile_card.dart';
import 'package:kelime_islem_game/widgets/ui/pressable.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)));

void main() {
  testWidgets('HeroModeCard başlık, rozet ve OYNA düğmesini gösterir; dokunma çalışır', (tester) async {
    int taps = 0;
    await tester.pumpWidget(_host(HeroModeCard(
      title: 'Hızlı Oyun',
      subtitle: 'Kelime ve işlem bir arada',
      badge: 'ZAMANA KARŞI • KARIŞIK',
      icon: Icons.bolt_rounded,
      onTap: () => taps++,
    )));
    expect(find.text('Hızlı Oyun'), findsOneWidget);
    expect(find.text('ZAMANA KARŞI • KARIŞIK'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
    expect(tester.getSize(find.byType(HeroModeCard)).height, greaterThanOrEqualTo(172));
    await tester.tap(find.text('Hızlı Oyun'));
    expect(taps, 1);
  });

  testWidgets('HeroModeCard basılınca küçülür ve bırakılınca döner', (tester) async {
    await tester.pumpWidget(_host(HeroModeCard(title: 'T', subtitle: 'S', badge: 'B', icon: Icons.bolt_rounded, onTap: () {})));
    double scale() => tester.widget<AnimatedScale>(find.descendant(of: find.byType(Pressable), matching: find.byType(AnimatedScale)).first).scale;
    expect(scale(), 1.0);
    final g = await tester.startGesture(tester.getCenter(find.text('T')));
    await tester.pump();
    expect(scale(), lessThan(1.0));
    await g.up();
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
  });

  testWidgets('ModeGridCard: 2\'li grid\'de dokunma ve kilit durumu', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(_host(GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        ModeGridCard(title: 'Kelime', subtitle: 'Harflerden kelime türet', icon: Icons.text_fields_rounded, color: Colors.purple, onTap: () => taps.add('kelime')),
        ModeGridCard(title: 'Çok Oyunculu', subtitle: 'Solo modda 500 puana ulaşınca açılır', icon: Icons.public_rounded, color: Colors.blue, locked: true, onTap: () => taps.add('multi')),
      ],
    )));
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.tap(find.text('Kelime'));
    await tester.tap(find.text('Çok Oyunculu'));
    expect(taps, ['kelime', 'multi'], reason: 'kilitli kart da dokunmayı iletir (ekran snackbar gösterir)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ModeGridCard 360dp genişlikte ve büyük yazı ölçeğinde taşmaz', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: w!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Builder(builder: (context) => GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: ModeGridCard.extentFor(context)),
            children: [
              for (final t in ['Kelime', 'İşlem', 'Çok Oyunculu', 'Oda Kur / Katıl', 'Alıştırma / Solo', 'Mağaza'])
                ModeGridCard(title: t, subtitle: 'Elmas harca, profilini özelleştir', icon: Icons.storefront_rounded, color: Colors.pink, onTap: () {}),
            ],
          )),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileCard sadeleşti: isim, rütbe, seviye, XP ve elmas tek çubukta', (tester) async {
    final profile = UserProfile(uid: 'u1', username: 'Cesur', avatar: 'boy', gems: 42, totalScore: 1234, xp: 150);
    await tester.pumpWidget(_host(ProfileCard(profile: profile)));
    expect(find.text('Cesur'), findsOneWidget);
    expect(find.text(profile.rankName), findsOneWidget);
    expect(find.text('Seviye ${profile.level}'), findsOneWidget);
    expect(find.text('${profile.currentLevelXp} / ${profile.nextLevelXp} XP'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsOneWidget);
    // Eski kalabalık istatistik sütunları ana ekrandan kalktı
    expect(find.text('Oynanan'), findsNothing);
    expect(find.text('Tek Maç Rekoru'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
