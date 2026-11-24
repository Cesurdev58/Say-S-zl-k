import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/main.dart';

void main() {
  testWidgets('Home screen shows game title and menu buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KelimeIslemApp());
    await tester.pumpAndSettle();

    expect(find.text('Bir Kelime'), findsOneWidget);
    expect(find.text('Bir İşlem'), findsOneWidget);
    expect(find.text('1v1 Online Maç'), findsOneWidget);
    expect(find.text('Oda Kur / Katıl'), findsOneWidget);
    expect(find.text('Alıştırma / Solo'), findsOneWidget);
  });
}
