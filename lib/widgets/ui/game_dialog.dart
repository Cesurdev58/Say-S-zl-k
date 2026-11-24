import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'game_button.dart';
import 'game_card.dart';

/// Tutarlı diyalog çerçevesi: başlık (+ikon), içerik ve eylemler.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    this.title,
    this.titleColor = Colors.white,
    this.icon,
    this.borderColor,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    this.padding = const EdgeInsets.all(22),
    required this.child,
    this.actions = const [],
  });

  final String? title;
  final Color titleColor;
  final IconData? icon;
  final Color? borderColor;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry padding;
  final Widget child;

  /// Genellikle `GameButton`'lar; yatay olarak eşit dağıtılır.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: GameCard(
        radius: AppRadius.xl,
        padding: padding,
        borderColor: borderColor ?? colors.primary.withValues(alpha: 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: titleColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(title!, textAlign: TextAlign.center, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Flexible(child: child),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Onay diyaloğu (Evet/Hayır). `true`: onaylandı, `false`/`null`: vazgeçildi.
///
/// [onCancel] ve [onConfirm], diyalog kapanmadan hemen önce çalışır.
Future<bool?> showGameConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => GameDialog(
      title: title,
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
      actions: [
        GameButton(
          label: cancelLabel,
          variant: GameButtonVariant.secondary,
          onPressed: () {
            onCancel?.call();
            Navigator.of(dialogContext).pop(false);
          },
        ),
        GameButton(
          label: confirmLabel,
          variant: GameButtonVariant.danger,
          onPressed: () {
            onConfirm?.call();
            Navigator.of(dialogContext).pop(true);
          },
        ),
      ],
    ),
  );
}
