import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class RankRoadScreen extends StatelessWidget {
  final UserProfile profile;

  const RankRoadScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> ranks = [
      {'level': 0, 'name': 'Çaylak', 'score': 0, 'color': const Color(0xFFA0A0A0), 'height': 140.0, 'icon': Icons.egg_rounded},
      {'level': 1, 'name': 'Amatör', 'score': 500, 'color': const Color(0xFF55EFC4), 'height': 180.0, 'icon': Icons.skateboarding_rounded},
      {'level': 2, 'name': 'Yetenekli', 'score': 1500, 'color': const Color(0xFF74B9FF), 'height': 220.0, 'icon': Icons.color_lens_rounded},
      {'level': 3, 'name': 'Uzman', 'score': 3000, 'color': const Color(0xFFA78BFA), 'height': 260.0, 'icon': Icons.military_tech_rounded},
      {'level': 4, 'name': 'Usta', 'score': 6000, 'color': const Color(0xFFFF9F43), 'height': 300.0, 'icon': Icons.workspace_premium_rounded},
      {'level': 5, 'name': 'Deha', 'score': 12000, 'color': const Color(0xFF00CEC9), 'height': 340.0, 'icon': Icons.psychology_rounded},
    ];

    final int currentScore = profile.totalScore;
    final int currentLevel = profile.rankLevel;

    return Scaffold(
      backgroundColor: const Color(0xFF131127),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rütbe Yolu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2D2A59), Color(0xFF1A1836)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF7C5CFC).withValues(alpha: 0.15), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Toplam Zeka Puanı', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$currentScore', style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ranks[currentLevel]['color'].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ranks[currentLevel]['name'],
                    style: TextStyle(color: ranks[currentLevel]['color'], fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: ranks.length,
              itemBuilder: (context, index) {
                final rank = ranks[index];
                final bool isUnlocked = currentLevel >= index;
                final bool isCurrent = currentLevel == index;
                
                double progress = 0.0;
                String scoreText = '';

                if (isUnlocked && !isCurrent) {
                  progress = 1.0; 
                  scoreText = 'Tamamlandı';
                } else if (isCurrent) {
                  int nextScore = index < ranks.length - 1 ? ranks[index + 1]['score'] : currentScore;
                  int prevScore = rank['score'];
                  
                  if (nextScore > prevScore) {
                    progress = (currentScore - prevScore) / (nextScore - prevScore);
                    scoreText = '$currentScore / $nextScore'; // Kullanıcı anlık puanını görecek
                  } else {
                    progress = 1.0; 
                    scoreText = 'Maksimum Seviye';
                  }
                } else {
                  scoreText = 'Hedef: ${rank['score']}';
                }

                return Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end, 
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked ? rank['color'].withValues(alpha: 0.2) : const Color(0xFF1D1B36),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent ? rank['color'] : (isUnlocked ? rank['color'].withValues(alpha: 0.5) : Colors.white12),
                            width: isCurrent ? 3 : 1,
                          ),
                          boxShadow: isCurrent ? [BoxShadow(color: rank['color'].withValues(alpha: 0.3), blurRadius: 15)] : [],
                        ),
                        child: Icon(
                          isUnlocked ? rank['icon'] : Icons.lock_rounded, 
                          color: isUnlocked ? rank['color'] : Colors.white24, 
                          size: 32
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        rank['name'],
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                          fontSize: isCurrent ? 16 : 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      Text(
                        scoreText,
                        style: TextStyle(
                          color: isCurrent ? Colors.amber : (isUnlocked ? Colors.white70 : Colors.white24),
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: isCurrent ? 13 : 11,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 60,
                            height: rank['height'],
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1B36),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            width: 60,
                            height: rank['height'] * progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  rank['color'].withValues(alpha: 0.5),
                                  rank['color'],
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isCurrent ? [BoxShadow(color: rank['color'].withValues(alpha: 0.4), blurRadius: 10)] : [],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40), 
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}