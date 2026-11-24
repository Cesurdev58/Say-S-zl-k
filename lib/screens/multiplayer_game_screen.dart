import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import '../services/score_calculator.dart';
import '../services/word_service.dart';
import '../services/number_solver_service.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import '../services/ad_service.dart';
import '../services/match_service.dart';
import '../widgets/joker_picker_dialog.dart';
import '../widgets/timer_chip.dart';
import 'private_room_screen.dart';
import 'matchmaking_screen.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String matchId;

  const MultiplayerGameScreen({super.key, required this.matchId});

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription<DocumentSnapshot>? _matchSubscription;

  bool isHost = false;
  bool isPrivate = false;
  bool isGameOver = false;
  bool _isSubmittingAnswer = false;
  bool _isResolvingSolution = false;
  Future<List<String>>? _mathStepsFuture;
  int searchEndTime = 0;
  String? currentRoomCode;

  Map<String, dynamic> _players = {};

  Set<String> _friendUids = {};
  Set<String> _pendingRequestUids = {};

  bool _settingsLoaded = false;
  String matchMode = 'mix';
  // Kalan süre ValueNotifier'da tutulur; saniyelik tikler tüm ekranı rebuild etmez.
  final ValueNotifier<int> _remainingNotifier = ValueNotifier<int>(120);
  int get remainingSeconds => _remainingNotifier.value;
  set remainingSeconds(int v) => _remainingNotifier.value = v;
  int remainingPasses = 3;

  Timer? gameTimer;
  Timer? matchmakingTimer;

  List<Map<String, dynamic>> missedSolutions = [];
  List<Map<String, dynamic>> matchQuestions = [];
  int myQuestionIndex = 0;
  String currentRoundType = 'loading';

  List<String> availableLetters = [];
  List<int> selectedIndices = [];
  List<String> selectedLetters = [];

  List<int> originalNumbers = [];
  List<int> currentNumbers = [];
  int targetNumber = 0;
  List<String> historySteps = [];
  List<List<int>> previousNumbersHistory = [];
  int? firstNumIndex;
  int? firstNumValue;
  String? selectedOp;


  late ConfettiController _confettiController;
  late AnimationController _pulseController;

  String _praiseText = "";
  double _praiseBottom = 0;
  double _praiseOpacity = 0.0;

  int _lastMessageTime = 0;
  String? _floatingEmojiText;
  String? _floatingEmojiSenderName;
  Timer? _emojiTimer;
  double _emojiOpacity = 0.0;

  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    UserService.instance.updateUserStatus('oyunda');

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _praiseBottom = 250;

    _loadMyFriendsAndRequests();
    _initMatchSync();
  }

  void _loadMyFriendsAndRequests() async {
    try {
      final friendsSnapshot = await _firestore.collection('users').doc(myUid).collection('friends').get();
      if (mounted) {
        setState(() {
          _friendUids = friendsSnapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      debugPrint("Arkadaş listesi yüklenemedi: $e");
    }
  }

  Future<bool> _onWillPop() async {
    if (isGameOver) return true;

    bool? exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        title: const Text('Pes mi Ediyorsun?', style: TextStyle(color: Colors.white)),
        content: const Text('Oyundan çıkarsanız yenilmiş sayılacaksınız. Emin misiniz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır, Devam Et', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              MatchService.instance.cancelMatchmaking(widget.matchId);
              Navigator.of(context).pop(true);
            },
            child: const Text('Çık', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  void _sendEmoji(String text) {
    AudioService.instance.playClick();
    _firestore.collection('matches').doc(widget.matchId).update({
      'lastMessage': {
        'uid': myUid,
        'text': text,
        'time': DateTime.now().millisecondsSinceEpoch,
      }
    }).catchError((_) {});
    Navigator.pop(context);
  }

  void _showFloatingEmoji(String senderName, String text) {
    _emojiTimer?.cancel();
    if (mounted) {
      setState(() {
        _floatingEmojiSenderName = senderName;
        _floatingEmojiText = text;
        _emojiOpacity = 1.0;
      });
      _emojiTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _emojiOpacity = 0.0);
      });
    }
  }

  void _showChatPanel() {
    if (_isDialogShowing || isGameOver || remainingSeconds <= 0) return;
    _isDialogShowing = true;
    AudioService.instance.playClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1D1B36),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Hızlı Mesaj', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: ['🤯', '😂', '😡', '⏳', '👏', '🎯', '😅', '🥶']
                  .map((e) => InkWell(
                        onTap: () => _sendEmoji(e),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(16)),
                          child: Text(e, style: const TextStyle(fontSize: 28)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['Tebrikler!', 'Çok Hızlısın!', 'Zor Soru!', 'Zaman Daralıyor!', 'Pas!']
                  .map((text) => InkWell(
                        onTap: () => _sendEmoji(text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF7C5CFC).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.5))),
                          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _showPraiseAnimation() {
    final random = Random();
    final words = ['MÜKEMMEL!', 'HARİKA!', 'ZEKİCE!', 'EFSANE!', 'ZAFER!'];

    setState(() {
      _praiseText = words[random.nextInt(words.length)];
      _praiseBottom = MediaQuery.of(context).size.height * 0.4;
      _praiseOpacity = 0.0;
    });

    Future.microtask(() {
      if (mounted) {
        setState(() {
          _praiseBottom = MediaQuery.of(context).size.height * 0.6;
          _praiseOpacity = 1.0;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _praiseOpacity = 0.0;
          _praiseBottom = MediaQuery.of(context).size.height * 0.65;
        });
      }
    });
  }

  void _initMatchSync() {
    _matchSubscription?.cancel();
    _matchSubscription = _firestore.collection('matches').doc(widget.matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        if (mounted && !isGameOver) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1D1B36),
              title: const Text('Maç İptal Edildi', style: TextStyle(color: Colors.white)),
              content: const Text('Yeterli oyuncu bulunamadı veya oda kapatıldı.', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Ana Menü', style: TextStyle(color: Color(0xFF00CEC9))),
                )
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        isHost = data['hostUid'] == myUid;
        isPrivate = data['isPrivate'] ?? false;
        searchEndTime = data['searchEndTime'] ?? 0;
        currentRoomCode = data['roomCode'];
        _players = Map<String, dynamic>.from(data['players'] ?? {});
        matchMode = data['gameMode'] ?? 'mix';

        if (!_settingsLoaded && !isGameOver) {
          _settingsLoaded = true;
          remainingSeconds = data['timeLimit'] ?? 120;
          remainingPasses = data['passLimit'] ?? 3;
        }
      });

      if (data.containsKey('lastMessage') && data['lastMessage'] is Map) {
        final msg = data['lastMessage'] as Map;
        final int msgTime = msg['time'] ?? 0;
        if (msgTime > _lastMessageTime) {
          _lastMessageTime = msgTime;
          final senderUid = msg['uid'];
          final text = msg['text']?.toString() ?? '';
          final senderName = _players[senderUid]?['name']?.toString() ?? 'Biri';
          _showFloatingEmoji(senderName, text);
        }
      }

      if (data['status'] == 'finished' && !isGameOver) {
        _triggerLocalGameOver();
        return;
      }

      if (isHost && data['status'] == 'waiting') {
        if (_players.length >= 6) {
          _startMatchAutomatically();
        } else if (!isPrivate && searchEndTime > 0 && matchmakingTimer == null) {
          _startMatchmakingTimer();
        }
      }

      if (data['status'] == 'playing') {
        matchmakingTimer?.cancel();

        if (data.containsKey('gameData') && matchQuestions.isEmpty) {
          matchQuestions = List<Map<String, dynamic>>.from(data['gameData']['rounds']);
          _loadCurrentQuestion();
        }

        if (isHost && !data.containsKey('endTime')) {
          _firestore.collection('matches').doc(widget.matchId).update({
            'endTime': DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000),
          }).catchError((_) {});
        }

        if (data.containsKey('endTime') && gameTimer == null) {
          _startGlobalTimer(data['endTime']);
        }
      }
    });
  }

  Future<void> _triggerLocalGameOver() async {
    if (isGameOver) return;
    isGameOver = true;
    gameTimer?.cancel();
    _pulseController.stop();

    if (currentRoundType != 'done') {
      await _recordCurrentSolution();
    }

    if (_isDialogShowing && mounted) {
      Navigator.of(context).pop();
      _isDialogShowing = false;
    }

    if (mounted) {
      setState(() {
        remainingSeconds = 0;
      });
      _showGameOverDialog();
    }
  }

  void _startMatchAutomatically() {
    matchmakingTimer?.cancel();
    MatchService.instance.startMatch(widget.matchId);
  }

  void _startMatchmakingTimer() {
    matchmakingTimer?.cancel();
    matchmakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      int now = DateTime.now().millisecondsSinceEpoch;

      if (now >= searchEndTime) {
        timer.cancel();
        if (isHost) {
          if (_players.length >= 2) {
            _startMatchAutomatically();
          } else {
            MatchService.instance.cancelMatchmaking(widget.matchId);
          }
        }
      } else {
        setState(() {});
      }
    });
  }

  void _startGlobalTimer(int endTimeMs) {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int now = DateTime.now().millisecondsSinceEpoch;
      int rem = ((endTimeMs - now) / 1000).round();

      if (rem <= 0) {
        rem = 0;
        timer.cancel();
        _finishMatch();
        _triggerLocalGameOver();
        return;
      }

      if (mounted && !isGameOver) {
        remainingSeconds = rem;
        if (remainingSeconds <= 10 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      }
    });
  }

  void _loadCurrentQuestion() {
    if (myQuestionIndex >= matchQuestions.length) {
      setState(() {
        _isSubmittingAnswer = false;
        currentRoundType = 'done';
      });
      return;
    }
    var q = matchQuestions[myQuestionIndex];
    setState(() {
      _isSubmittingAnswer = false;
      selectedIndices.clear();
      selectedLetters.clear();
      historySteps.clear();
      previousNumbersHistory.clear();
      firstNumIndex = null;
      firstNumValue = null;
      selectedOp = null;
      currentRoundType = q['type'];

      if (currentRoundType == 'word') {
        var rawLetters = q['letters'];
        if (rawLetters is String) {
          availableLetters = rawLetters.split('');
        } else {
          availableLetters = List<String>.from(rawLetters);
        }
      } else {
        targetNumber = q['target'];
        originalNumbers = List<int>.from(q['numbers']);
        currentNumbers = List<int>.from(originalNumbers);
        // Çözüm adımları arka planda (isolate) önceden hesaplanır.
        _mathStepsFuture = NumberSolverService.instance.solveStepsAsync(originalNumbers, targetNumber);
      }
    });
  }

  void _nextQuestion() {
    if (isGameOver || remainingSeconds <= 0) return;
    myQuestionIndex++;
    _loadCurrentQuestion();
  }

  Future<List<String>> _calculateRealMathSteps() {
    return _mathStepsFuture ??=
        NumberSolverService.instance.solveStepsAsync(originalNumbers, targetNumber);
  }

  Future<String> _calculateRealLongestWord() async {
    String b = await WordService.instance.findLongestWordAsync(availableLetters);
    return b.isEmpty ? "BULUNAMADI" : b;
  }

  Future<void> _recordCurrentSolution() async {
    if (currentRoundType == 'word') {
      final letters = availableLetters.where((l) => l != 'JOKER').join(', ');
      missedSolutions.add({
        'type': 'word',
        'letters': letters,
        'bestWord': await _calculateRealLongestWord(),
      });
    } else if (currentRoundType == 'math') {
      final target = targetNumber;
      missedSolutions.add({
        'type': 'math',
        'target': target,
        'mathSteps': await _calculateRealMathSteps(),
      });
    }
  }

  Future<void> _passQuestion() async {
    if (_isSubmittingAnswer || _isResolvingSolution || isGameOver || remainingSeconds <= 0 || remainingPasses <= 0) return;
    AudioService.instance.playClick();
    _isResolvingSolution = true;
    try {
      await _recordCurrentSolution();
    } finally {
      _isResolvingSolution = false;
    }
    if (!mounted || isGameOver) return;
    setState(() => remainingPasses--);
    _nextQuestion();
  }

  void _updateMyScore(int earned) {
    if (isGameOver || remainingSeconds <= 0) return;
    _firestore.collection('matches').doc(widget.matchId).update({
      'players.$myUid.score': FieldValue.increment(earned),
    }).catchError((_) {});
  }

  void _finishMatch() {
    _firestore.collection('matches').doc(widget.matchId).update({'status': 'finished'}).catchError((_) {});
  }

  void _exitToMainMenu() async {
    AudioService.instance.playClick();
    bool shouldShowAd = await UserService.instance.checkAndTriggerInterstitial();

    if (shouldShowAd) {
      AdService.instance.showInterstitialAd(onDismissed: () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
        }
      });
    } else {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }

  void _showGameOverDialog() {
    var sortedPlayers = _players.entries.toList()..sort((a, b) => (b.value['score'] as int).compareTo(a.value['score'] as int));
    int myRank = sortedPlayers.indexWhere((p) => p.key == myUid) + 1;
    bool didWin = myRank == 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF1D1B36),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: didWin ? Colors.amber : const Color(0xFF7C5CFC), width: 2)),
              child: Column(
                children: [
                  Text(didWin ? '🏆 ŞAMPİYON SENSİN!' : '$myRank. OLDUN',
                      style: TextStyle(color: didWin ? Colors.amber : Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedPlayers.length,
                        itemBuilder: (context, index) {
                          var p = sortedPlayers[index];
                          bool isMe = p.key == myUid;

                          bool isFriend = _friendUids.contains(p.key);
                          bool isPending = _pendingRequestUids.contains(p.key);

                          Color rankColor = index == 0
                              ? Colors.amber
                              : (index == 1 ? Colors.grey[400]! : (index == 2 ? Colors.brown[300]! : Colors.white54));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF7C5CFC).withValues(alpha: 0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isMe ? const Color(0xFF7C5CFC) : Colors.transparent)),
                            child: Row(
                              children: [
                                Text('${index + 1}.', style: TextStyle(color: rankColor, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(p.value['name'].toString(),
                                        style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16))),
                                Text('${p.value['score']} P', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18)),
                                if (!isMe && !isFriend) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: isPending
                                        ? null
                                        : () async {
                                            AudioService.instance.playClick();
                                            await _sendFriendRequest(p.key, p.value['name'].toString());
                                            setDialogState(() {});
                                          },
                                    icon: Icon(
                                      isPending ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded,
                                      color: isPending ? Colors.greenAccent : const Color(0xFF00CEC9),
                                      size: 24,
                                    ),
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (missedSolutions.isNotEmpty) ...[
                    const Text('Kaçırılan Çözümler', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: missedSolutions.length,
                        itemBuilder: (context, index) {
                          var sol = missedSolutions[index];
                          bool isWord = sol['type'] == 'word';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFF131127), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                            child: isWord
                                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Harfler: ${sol['letters']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                    Text('${sol['bestWord']} (${sol['bestWord'].length} Harf)',
                                        style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 14, fontWeight: FontWeight.bold))
                                  ])
                                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Hedef: ${sol['target']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                                    ...(sol['mathSteps'] as List<String>).map((step) =>
                                        Text(step, style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 12, fontWeight: FontWeight.bold)))
                                  ]),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (isPrivate && currentRoomCode != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00CEC9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () async {
                          AudioService.instance.playClick();
                          if (isHost) {
                            await MatchService.instance.resetPrivateMatchForRematch(
                              widget.matchId,
                              matchMode,
                              _players,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PrivateRoomScreen(
                                          initialRoomCode: currentRoomCode, activeMatchId: widget.matchId, isHostReopening: true)));
                            }
                          } else {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PrivateRoomScreen(initialRoomCode: currentRoomCode, waitForHostMatchId: widget.matchId)));
                          }
                        },
                        child: const Text('Odaya Tekrar Katıl', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _exitToMainMenu,
                      child: const Text('Ana Menüye Dön', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    )
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              onPressed: _exitToMainMenu,
                              child: const Text('Ana Menü', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5CE7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              onPressed: () {
                                AudioService.instance.playClick();
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
                              },
                              child: const Text('Tekrar Oyna', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendFriendRequest(String targetUid, String targetName) async {
    if (_pendingRequestUids.contains(targetUid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kişiye zaten istek gönderdiniz!'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      String myName = UserService.instance.cachedUser?.username ?? '';
      if (myName.isEmpty) {
        final myDoc = await _firestore.collection('users').doc(myUid).get();
        myName = myDoc.data()?['username'] ?? myDoc.data()?['name'] ?? 'Oyuncu';
      }

      await _firestore.collection('users').doc(targetUid).collection('friendRequests').doc(myUid).set({
        'uid': myUid,
        'fromUid': myUid,
        'name': myName,
        'username': myName,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _pendingRequestUids.add(targetUid));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$targetName kişisine arkadaşlık isteği gönderildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Arkadaş İstek Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek gönderilemedi. Bağlantınızı kontrol edin.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _submitWord() {
    if (_isSubmittingAnswer || isGameOver || remainingSeconds <= 0) return;
    String word = selectedLetters.join('');
    if (word.isEmpty) return;

    if (word.length == 1) {
      AudioService.instance.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 harfli bir kelime girmelisiniz!'), backgroundColor: Colors.orange, duration: Duration(seconds: 1)),
      );
      return;
    }

    _isSubmittingAnswer = true;
    var result = WordService.instance.validateWord(word, availableLetters);
    if (result == WordValidationResult.valid) {
      AudioService.instance.playSuccess();
      _confettiController.play();
      _showPraiseAnimation();
      int earned = ScoreCalculator.multiWordScore(word.length);
      _updateMyScore(earned);
      _nextQuestion();
    } else {
      _isSubmittingAnswer = false;
      AudioService.instance.playError();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 1)));
    }
  }

  void _submitMath() {
    if (_isSubmittingAnswer || isGameOver || remainingSeconds <= 0) return;
    if (currentNumbers.isEmpty) return;
    int closest = currentNumbers.first;
    int minDiff = (targetNumber - closest).abs();
    for (int n in currentNumbers) {
      int diff = (targetNumber - n).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = n;
      }
    }
    if (minDiff <= 10) {
      _isSubmittingAnswer = true;
      AudioService.instance.playSuccess();
      _confettiController.play();
      _showPraiseAnimation();
      int earned = ScoreCalculator.mathScore(minDiff, currentNumbers.length);
      _updateMyScore(earned);
      _nextQuestion();
    } else {
      AudioService.instance.playError();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedefe en fazla 10 yaklaşmalısınız!'), backgroundColor: Colors.orange, duration: Duration(seconds: 1)));
    }
  }

  void _undoLastAction() {
    if (_isSubmittingAnswer || isGameOver || remainingSeconds <= 0) return;
    AudioService.instance.playClick();
    setState(() {
      if (currentRoundType == 'word') {
        if (selectedLetters.isNotEmpty) {
          selectedLetters.removeLast();
          selectedIndices.removeLast();
        }
      } else {
        if (selectedOp != null) {
          selectedOp = null;
        } else if (firstNumIndex != null) {
          firstNumIndex = null;
          firstNumValue = null;
        } else if (historySteps.isNotEmpty && previousNumbersHistory.isNotEmpty) {
          historySteps.removeLast();
          currentNumbers = List<int>.from(previousNumbersHistory.last);
          previousNumbersHistory.removeLast();
        }
      }
    });
  }

  void _openJokerPicker(int index) {
    if (_isSubmittingAnswer || _isDialogShowing || isGameOver || remainingSeconds <= 0) return;
    _isDialogShowing = true;
    AudioService.instance.playClick();

    JokerPickerDialog.show(context).then((char) {
      _isDialogShowing = false;
      if (char == null || !mounted) return;
      if (!isGameOver && remainingSeconds > 0) {
        setState(() {
          selectedIndices.add(index);
          selectedLetters.add(char);
        });
      }
    });
  }

  void _onNumberTap(int index, int num) {
    if (_isSubmittingAnswer || isGameOver || remainingSeconds <= 0) return;
    AudioService.instance.playClick();
    if (firstNumIndex == null) {
      setState(() {
        firstNumIndex = index;
        firstNumValue = num;
      });
    } else if (selectedOp != null && firstNumIndex != index) {
      int secondNum = num;
      int? result;
      if (selectedOp == '+') result = firstNumValue! + secondNum;
      // Standart Kural: Ara sonuçlar pozitif tam sayı olmalıdır
      if (selectedOp == '-') {
        if (firstNumValue! - secondNum > 0) {
          result = firstNumValue! - secondNum;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çıkarma sonucu pozitif bir tam sayı olmalıdır!'),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 900),
            ),
          );
        }
      }
      if (selectedOp == '*') result = firstNumValue! * secondNum;
      if (selectedOp == '/') {
        if (secondNum > 0 && firstNumValue! % secondNum == 0) {
          result = firstNumValue! ~/ secondNum;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bölme işlemi kalansız olmalıdır!'),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 900),
            ),
          );
        }
      }

      if (result != null) {
        setState(() {
          previousNumbersHistory.add(List<int>.from(currentNumbers));
          historySteps.add('$firstNumValue $selectedOp $secondNum = $result');
          if (firstNumIndex! > index) {
            currentNumbers.removeAt(firstNumIndex!);
            currentNumbers.removeAt(index);
          } else {
            currentNumbers.removeAt(index);
            currentNumbers.removeAt(firstNumIndex!);
          }
          currentNumbers.add(result!);
          firstNumIndex = null;
          firstNumValue = null;
          selectedOp = null;
        });

        if (result == targetNumber) {
          Future.delayed(Duration.zero, () {
            if (mounted && !isGameOver) _submitMath();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    UserService.instance.updateUserStatus('çevrimiçi');
    _matchSubscription?.cancel();
    gameTimer?.cancel();
    matchmakingTimer?.cancel();
    _emojiTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    _remainingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _onWillPop()) {
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        body: currentRoundType == 'loading' ? _buildLoading() : _buildGameUI(),
      ),
    );
  }

  Widget _buildLoading() {
    int waitRem = 0;
    if (!isPrivate && searchEndTime > 0) {
      waitRem = ((searchEndTime - DateTime.now().millisecondsSinceEpoch) / 1000).round();
      if (waitRem < 0) waitRem = 0;
    }

    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: Color(0xFF7C5CFC)),
      const SizedBox(height: 20),
      Text(
          isPrivate
              ? 'Özel Oda Bekleniyor...\nOdada: ${_players.length}/6 Oyuncu'
              : 'Eşleşme Bekleniyor... ($waitRem)\nOdada: ${_players.length}/6 Oyuncu',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      if (isHost && isPrivate) ...[
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
          onPressed: _startMatchAutomatically,
          child: const Text('Oyunu Başlat', style: TextStyle(color: Colors.white)),
        )
      ]
    ]));
  }

  Widget _buildGameUI() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              _buildTopScoreBoard(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: currentRoundType == 'done'
                      ? const Center(
                          child: Text("Bütün soruları bitirdin!\nMaçın sonlanması bekleniyor...",
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)))
                      : Column(
                          children: [
                            const Spacer(),
                            if (currentRoundType == 'word') _buildWordArea() else _buildMathArea(),
                            const Spacer(),
                            _buildBottomControls()
                          ],
                        ),
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            bottom: _praiseBottom,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _praiseOpacity,
                child: Text(
                  _praiseText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Color(0xFF7C5CFC), blurRadius: 20, offset: Offset(0, 0)),
                        Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))
                      ]),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 145),
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _emojiOpacity,
                  child: _floatingEmojiText == null
                      ? const SizedBox()
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131127).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_floatingEmojiSenderName',
                                  style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 13, fontWeight: FontWeight.bold)),
                              const Text(': ', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(_floatingEmojiText!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          Text('Soru: ${myQuestionIndex + 1}/${matchQuestions.length}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF00CEC9)),
            onPressed: _showChatPanel,
          ),
          TimerChip(
            seconds: _remainingNotifier,
            warnAt: 10,
            horizontalPadding: 16,
            verticalPadding: 6,
            borderRadius: 14,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTopScoreBoard() {
    var sortedPlayers = _players.entries.toList()..sort((a, b) => (b.value['score'] as int).compareTo(a.value['score'] as int));

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedPlayers.length,
        itemBuilder: (context, index) {
          var p = sortedPlayers[index];
          bool isMe = p.key == myUid;
          int rank = index + 1;

          Color bgColor = isMe ? const Color(0xFF00CEC9).withValues(alpha: 0.2) : const Color(0xFF232042);
          Color borderColor = isMe ? const Color(0xFF00CEC9) : Colors.white12;
          Color rankColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[400]! : (rank == 3 ? Colors.brown[300]! : Colors.white54));

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.value['name'].toString(),
                        style: TextStyle(color: isMe ? const Color(0xFF00CEC9) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('${p.value['score']} P', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordArea() {
    final bool isLocked = _isSubmittingAnswer || isGameOver || remainingSeconds <= 0;
    return Column(children: [
      Container(
          height: 60,
          decoration: BoxDecoration(
              color: const Color(0xFF1D1B36),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF5A4FCF).withValues(alpha: 0.4))),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: selectedLetters
                  .map((char) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 36,
                      height: 42,
                      decoration: BoxDecoration(color: const Color(0xFF5A4FCF), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))))
                  .toList())),
      const SizedBox(height: 24),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
          itemCount: availableLetters.length,
          itemBuilder: (context, index) {
            String char = availableLetters[index];
            bool isUsed = selectedIndices.contains(index);
            return InkWell(
                onTap: (isUsed || isLocked)
                    ? null
                    : () {
                        if (char == 'JOKER') {
                          _openJokerPicker(index);
                        } else {
                          AudioService.instance.playClick();
                          setState(() {
                            selectedIndices.add(index);
                            selectedLetters.add(char);
                          });
                        }
                      },
                child: Container(
                    decoration: BoxDecoration(
                        color: isUsed ? const Color(0xFF1D1B36).withValues(alpha: 0.4) : (char == 'JOKER' ? const Color(0xFFFF9F43) : const Color(0xFF5A4FCF)),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                        child: Text(char,
                            style: TextStyle(
                                color: isUsed ? Colors.white24 : Colors.white, fontSize: char == 'JOKER' ? 14 : 20, fontWeight: FontWeight.bold)))));
          })
    ]);
  }

  Widget _buildMathArea() {
    final bool isLocked = _isSubmittingAnswer || isGameOver || remainingSeconds <= 0;
    return Column(children: [
      Text('HEDEF SAYI', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
      Text('$targetNumber', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(currentNumbers.length, (index) {
            bool isSelected = firstNumIndex == index;
            return GestureDetector(
                onTap: isLocked ? null : () => _onNumberTap(index, currentNumbers[index]),
                child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF9F43) : const Color(0xFF232042),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? const Color(0xFFFF9F43) : Colors.white12)),
                    child: Center(
                        child: Text('${currentNumbers[index]}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
          })),
      const SizedBox(height: 20),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['+', '-', '*', '/']
              .map((op) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                      onTap: isLocked ? null : () => setState(() => selectedOp = op),
                      child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              color: selectedOp == op ? const Color(0xFFFF9F43) : const Color(0xFF5A4FCF), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(op, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))))))
              .toList())
    ]);
  }

  Widget _buildBottomControls() {
    final bool isLocked = _isSubmittingAnswer || isGameOver || remainingSeconds <= 0;
    return Row(children: [
      Expanded(
          flex: 2,
          child: SizedBox(
              height: 46,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: isLocked ? null : _undoLastAction,
                  child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))))),
      const SizedBox(width: 6),
      Expanded(
          flex: 2,
          child: SizedBox(
              height: 46,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: isLocked
                      ? null
                      : () => setState(() {
                            if (currentRoundType == 'word') {
                              selectedLetters.clear();
                              selectedIndices.clear();
                            } else {
                              currentNumbers = List<int>.from(originalNumbers);
                              historySteps.clear();
                              previousNumbersHistory.clear();
                              firstNumIndex = null;
                              selectedOp = null;
                            }
                          }),
                  child: const Text('Temizle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))))),
      const SizedBox(width: 6),
      Expanded(
          flex: 2,
          child: SizedBox(
              height: 46,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: (remainingPasses > 0 && !isLocked) ? Colors.orangeAccent : Colors.grey.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: (remainingPasses > 0 && !isLocked) ? _passQuestion : null,
                  child: Text('Pas ($remainingPasses)',
                      style: TextStyle(color: remainingPasses > 0 ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))))),
      const SizedBox(width: 6),
      Expanded(
          flex: 3,
          child: SizedBox(
              height: 46,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF00CEC9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: isLocked ? null : (currentRoundType == 'word' ? _submitWord : _submitMath),
                  child: const Text('Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))))
    ]);
  }
}