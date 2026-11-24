import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart'; 
import '../models/user_profile.dart'; 
import '../screens/statistics_screen.dart';
import '../theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            AudioService.instance.playClick();
            Navigator.pop(context);
          }
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Global Sıralama', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalScore', descending: true) 
            .limit(50) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz oyuncu yok.', style: TextStyle(color: Colors.white54)));
          }

          final players = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final data = players[index].data() as Map<String, dynamic>;
              final String playerId = players[index].id;
              
              final bool isMe = playerId == currentUserId; 
              
              final String username = data['username'] ?? 'Bilinmeyen';
              final String avatar = data['avatar'] ?? 'boy';
              final String border = data['selectedBorder'] ?? 'none';
              final int score = data['totalScore'] ?? 0;
              final String rankName = data['rankName'] ?? 'Çaylak';

              Color? rankColor;
              IconData? rankIcon;
              if (index == 0) { rankColor = Colors.amber; rankIcon = Icons.military_tech_rounded; }
              else if (index == 1) { rankColor = const Color(0xFFC0C0C0); rankIcon = Icons.military_tech_rounded; }
              else if (index == 2) { rankColor = const Color(0xFFCD7F32); rankIcon = Icons.military_tech_rounded; }

              // YENİ: Başkasının profiline tıklayıp verilerini çekme sistemi
              return GestureDetector(
                onTap: () async {
                  AudioService.instance.playClick();
                  
                  // Veri çekerken minik bir yükleme göstergesi
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );

                  final UserProfile? targetProfile = await UserService.instance.getUserProfileById(playerId);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Yüklemeyi kapat
                    
                    if (targetProfile != null) {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => StatisticsScreen(profile: targetProfile))
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil detayları alınamadı.'), backgroundColor: Colors.orange));
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMe ? AppColors.primary : (rankColor?.withValues(alpha: 0.5) ?? Colors.white.withValues(alpha: 0.05)),
                      width: isMe || index < 3 ? 2 : 1,
                    ),
                    boxShadow: index < 3
                        ? [BoxShadow(color: rankColor!.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: index < 3
                              ? Icon(rankIcon, color: rankColor, size: 32)
                              : Text('#${index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (border != 'none')
                            Image.asset('assets/borders/$border.png', width: 58, height: 58, fit: BoxFit.contain),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.background,
                            backgroundImage: AssetImage('assets/avatars/$avatar.png'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: TextStyle(color: isMe ? AppColors.lavender : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(rankName, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}