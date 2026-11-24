import 'package:flutter/material.dart';

/// Alt kontrol çubuğundaki bir eylem ve esnek genişliği.
class GameBarItem {
  const GameBarItem({required this.child, this.flex = 1});

  final Widget child;
  final int flex;
}

/// Oyun ekranlarının alt kontrol çubuğu: eylemler yan yana, aralarında sabit boşluk.
class GameControlBar extends StatelessWidget {
  const GameControlBar({super.key, required this.items, this.spacing = 6});

  final List<GameBarItem> items;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(flex: items[i].flex, child: items[i].child),
        ],
      ],
    );
  }
}
