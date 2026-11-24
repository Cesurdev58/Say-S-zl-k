import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/menu_button.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_bottom_sheet.dart';
import 'solo_mode_select_screen.dart'; 
import 'quests_screen.dart';
import 'store_screen.dart'; 
import 'leaderboard_screen.dart';
import 'matchmaking_screen.dart';
import 'friends_screen.dart';
import 'private_room_screen.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile = UserService.instance.cachedUser;
  
  bool _hasPendingRequests = false;
  StreamSubscription<QuerySnapshot>? _requestSub;
  StreamSubscription<QuerySnapshot>? _inviteSub;
  StreamSubscription<User?>? _authSub; 
  
  // YENİ: Cihaz çakışması dinleyicisi

  @override
  void initState() {
    super.initState();
    _checkPrivacyPolicy();
    
    if (_profile != null) {
      _listenForFriendRequests();
      _listenForRoomInvites();
    }
    
    _setupProfileListener(); 
  }

  void _setupProfileListener() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _requestSub?.cancel();
        _inviteSub?.cancel();
        _requestSub = null;
        _inviteSub = null;
        if (mounted) setState(() => _hasPendingRequests = false);
      } else if (mounted) {
        await _loadProfile();
      }
    });
  }

  Future<void> _checkPrivacyPolicy() async {
    final isAccepted = await SecureStorageService.instance.readData('privacyAccepted');
    if (isAccepted != 'true' && mounted) {
      _showPrivacyPolicyDialog();
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: AppColors.accent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kullanıcı Sözleşmesi ve Gizlilik Politikası',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: const Text(
                      'SayıSözlük oyununa hoş geldiniz!\n\n'
                      'Bu uygulama, Türkiye Cumhuriyeti Kişisel Verilerin Korunması Kanunu (KVKK) '
                      've uluslararası standartlara uygun olarak tasarlanmıştır.\n\n'
                      '1. Toplanan Veriler:\n'
                      'Oyun deneyiminizi sunabilmek için oyun içi skorlarınız, başarımlarınız, seçtiğiniz kullanıcı adınız ve (eğer bağlarsanız) e-posta adresiniz kaydedilir.\n\n'
                      '2. Veri Güvenliği ve 3. Partiler:\n'
                      'Verileriniz Google Firebase sunucularında şifrelenerek güvenle saklanır. Uygulama içi hataları tespit etmek için Firebase Crashlytics ve size uygun içerikler sunmak için Google AdMob reklam servisleri kullanılmaktadır.\n\n'
                      '3. Hesabı Silme:\n'
                      'Verilerinizin kontrolü tamamen sizdedir. İstediğiniz zaman "Ayarlar" menüsündeki "Hesabımı Sil" butonu ile tüm bilgilerinizi sunucularımızdan kalıcı ve geri döndürülemez şekilde silebilirsiniz.\n\n'
                      'SayıSözlük, cihazınızın kamerasına, rehberine, galerisine veya konumuna ASLA erişim talep etmez.\n\n'
                      'Oyunu oynamaya devam ederek bu şartları kabul etmiş sayılırsınız.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          AudioService.instance.playClick();
                          if (Platform.isAndroid) {
                            SystemNavigator.pop();
                          } else {
                            exit(0);
                          }
                        },
                        child: const Text('Reddet ve Çık', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          AudioService.instance.playClick();
                          await SecureStorageService.instance.writeData('privacyAccepted', 'true');
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text('Kabul Ediyorum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.instance.getCurrentUser().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException("UserService yanıt vermedi"),
      );

      if (mounted) {
        setState(() {
          _profile = profile;
        });
        _listenForFriendRequests();
        _listenForRoomInvites();
      }
    } catch (e) {
      debugPrint("Profil yükleme hatası: $e");
    }
  }

  void _listenForFriendRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _requestSub?.cancel(); 
      _requestSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('friendRequests')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _hasPendingRequests = snapshot.docs.isNotEmpty;
          });
        }
      }, onError: (error) {
        debugPrint("Friend Request Stream Error: $error");
      });
    }
  }

  void _listenForRoomInvites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _inviteSub?.cancel(); 
      _inviteSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('room_invites')
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final docId = change.doc.id;
            final hostName = data['hostName'] ?? 'Bir arkadaşın';
            final roomCode = data['roomCode'];

            if (mounted && roomCode != null) {
              _showInviteDialog(docId, hostName, roomCode);
            }
          }
        }
      }, onError: (error) {
        debugPrint("Room Invite Stream Error: $error");
      });
    }
  }

  void _showInviteDialog(String docId, String hostName, String roomCode) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    AudioService.instance.playSuccess(); 
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Oda Daveti!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${hostName.toUpperCase()} seni $roomCode kodlu özel odaya davet ediyor. Katılmak ister misin?', 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playClick();
              FirebaseFirestore.instance.collection('users').doc(user.uid).collection('room_invites').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text('Reddet', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AudioService.instance.playClick();
              FirebaseFirestore.instance.collection('users').doc(user.uid).collection('room_invites').doc(docId).delete();
              Navigator.pop(context); 
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivateRoomScreen(initialRoomCode: roomCode),
                ),
              );
            },
            child: const Text('Katıl', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel(); 
    _requestSub?.cancel();
    _inviteSub?.cancel(); 
    super.dispose();
  }

  bool _hasUnclaimedRewards() {
    if (_profile == null) return false;
    
    final allQuests = [
      {'id': 'dq_play_3', 'goal': 3},
      {'id': 'dq_score_200', 'goal': 200},
      {'id': 'dq_math_exact_1', 'goal': 1},
      {'id': 'dq_word_see_10', 'goal': 10},
      {'id': 'q_play_50', 'goal': 50},
      {'id': 'q_play_250', 'goal': 250},
      {'id': 'q_play_1000', 'goal': 1000},
      {'id': 'q_score_3000', 'goal': 3000},
      {'id': 'q_score_10000', 'goal': 10000},
      {'id': 'q_score_50000', 'goal': 50000},
      {'id': 'q_word_len_7', 'goal': 7},
      {'id': 'q_word_len_8', 'goal': 8}, 
      {'id': 'q_math_exact_25', 'goal': 25},
      {'id': 'q_math_exact_100', 'goal': 100},
      {'id': 'q_word_correct_100', 'goal': 100},
      {'id': 'q_math_correct_100', 'goal': 100},
      {'id': 'q_rank_5', 'goal': 12000},
    ];

    for (var q in allQuests) {
      if (!_profile!.claimedQuests.contains(q['id'])) {
        int progress = _getProgress(q['id'].toString());
        if (progress >= (q['goal'] as int)) return true; 
      }
    }
    return false;
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

  void _showHowToPlayBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('SayıSözlük Akademisi', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Kurallar ve Zeka Puanı Sistemi', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRuleCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Temel Amaç',
                    content: 'Sözel aşamada harfleri birleştirerek en uzun ve geçerli kelimeyi bul. Sayısal aşamada ise 6 sayıyı kullanarak (4 işlemle) ortadaki hedef sayıya en fazla 10 sayı yaklaş.',
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  _buildRuleCard(
                    icon: Icons.timer_off_rounded,
                    title: 'Süre ve Pas Cezaları',
                    content: 'Pas geçmek süreni eksiltir ve oyun sonu zeka puanından ciddi eksi yazar. 5 saniyenin altına düştüğünde kırmızı nabız başlar, adrenalin yükselir!',
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  _buildRuleCard(
                    icon: Icons.psychology_rounded,
                    title: 'Zeka Profili Nasıl Hesaplanır?',
                    content: 'Baskın Zeka Türü rastgele verilmez. Arkasında acımasız bir paradigma vardır:\n\n'
                             '**Ham Güç = (Başarı % x 0.65) - (Pas % x 0.35) + Hız Bonusu**\n\n'
                             'Çözüm süren 25 saniyenin ne kadar altındaysa hız bonusun o kadar artar.',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildRuleCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Güvenilirlik Katsayısı (Baraj)',
                    content: 'Sistemi 1-2 soru çözerek kandıramazsın. Gerçek Zeka Puanının görünmesi için en az 25 soru çözmüş olmalısın.',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({required IconData icon, required String title, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMultiplayerUnlocked = _profile != null && _profile!.totalScore >= 500;

    return Scaffold(
      backgroundColor: AppColors.gradientBottom, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientTop,
              AppColors.gradientMid,
              AppColors.gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false, 
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 28),
                
                _profile == null
                    ? Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      )
                    : ProfileCard(
                        profile: _profile!,
                        onProfileUpdated: _loadProfile,
                      ),
                      
                const SizedBox(height: 32),
                Text(
                  'Oyun Modları',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 16),
                
                MenuButton(
                  label: 'Çok Oyunculu Yarış',
                  subtitle: isMultiplayerUnlocked ? 'Dünyadan rakiplerle zamana karşı yarış' : 'Kilidi açmak için Solo modda 500 puana ulaş',
                  icon: isMultiplayerUnlocked ? Icons.public_rounded : Icons.lock_rounded,
                  isPrimary: isMultiplayerUnlocked,
                  onTap: () async {
                    if (!isMultiplayerUnlocked) {
                      AudioService.instance.playError();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce Solo modda pratik yapıp 500 puana ulaşmalısın!'), backgroundColor: Colors.orange));
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatchmakingScreen(),
                      ),
                    );
                    _loadProfile(); 
                  },
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Oda Kur / Katıl',
                  subtitle: 'Arkadaşlarınla özel oda oluştur',
                  icon: Icons.meeting_room_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivateRoomScreen(),
                      ),
                    );
                    _loadProfile();
                  },
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Alıştırma / Solo',
                  subtitle: 'Tek başına pratik yap, seviye atla',
                  icon: Icons.psychology_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SoloModeSelectScreen(),
                      ),
                    );
                    _loadProfile(); 
                  },
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Mağaza (Market)',
                  subtitle: 'Cevher harca, profilini özelleştir',
                  icon: Icons.storefront_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StoreScreen(),
                      ),
                    );
                    _loadProfile(); 
                  },
                ),
                const SizedBox(height: 12),
                MenuButton(
                  label: 'Nasıl Oynanır?',
                  subtitle: 'Oyun kuralları ve puanlama sistemi',
                  icon: Icons.menu_book_rounded,
                  onTap: () => _showHowToPlayBottomSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 90, 
          fit: BoxFit.contain,
        ),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FriendsScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.people_alt_rounded, color: Colors.white.withValues(alpha: 0.9), size: 28),
                    ),
                    if (_hasPendingRequests)
                      Positioned(
                        top: 6, right: 6, 
                        child: Container(
                          width: 12, height: 12, 
                          decoration: BoxDecoration(
                            color: Colors.redAccent, 
                            shape: BoxShape.circle, 
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    );
                    _loadProfile();
                  },
                  icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const QuestsScreen(),
                          ),
                        );
                        _loadProfile();
                      },
                      icon: Icon(Icons.track_changes_rounded, color: Colors.white.withValues(alpha: 0.9), size: 28),
                    ),
                    if (_hasUnclaimedRewards())
                      Positioned(
                        top: 6, left: 6, 
                        child: Container(
                          width: 12, height: 12, 
                          decoration: BoxDecoration(
                            color: Colors.redAccent, 
                            shape: BoxShape.circle, 
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond_rounded, color: AppColors.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_profile?.gems ?? 0}', 
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showSettingsBottomSheet(context, _loadProfile),
                  icon: Icon(Icons.settings_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}