import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Cihazda "animasyonları azalt" açıksa animasyon sürelerini sıfırlar.
abstract final class Motion {
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d] süresini döndürür; hareket azaltma açıksa [Duration.zero].
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;

  /// [action]'ı bir sonraki kare çizildikten sonra çalıştırır (ve kare planlar).
  ///
  /// Doğru cevapta tahta sıfırlaması ile ses/konfeti/övgü tetiklemesinin aynı
  /// kareye binip darboğaz yaratmasını önlemek için kullanılır.
  static void afterFrame(VoidCallback action) {
    SchedulerBinding.instance.addPostFrameCallback((_) => action());
    SchedulerBinding.instance.ensureVisualUpdate();
  }
}
