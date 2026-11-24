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
    this.stacked = false,
    this.emphasized = false,
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

  /// true ise ikon etiketin üstünde, dikey yerleşimle gösterilir (dar butonlar için).
  final bool stacked;

  /// true ise buton belirgin vurgulanır: daha güçlü parlama, kalın kenarlık ve yazı.
  final bool emphasized;

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
                    ? [
                        BoxShadow(color: base.withValues(alpha: emphasized ? 0.6 : 0.35), blurRadius: emphasized ? 20 : 12, offset: Offset(0, emphasized ? 7 : 5)),
                        if (emphasized) BoxShadow(color: base.withValues(alpha: 0.3), blurRadius: 32, spreadRadius: 1),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
                    border: Border.all(color: emphasized ? Colors.white.withValues(alpha: 0.55) : _border(), width: emphasized ? 1.6 : 1.2),
                  ),
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: radius,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: stacked ? 4 : 8, vertical: stacked ? 4 : 10),
                      child: Center(child: stacked && icon != null ? _stackedContent() : _rowContent()),
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

  TextStyle get _labelStyle => TextStyle(color: Colors.white, fontWeight: emphasized ? FontWeight.w800 : FontWeight.bold, fontSize: fontSize);

  Widget _rowContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: fontSize + 5),
          const SizedBox(width: 6),
        ],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: _labelStyle)),
      ],
    );
  }

  // Büyük yazı boyutlarında içerik taşmak yerine kademeli küçülür.
  Widget _stackedContent() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, textAlign: TextAlign.center, style: _labelStyle),
        ],
      ),
    );
  }
}
