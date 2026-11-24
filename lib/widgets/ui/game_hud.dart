import 'package:flutter/material.dart';

/// Oyun ekranları için üst bar (HUD): geri tuşu, başlık ve sağ taraf eylemleri.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing = const [],
    this.centerTitle = false,
    this.padding = const EdgeInsets.all(12),
    this.titleFontSize = 14,
    this.backIconSize = 20,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> trailing;

  /// `true` ise başlık geri tuşu ile sağ eylemler arasında ortalanır.
  final bool centerTitle;
  final EdgeInsetsGeometry padding;
  final double titleFontSize;
  final double backIconSize;

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = Text(
      title,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize),
    );
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: centerTitle ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Geri',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: backIconSize),
            onPressed: onBack,
          ),
          titleWidget,
          if (!centerTitle) const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: trailing),
        ],
      ),
    );
  }
}
