import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  UserProfile? _profile;
  late ConfettiController _confettiController;
  bool _isClaiming = false;

  final List<Map<String, dynamic>> _dailyQuests = [
    {'id': 'dq_play_3', 'title': 'Antrenman Şart', 'desc': '3 Oyun Oyna', 'goal': 3, 'reward': 15, 'icon': Icons.sports_gymnastics_rounded, 'color': const Color(0xFF00CEC9)},
    {'id': 'dq_score_200', 'title': 'Günün Skoru', 'desc': '200 Puan Topla', 'goal': 200, 'reward': 25, 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF9F43)},
    {'id': 'dq_math_exact_1', 'title': 'Zihin Açıcı', 'desc': 'Sayısalda 1 Kez Tam İsabet Yap', 'goal': 1, 'reward': 20, 'icon': Icons.calculate_rounded, 'color': const Color(0xFFFD79A8)},
    {'id': 'dq_word_see_10', 'title': 'Kelime Avcısı', 'desc': '10 Adet Sözel Soru Gör', 'goal': 10, 'reward': 15, 'icon': Icons.text_fields_rounded, 'color': const Color(0xFF7C5CFC)},
  ];

  final List<Map<String, dynamic>> _achievements = [
    {'id': 'q_play_50', 'title': 'Müdavim I', 'desc': 'Toplam 50 Oyun Oyna', 'goal': 50, 'reward': 100, 'icon': Icons.all_inclusive_rounded, 'color': const Color(0xFF00CEC9)},
    {'id': 'q_play_250', 'title': 'Müdavim II', 'desc': 'Toplam 250 Oyun Oyna', 'goal': 250, 'reward': 500, 'icon': Icons.all_inclusive_rounded, 'color': const Color(0xFF00CEC9)},
    {'id': 'q_play_1000', 'title': 'Efsanevi Müdavim', 'desc': 'Toplam 1000 Oyun Oyna', 'goal': 1000, 'reward': 2000, 'icon': Icons.all_inclusive_rounded, 'color': const Color(0xFF00CEC9)},
    {'id': 'q_score_3000', 'title': 'Puan Avcısı I', 'desc': 'Toplam 3000 Puana Ulaş', 'goal': 3000, 'reward': 200, 'icon': Icons.military_tech_rounded, 'color': Colors.amber},
    {'id': 'q_score_10000', 'title': 'Puan Avcısı II', 'desc': 'Toplam 10.000 Puana Ulaş', 'goal': 10000, 'reward': 1000, 'icon': Icons.military_tech_rounded, 'color': Colors.amber},
    {'id': 'q_score_50000', 'title': 'Yenilmez Puan', 'desc': 'Toplam 50.000 Puana Ulaş', 'goal': 50000, 'reward': 5000, 'icon': Icons.military_tech_rounded, 'color': Colors.amber},
    {'id': 'q_word_len_7', 'title': 'Sözlük Yazarı I', 'desc': '7 Harfli Kelime Bul', 'goal': 7, 'reward': 150, 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF7C5CFC)},
    {'id': 'q_word_len_8', 'title': 'Edebiyatçı', 'desc': '8 Harfli Kelime Bul', 'goal': 8, 'reward': 500, 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF7C5CFC)},
    {'id': 'q_word_correct_100', 'title': 'Kelime Uzmanı', 'desc': '100 Doğru Kelime Bul', 'goal': 100, 'reward': 300, 'icon': Icons.spellcheck_rounded, 'color': const Color(0xFF7C5CFC)},
    {'id': 'q_math_exact_25', 'title': 'Hesap Makinesi I', 'desc': '25 Kez Tam İsabet Yap', 'goal': 25, 'reward': 250, 'icon': Icons.functions_rounded, 'color': const Color(0xFFFD79A8)},
    {'id': 'q_math_exact_100', 'title': 'Hesap Makinesi II', 'desc': '100 Kez Tam İsabet Yap', 'goal': 100, 'reward': 1000, 'icon': Icons.functions_rounded, 'color': const Color(0xFFFD79A8)},
    {'id': 'q_math_correct_100', 'title': 'Sayısal Zeka', 'desc': '100 Doğru İşlem Çöz', 'goal': 100, 'reward': 300, 'icon': Icons.onetwothree_rounded, 'color': const Color(0xFFFD79A8)},
    {'id': 'q_rank_5', 'title': 'Akademi Birincisi', 'desc': 'Deha Rütbesine Ulaş (12.000 Puan)', 'goal': 12000, 'reward': 1000, 'icon': Icons.psychology_alt_rounded, 'color': const Color(0xFF55EFC4)},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadProfile();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.instance.getCurrentUser();
    if (mounted) setState(() => _profile = profile);
  }

  int _getProgress(String id) {
    if (_profile == null) return 0;
    if (id == 'dq_play_3') return _profile!.dailyGamesPlayed;
    if (id == 'dq_score_200') return _profile!.dailyScore;
    if (id == 'dq_math_exact_1') return _profile!.dailyExactMathMatches;
    if (id == 'dq_word_see_10') return _profile!.dailyWordQuestionsSeen;
    if (id.startsWith('q_play')) return _profile!.gamesPlayed;
    if (id.startsWith('q_score')) return _profile!.totalScore;
    if (id.startsWith('q_word_len')) return _profile!.longestWord.length;
    if (id.startsWith('q_math_exact')) return _profile!.exactMathMatches;
    if (id.startsWith('q_word_correct')) return _profile!.wordCorrectAnswers;
    if (id.startsWith('q_math_correct')) return _profile!.mathCorrectAnswers;
    if (id.startsWith('q_rank')) return _profile!.totalScore;
    return 0;
  }

  Future<void> _claimReward(String questId, int rewardAmount) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final bool success = await UserService.instance.claimQuestReward(questId);
      if (!mounted) return;

      if (success) {
        AudioService.instance.playSuccess();
        _confettiController.play();
        await _loadProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tebrikler! $rewardAmount Cevher kazandın.'),
            backgroundColor: const Color(0xFF00CEC9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        AudioService.instance.playError();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödül alınamadı veya daha önce alınmış.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Görevler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00CEC9),
            indicatorWeight: 3,
            labelColor: Color(0xFF00CEC9),
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Günlük Görevler'),
              Tab(text: 'Başarımlar'),
            ],
          ),
        ),
        body: _profile == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFC)))
            : Stack(
                children: [
                  TabBarView(
                    children: [
                      _buildQuestList(_dailyQuests),
                      _buildQuestList(_achievements),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      maxBlastForce: 20,
                      minBlastForce: 8,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.1,
                      colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestList(List<Map<String, dynamic>> questList) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questList.length,
      itemBuilder: (context, index) {
        final quest = questList[index];
        final String id = quest['id'];
        final int goal = quest['goal'];
        final int reward = quest['reward'];
        final Color color = quest['color'];

        int currentProgress = _getProgress(id);
        if (currentProgress > goal) currentProgress = goal;

        final bool isCompleted = currentProgress >= goal;
        final bool isClaimed = _profile!.claimedQuests.contains(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCompleted && !isClaimed ? color : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: Icon(quest['icon'], color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quest['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(quest['desc'], style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Text('+$reward', style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 4),
                        const Icon(Icons.diamond_rounded, color: Color(0xFF00CEC9), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$currentProgress / $goal', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: currentProgress / goal,
                            backgroundColor: const Color(0xFF131127),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (isClaimed)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00CEC9), size: 32)
                  else if (isCompleted)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _isClaiming ? null : () => _claimReward(id, reward),
                      child: const Text('Ödülü Al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  else
                    const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}