import 'package:flutter/material.dart';

/// Diyalog gibi State'i olmayan yerlerde bir [TextEditingController]'ı doğru
/// yaşam döngüsüyle (initState/dispose) sağlar; sızıntıyı önler.
class TextControllerScope extends StatefulWidget {
  const TextControllerScope({super.key, required this.builder});

  final Widget Function(BuildContext context, TextEditingController controller) builder;

  @override
  State<TextControllerScope> createState() => _TextControllerScopeState();
}

class _TextControllerScopeState extends State<TextControllerScope> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
