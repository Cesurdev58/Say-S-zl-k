import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kelime_islem_game/services/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
    Haptics.enabledReader = () => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('olaylar doğru titreşim türüne eşlenir', () async {
    Haptics.selection();
    Haptics.success();
    Haptics.success(exact: true);
    Haptics.error();
    Haptics.tick();
    await Future<void>.delayed(Duration.zero);
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  test('titreşim kapalıyken hiçbir şey göndermez', () async {
    Haptics.enabledReader = () => false;
    Haptics.selection();
    Haptics.success(exact: true);
    Haptics.error();
    Haptics.tick();
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
  });
}
