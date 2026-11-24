import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Alttan açılan paneller (`showModalBottomSheet`) için ortak çerçeve:
/// 24px yuvarlak üst köşeler, ortalanmış tutamaç, ince üst kenar ışığı ve
/// ferah iç boşluklar. Klavye ve alt güvenli alan payını kendisi ekler.
///
/// [heightFactor] verilirse panel ekran yüksekliğinin o oranını kaplar ve
/// [child] kalan alanı doldurur (içinde `Expanded` kullanılabilir); verilmezse
/// panel içeriği kadar yer kaplar.
class GameSheet extends StatelessWidget {
  const GameSheet({
    super.key,
    required this.child,
    this.heightFactor,
    this.color = AppColors.surface,
    this.padding = EdgeInsets.zero,
  });

  static const double radius = 24;

  final Widget child;
  final double? heightFactor;
  final Color color;

  /// İçeriğin çevresindeki boşluk (tutamaç alanı hariç).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    const BorderRadius br = BorderRadius.vertical(top: Radius.circular(radius));
    final bool fixed = heightFactor != null;
    final Widget body = Padding(padding: padding, child: child);

    return Container(
      height: fixed ? media.size.height * heightFactor! : null,
      // Klavye açıldığında içerik yukarı kayar
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Column(
              mainAxisSize: fixed ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const SheetHandle(),
                const SizedBox(height: 16),
                if (fixed) Expanded(child: body) else Flexible(child: body),
                SizedBox(height: media.padding.bottom > 0 ? media.padding.bottom : 16),
              ],
            ),
            // İnce üst kenar ışığı
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1.5,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.4), Colors.transparent]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortalanmış sürükleme tutamacı.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
