import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../ui/pressable.dart';

/// Ana menünün vitrin kartı: büyük, gradyanlı ve ikonik "Hızlı Oyun" kartı.
class HeroModeCard extends StatelessWidget {
  const HeroModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
    this.actionLabel = 'OYNA',
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(AppRadius.xl + 4);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 12)),
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 1),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: Container(
            constraints: const BoxConstraints(minHeight: 172),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryBright, AppColors.primary, AppColors.indigo, AppColors.violet],
                stops: [0.0, 0.35, 0.75, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
            ),
            child: Stack(
              children: [
                // Dekoratif devasa ikon (filigran)
                Positioned(
                  right: -26,
                  bottom: -34,
                  child: Icon(icon, size: 190, color: Colors.white.withValues(alpha: 0.12)),
                ),
                // Üst kenar ışığı
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.6), Colors.transparent]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined, color: AppColors.mint, size: 13),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(badge, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.3)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(actionLabel, style: const TextStyle(color: AppColors.violet, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.play_arrow_rounded, color: AppColors.violet, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.08)]),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 24)],
                        ),
                        child: Icon(icon, color: Colors.white, size: 44),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
