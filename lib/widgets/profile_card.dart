import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../screens/statistics_screen.dart';
import '../screens/rank_road_screen.dart'; 
import '../services/user_service.dart';
import '../theme/app_colors.dart';

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
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StatisticsScreen(profile: widget.profile)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showCustomizationPicker, 
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.profile.selectedBorder != 'none')
                            Image.asset(
                              'assets/borders/${widget.profile.selectedBorder}.png',
                              width: 90, 
                              height: 90,
                              fit: BoxFit.contain,
                            ),
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.background,
                            backgroundImage: AssetImage('assets/avatars/${widget.profile.avatar}.png'),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.profile.username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RankRoadScreen(profile: widget.profile)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.profile.rankName, style: const TextStyle(color: AppColors.lavender, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline_rounded, color: AppColors.lavender, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 28),
              ],
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Puan', _formatNumber(widget.profile.totalScore), Icons.star_rounded, Colors.amber),
                _buildStatColumn('Oynanan', '${widget.profile.gamesPlayed}', Icons.sports_esports_rounded, AppColors.accent),
                // YENİ: Seviye İlerlemesi yerine Rekor gösteriliyor
                _buildStatColumn('Tek Maç Rekoru', _formatNumber(widget.profile.highestSingleMatchScore), Icons.local_fire_department_rounded, Colors.deepOrange),
              ],
            ),

            // YENİ: XP ve Seviye Barı (Level Progress)
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('Seviye ${widget.profile.level}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Text(
                        '${widget.profile.currentLevelXp} / ${widget.profile.nextLevelXp} XP', 
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.profile.levelProgress,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}