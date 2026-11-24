import 'package:flutter/material.dart';

/// Cihazda "animasyonları azalt" açıksa animasyon sürelerini sıfırlar.
abstract final class Motion {
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d] süresini döndürür; hareket azaltma açıksa [Duration.zero].
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
