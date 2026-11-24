import 'package:flutter/material.dart';

import '../widgets/game_intro_dialog.dart'; // Bilgilendirme ve Geri Sayım Pop-up'ı
import 'game_screen.dart'; // Oyun Ekranı
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/game_card.dart';
import '../widgets/ui/game_tile.dart';
import '../widgets/game_background.dart';

class SoloModeSelectScreen extends StatefulWidget {
  const SoloModeSelectScreen({super.key});

  @override
  State<SoloModeSelectScreen> createState() => _SoloModeSelectScreenState();
}

class _SoloModeSelectScreenState extends State<SoloModeSelectScreen> {
  // Seçilen Ana Mod: true -> Zamana Karşı, false -> Sonsuz Macera
  bool isTimedMode = true;

  @override
  Widget build(BuildContext context) {
    return GameBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solo Mod Seçimi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oyun Tarzını Seç',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMainModeCard(
                      title: 'Zamana Karşı',
                      subtitle: 'Arcade & Hızlı',
                      icon: Icons.timer_outlined,
                      isSelected: isTimedMode,
                      onTap: () => setState(() => isTimedMode = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainModeCard(
                      title: 'Sonsuz Macera',
                      subtitle: 'Stressiz & Serbest',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: !isTimedMode,
                      onTap: () => setState(() => isTimedMode = false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                isTimedMode ? '⏳ Zamana Karşı Kategorini Seç' : '♾️ Sonsuz Macera Kategorini Seç',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isTablet = constraints.maxWidth > 600;

                    if (isTablet) {
                      return GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSubModeCard(
                            title: 'Bir Kelime',
                            description: isTimedMode
                                ? 'Harflerle kelime türet, doğru kelimelerle ek saniye kazan ve serini sürdür!'
                                : 'Süre kısıtı olmadan en uzun Türkçe kelimeleri türet.',
                            icon: Icons.text_fields_rounded,
                            iconBgColor: AppColors.primaryAlt,
                            onTap: () => _navigateToGame(context, subMode: 'word'),
                          ),
                          _buildSubModeCard(
                            title: 'Bir İşlem',
                            description: isTimedMode
                                ? 'Hedefi tam bul (+5s) ve artan sayılarla dev süre bonusu kap!'
                                : 'Rastgele sayılarla işlem yap, pratik matematik zekanı geliştir.',
                            icon: Icons.calculate_outlined,
                            iconBgColor: AppColors.accent,
                            onTap: () => _navigateToGame(context, subMode: 'math'),
                          ),
                          _buildSubModeCard(
                            title: 'Bir Kelime Bir İşlem',
                            description: isTimedMode
                                ? 'Klasik Karma! Doğru cevaplarla süreni uzat ve 40 saniyeyle sınırları zorla.'
                                : 'Hem sözel hem sayısal turlarla kesintisiz antrenman yap.',
                            icon: Icons.sports_esports_outlined,
                            iconBgColor: AppColors.rose,
                            onTap: () => _navigateToGame(context, subMode: 'mix'),
                          ),
                        ],
                      );
                    } else {
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSubModeCard(
                            title: 'Bir Kelime',
                            description: isTimedMode
                                ? 'Harflerle kelime türet, doğru kelimelerle ek saniye kazan ve serini sürdür!'
                                : 'Süre kısıtı olmadan en uzun Türkçe kelimeleri türet.',
                            icon: Icons.text_fields_rounded,
                            iconBgColor: AppColors.primaryAlt,
                            onTap: () => _navigateToGame(context, subMode: 'word'),
                          ),
                          const SizedBox(height: 12),
                          _buildSubModeCard(
                            title: 'Bir İşlem',
                            description: isTimedMode
                                ? 'Hedefi tam bul (+5s) ve artan sayılarla dev süre bonusu kap!'
                                : 'Rastgele sayılarla işlem yap, pratik matematik zekanı geliştir.',
                            icon: Icons.calculate_outlined,
                            iconBgColor: AppColors.accent,
                            onTap: () => _navigateToGame(context, subMode: 'math'),
                          ),
                          const SizedBox(height: 12),
                          _buildSubModeCard(
                            title: 'Bir Kelime Bir İşlem',
                            description: isTimedMode
                                ? 'Klasik Karma! Doğru cevaplarla süreni uzat ve 40 saniyeyle sınırları zorla.'
                                : 'Hem sözel hem sayısal turlarla kesintisiz antrenman yap.',
                            icon: Icons.sports_esports_outlined,
                            iconBgColor: AppColors.rose,
                            onTap: () => _navigateToGame(context, subMode: 'mix'),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildMainModeCard({required String title, required String subtitle, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GameTile(
        duration: const Duration(milliseconds: 200),
        radius: AppRadius.lg,
        flat: !isSelected,
        color: isSelected ? AppColors.primaryDeep : AppColors.surfaceHigh,
        borderColor: isSelected ? AppColors.primaryBright : Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.38), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubModeCard({required String title, required String description, required IconData icon, required Color iconBgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GameCard(
        radius: 20,
        color: AppColors.surfaceHigh,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: iconBgColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconBgColor, size: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, {required String subMode}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameIntroDialog(
        isTimed: isTimedMode,
        subMode: subMode,
        onStartGame: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                isTimed: isTimedMode,
                subMode: subMode,
              ),
            ),
          );
        },
      ),
    );
  }
}