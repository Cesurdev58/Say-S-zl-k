import 'package:flutter/material.dart';

/// Alt kontrol çubuğundaki bir eylem ve esnek genişliği.
class GameBarItem {
  const GameBarItem({required this.child, this.flex = 1});

  final Widget child;
  final int flex;
}

/// Oyun ekranlarının alt kontrol çubuğu: üstte ince ayırıcı ışık çizgisi, altında
/// aynı yükseklikte (ergonomik 56dp) eylemler; aralarında sabit boşluk.
class GameControlBar extends StatelessWidget {
  const GameControlBar({super.key, required this.items, this.spacing = 8, this.itemHeight = 56});

  final List<GameBarItem> items;
  final double spacing;

  /// Tüm eylemlerin ortak yüksekliği (en az 48dp dokunma alanı).
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Üstten ince ayırıcı ışık çizgisi
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.22), Colors.transparent]),
          ),
        ),
        Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(flex: items[i].flex, child: SizedBox(height: itemHeight, child: items[i].child)),
            ],
          ],
        ),
      ],
    );
  }
}
