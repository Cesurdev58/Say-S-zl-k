import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../widgets/game_background.dart';

class StatisticsScreen extends StatelessWidget {
  final UserProfile profile;

  const StatisticsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    int wPercent = profile.wordPercentage;
    int mPercent = profile.mathPercentage;

    // YENİ: Bu profil bana mı ait? (Bana aitse gizli olsa bile kendim görebilirim)
    final bool isMe = profile.uid == FirebaseAuth.instance.currentUser?.uid;
    // YENİ: Başkasının profiliyse VE gizliyse detayları sakla
    final bool isHidden = !isMe && profile.isStatsHidden;

    return GameBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text('Profil ve İstatistikler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- KULLANICI KARTI (AVATAR & ÇERÇEVE) ---
            Stack(
              alignment: Alignment.center,
              children: [
                // Z-Index çözüldü (Çerçeve altta, Avatar üstte)
                if (profile.selectedBorder != 'none')
                  Image.asset(
                    'assets/borders/${profile.selectedBorder}.png',
                    width: 115, 
                    height: 115,
                    fit: BoxFit.contain,
                  ),
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.background,
                  backgroundImage: AssetImage('assets/avatars/${profile.avatar}.png'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(profile.username, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(profile.rankName, style: const TextStyle(color: AppColors.lavender, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),

            // YENİ: GİZLİLİK KALKANI (Eğer hesap başkasına ait ve gizliyse burası çalışır)
            if (isHidden) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 80, color: Colors.white24),
                    const SizedBox(height: 24),
                    const Text('Gizli Profil', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      'Bu oyuncu istatistiklerini diğer oyunculara gizlemeyi tercih etmiş.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // EĞER GİZLİ DEĞİLSE İSTATİSTİKLER NORMAL ŞEKİLDE GÖSTERİLİR
              // --- ZEKA PROFİLİ VE GRAFİĞİ ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.surfaceGradientTop, AppColors.surfaceGradientBottom]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    const Text('Baskın Zeka Türü', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(profile.dominantIntelligence, style: const TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('%$wPercent Sözel', style: const TextStyle(color: AppColors.lavender, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('%$mPercent Sayısal', style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          if (wPercent > 0)
                            Expanded(
                              flex: wPercent,
                              child: Container(height: 12, color: AppColors.primary),
                            ),
                          if (mPercent > 0)
                            Expanded(
                              flex: mPercent,
                              child: Container(height: 12, color: AppColors.rose),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // --- GENEL BAKIŞ ---
              _buildSectionTitle('Genel Performans'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Oynanan', '${profile.gamesPlayed}', Icons.sports_esports_rounded, AppColors.accent)),
                  const SizedBox(width: 16),
                  // YENİ: TEK MAÇLIK REKOR KARTI EKLENDİ
                  Expanded(child: _buildStatCard('Tek Maçlık Rekor', '${profile.highestSingleMatchScore}', Icons.local_fire_department_rounded, Colors.deepOrange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Ortalama Puan', '${profile.averageScorePerGame}', Icons.bar_chart_rounded, Colors.amber)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Çözüm Hızı', '${profile.averageAnswerTime.toStringAsFixed(1)}s', Icons.bolt_rounded, Colors.yellowAccent)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Toplam Soru', '${profile.totalQuestionsSeen}', Icons.psychology_rounded, const Color(0xFF00B894))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Bugünkü Puan', '${profile.dailyScore}', Icons.today_rounded, AppColors.sky)),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- SÖZEL BÖLÜMÜ ---
              _buildSectionTitle('Sözel Zeka (Kelime)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('En Uzun', profile.longestWord.isEmpty ? '-' : profile.longestWord, Icons.text_fields_rounded, AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Başarı Oranı', '%${profile.wordSuccessRate.toStringAsFixed(1)}', Icons.check_circle_outline_rounded, AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Sözel Puan', '${profile.totalWordScore}', Icons.score_rounded, AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Pas Geçme', '%${profile.wordPassRate.toStringAsFixed(1)}', Icons.skip_next_rounded, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Görülen Soru', '${profile.wordQuestionsSeen}', Icons.visibility_rounded, AppColors.sky)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Doğru Cevap', '${profile.wordCorrectAnswers}', Icons.task_alt_rounded, AppColors.mint)),
                ],
              ),
              const SizedBox(height: 24),

              // --- SAYISAL BÖLÜMÜ ---
              _buildSectionTitle('Sayısal Zeka (İşlem)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Tam İsabet', '${profile.exactMathMatches}', Icons.calculate_rounded, AppColors.rose)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Başarı Oranı', '%${profile.mathSuccessRate.toStringAsFixed(1)}', Icons.check_circle_outline_rounded, AppColors.rose)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Sayısal Puan', '${profile.totalMathScore}', Icons.functions_rounded, AppColors.rose)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Pas Geçme', '%${profile.mathPassRate.toStringAsFixed(1)}', Icons.skip_next_rounded, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Görülen Soru', '${profile.mathQuestionsSeen}', Icons.visibility_rounded, AppColors.sky)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Doğru Cevap', '${profile.mathCorrectAnswers}', Icons.task_alt_rounded, AppColors.mint)),
                ],
              ),
              const SizedBox(height: 24),
            ]
          ],
        ),
      ),
    ));
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}