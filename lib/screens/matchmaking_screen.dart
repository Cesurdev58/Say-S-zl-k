import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_service.dart';
import '../services/audio_service.dart';
import 'multiplayer_game_screen.dart';
import '../theme/app_colors.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with SingleTickerProviderStateMixin {
  String? _activeMatchId;
  bool _isSearching = true;
  bool _isStartingMatch = false;
  int _searchGeneration = 0;

  StreamSubscription<DocumentSnapshot>? _matchSubscription;
  Timer? _countdownTimer;

  late AnimationController _radarController;

  Map<String, dynamic> _players = {};
  bool _isHost = false;
  int _remainingSeconds = 20;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    AudioService.instance.playClick();
    final int currentGen = ++_searchGeneration;

    String? matchId = await MatchService.instance.findOrCreateMatch();

    // Kullanıcı arama tamamlanmadan ekrandan çıktıysa veya iptal ettiyse (Ghost Room Önleme)
    if (!mounted || !_isSearching || currentGen != _searchGeneration) {
      if (matchId != null) {
        await MatchService.instance.cancelMatchmaking(matchId);
      }
      return;
    }

    if (matchId != null) {
      setState(() => _activeMatchId = matchId);
      _listenToMatchStatus(matchId);
    } else {
      _cancelAndGoHome('Eşleşme sunucusuna bağlanılamadı.');
    }
  }

  void _listenToMatchStatus(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !_isSearching) return;

      if (!snapshot.exists) {
        _cancelAndGoHome('Arama süresi doldu veya oda kapatıldı.');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        _players = Map<String, dynamic>.from(data['players'] ?? {});
        _isHost = currentUid != null && data['hostUid'] == currentUid;
      });

      if (data['status'] == 'playing') {
        _stopAndNavigate(matchId);
        return;
      }

      // Oda 6 kişiye ulaştıysa süreyi beklemeden Host hemen başlatsın
      if (_isHost && data['status'] == 'waiting' && _players.length >= 6 && !_isStartingMatch) {
        _isStartingMatch = true;
        MatchService.instance.startMatch(matchId);
        return;
      }

      if (data['searchEndTime'] != null && _countdownTimer == null) {
        _startCountdown(data['searchEndTime']);
      }
    });
  }

  void _startCountdown(int endTimeMs) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isSearching) {
        timer.cancel();
        return;
      }

      int now = DateTime.now().millisecondsSinceEpoch;
      int rem = ((endTimeMs - now) / 1000).round();

      if (rem <= 0) {
        rem = 0;
        timer.cancel();

        if (_isHost && _activeMatchId != null) {
          if (_players.length >= 2) {
            if (!_isStartingMatch) {
              _isStartingMatch = true;
              MatchService.instance.startMatch(_activeMatchId!);
            }
          } else {
            _cancelAndGoHome('Yeterli rakip bulunamadı.');
          }
        }
      }

      if (mounted) setState(() => _remainingSeconds = rem);
    });
  }

  void _stopAndNavigate(String matchId) {
    if (!_isSearching) return;
    _isSearching = false;
    _searchGeneration++;
    _radarController.stop();
    _matchSubscription?.cancel();
    _countdownTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MultiplayerGameScreen(matchId: matchId)),
    );
  }

  void _cancelAndGoHome([String? message]) {
    if (!_isSearching && _activeMatchId == null) return;
    _isSearching = false;
    _searchGeneration++;
    _radarController.stop();
    _matchSubscription?.cancel();
    _countdownTimer?.cancel();

    final String? matchToCancel = _activeMatchId;
    _activeMatchId = null;

    if (matchToCancel != null) {
      MatchService.instance.cancelMatchmaking(matchToCancel);
    }

    if (mounted) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _searchGeneration++;
    _radarController.dispose();
    _matchSubscription?.cancel();
    _countdownTimer?.cancel();
    if (_activeMatchId != null && _isSearching) {
      final String matchToCancel = _activeMatchId!;
      _activeMatchId = null;
      MatchService.instance.cancelMatchmaking(matchToCancel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            AudioService.instance.playClick();
            _cancelAndGoHome();
          },
        ),
        title: const Text('Çok Oyunculu Yarış', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _radarController,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent]),
                ),
                child: const Center(child: Icon(Icons.radar_rounded, color: AppColors.primary, size: 64)),
              ),
            ),
            const SizedBox(height: 32),
            Text('Kalan Süre: $_remainingSeconds', style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Rakipler Bekleniyor... (${_players.length}/6)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: List.generate(6, (index) {
                  if (index < _players.length) {
                    String uid = _players.keys.elementAt(index);
                    String name = (_players[uid]?['name'] ?? 'Oyuncu').toString();
                    bool isMe = uid == myUid;
                    return Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: isMe ? AppColors.accent : AppColors.primary,
                          radius: 24,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 60,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isMe ? AppColors.accent : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          radius: 24,
                          child: const Icon(Icons.person, color: Colors.white24),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(
                          width: 60,
                          child: Text(
                            'BOŞ',
                            style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 50),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                AudioService.instance.playClick();
                _cancelAndGoHome();
              },
              child: const Text('Aramayı İptal Et', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}