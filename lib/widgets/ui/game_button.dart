import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

enum GameButtonVariant { primary, secondary, danger, accent, warning }

/// Uygulama genelinde tutarlı buton: yumuşak gölge, belirgin kenarlık,
/// üst kenar ışığı ve en az 48dp dokunma alanı.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GameButtonVariant.primary,
    this.icon,
    this.fontSize = 13,
    this.semanticLabel,
  });

  /// Dokunma alanı alt sınırı (Material erişilebilirlik yönergesi).
  static const double minHeight = 48;

  final String label;

  /// `null` ise buton devre dışıdır.
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final IconData? icon;
  final double fontSize;
  final String? semanticLabel;

  Color _base() {
    switch (variant) {
      case GameButtonVariant.primary:
        return AppColors.primaryDeep;
      case GameButtonVariant.secondary:
        return Colors.white.withValues(alpha: 0.06);
      case GameButtonVariant.danger:
        return AppColors.wrong;
      case GameButtonVariant.accent:
        return AppColors.accent;
      case GameButtonVariant.warning:
        return AppColors.joker;
    }
  }

  Color _border() {
    switch (variant) {
      case GameButtonVariant.primary:
        return AppColors.primaryBright.withValues(alpha: 0.7);
      case GameButtonVariant.secondary:
        return Colors.white.withValues(alpha: 0.18);
      case GameButtonVariant.danger:
        return Colors.white.withValues(alpha: 0.3);
      case GameButtonVariant.accent:
      case GameButtonVariant.warning:
        return Colors.white.withValues(alpha: 0.35);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color base = _base();
    final bool isSecondary = variant == GameButtonVariant.secondary;
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);

    final Color top = isSecondary ? Colors.white.withValues(alpha: 0.09) : Color.alphaBlend(Colors.white.withValues(alpha: 0.16), base);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: (enabled && !isSecondary)
                    ? [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
                    border: Border.all(color: _border(), width: 1.2),
                  ),
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: radius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: Colors.white, size: fontSize + 5),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
