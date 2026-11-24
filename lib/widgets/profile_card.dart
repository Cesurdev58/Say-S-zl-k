import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../screens/statistics_screen.dart';
import '../screens/rank_road_screen.dart'; 
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui/game_card.dart';
import 'ui/pressable.dart';
import 'ui/game_sheet.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback? onProfileUpdated; 

  const ProfileCard({super.key, required this.profile, this.onProfileUpdated});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showCustomizationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 2,
        child: GameSheet(
          heightFactor: 0.6,
          color: AppColors.background,
          child: Column(
            children: [
              const Text('Profilini Özelleştir', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              
              const TabBar(
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Karakterler', icon: Icon(Icons.person)),
                  Tab(text: 'Çerçeveler', icon: Icon(Icons.stars_rounded)),
                ],
              ),
              
              Expanded(
                child: TabBarView(
                  children: [
                    // SEKME 1: AVATARLAR
                    GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16
                      ),
                      itemCount: widget.profile.purchasedAvatars.length,
                      itemBuilder: (context, index) {
                        final String avatarId = widget.profile.purchasedAvatars[index];
                        bool isSelected = widget.profile.avatar == avatarId;
                        
                        return GestureDetector(
                          onTap: () async {
                            await UserService.instance.updateAvatar(avatarId);
                            if (widget.onProfileUpdated != null) widget.onProfileUpdated!(); 
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Image.asset('assets/avatars/$avatarId.png', width: 40, height: 40),
                            ),
                          ),
                        );
                      },
                    ),

                    // SEKME 2: ÇERÇEVELER
                    widget.profile.purchasedBorders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
                            const SizedBox(height: 16),
                            const Text('Henüz çerçeven yok.\nMağazadan satın alabilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16
                        ),
                        itemCount: widget.profile.purchasedBorders.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            bool isNoneSelected = widget.profile.selectedBorder == 'none';
                            return GestureDetector(
                              onTap: () async {
                                await UserService.instance.setBorder('none');
                                if (widget.onProfileUpdated != null) widget.onProfileUpdated!(); 
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isNoneSelected ? AppColors.accent.withValues(alpha: 0.3) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isNoneSelected ? AppColors.accent : Colors.white12, width: isNoneSelected ? 2 : 1),
                                ),
                                child: const Center(child: Icon(Icons.block, color: Colors.white54, size: 32)),
                              ),
                            );
                          }

                          final String borderId = widget.profile.purchasedBorders[index - 1];
                          bool isSelected = widget.profile.selectedBorder == borderId;
                          
                          return GestureDetector(
                            onTap: () async {
                              await UserService.instance.setBorder(borderId);
                              if (widget.onProfileUpdated != null) widget.onProfileUpdated!(); 
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accent.withValues(alpha: 0.3) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Image.asset('assets/borders/$borderId.png', width: 64, height: 64),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Pressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StatisticsScreen(profile: p)),
        );
      },
      semanticLabel: '${p.username}, seviye ${p.level}. İstatistikleri aç',
      child: GameCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        borderColor: AppColors.primary.withValues(alpha: 0.35),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar + çerçeve (dokununca özelleştirme)
                GestureDetector(
                  onTap: _showCustomizationPicker,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (p.selectedBorder != 'none')
                              Image.asset('assets/borders/${p.selectedBorder}.png', width: 64, height: 64, fit: BoxFit.contain),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.background,
                              backgroundImage: AssetImage('assets/avatars/${p.avatar}.png'),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RankRoadScreen(profile: p)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(p.rankName, style: const TextStyle(color: AppColors.lavender, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.info_outline_rounded, color: AppColors.lavender, size: 11),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(_formatNumber(p.totalScore), style: AppText.counter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Elmas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_rounded, color: AppColors.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('${p.gems}', style: AppText.counter(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Seviye ve XP çubuğu
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('Seviye ${p.level}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w800, fontSize: 12)),
                const Spacer(),
                Text('${p.currentLevelXp} / ${p.nextLevelXp} XP', style: AppText.counter(color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: p.levelProgress,
                backgroundColor: Colors.black26,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
