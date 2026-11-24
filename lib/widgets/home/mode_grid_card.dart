import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../ui/game_card.dart';
import '../ui/pressable.dart';

/// Ana menüdeki 2'li grid için mod kartı. [locked] true ise soluk ve kilit ikonlu.
class ModeGridCard extends StatelessWidget {
  const ModeGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool locked;

  /// Kart yüksekliği: sabit kısım (iç boşluk + ikon + aralıklar) + yazı ölçeğiyle büyüyen metin.
  /// Grid'de `mainAxisExtent` olarak kullanılır; büyük yazı boyutunda taşmayı önler.
  static double extentFor(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(1.0);
    return 96 + 47 * scale;
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = locked ? Colors.white38 : color;
    return Pressable(
      onTap: onTap,
      semanticLabel: locked ? '$title, kilitli. $subtitle' : '$title. $subtitle',
      child: Opacity(
        opacity: locked ? 0.7 : 1,
        child: GameCard(
          color: AppColors.surface,
          borderColor: accent.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0.18)],
                        ),
                        border: Border.all(color: accent.withValues(alpha: 0.5)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    if (locked) const Icon(Icons.lock_rounded, color: Colors.white54, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
