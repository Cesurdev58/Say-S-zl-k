import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/match_service.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import 'multiplayer_game_screen.dart';

class PrivateRoomScreen extends StatefulWidget {
  final String? initialRoomCode;
  final String? activeMatchId;
  final bool isHostReopening;
  final String? waitForHostMatchId;

  const PrivateRoomScreen({
    super.key,
    this.initialRoomCode,
    this.activeMatchId,
    this.isHostReopening = false,
    this.waitForHostMatchId,
  });

  @override
  State<PrivateRoomScreen> createState() => _PrivateRoomScreenState();
}

class _PrivateRoomScreenState extends State<PrivateRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  String? _myRoomCode;
  String? _activeMatchId;
  StreamSubscription<DocumentSnapshot>? _matchSubscription;

  bool _isLoading = false;
  bool _isInLobby = false;
  bool _isHost = false;
  bool _initialSettingsSynced = false;

  Map<String, dynamic> _lobbyPlayers = {};

  String _gameMode = 'mix';
  int _timeLimit = 120;
  int _passLimit = 3;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomCode != null) {
      _codeController.text = widget.initialRoomCode!;
    }

    if (widget.isHostReopening && widget.activeMatchId != null) {
      _myRoomCode = widget.initialRoomCode;
      _activeMatchId = widget.activeMatchId;
      _isHost = true;
      _isInLobby = true;
      _listenToLobbyStatus(_activeMatchId!);
    } else if (widget.waitForHostMatchId != null) {
      _waitForHostReopen(widget.waitForHostMatchId!);
    }
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    // Hem Host hem normal oyuncu lobideyken ekran kapanırsa güvenli çıkış yap
    if (_isInLobby && _activeMatchId != null) {
      final String matchToLeave = _activeMatchId!;
      _activeMatchId = null;
      _isInLobby = false;
      MatchService.instance.cancelMatchmaking(matchToLeave);
    }
    _codeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isInLobby) return true;

    bool? exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        title: const Text('Odadan Çık?', style: TextStyle(color: Colors.white)),
        content: Text(
          _isHost
              ? (_lobbyPlayers.length > 1
                  ? 'Odadan ayrılmak istediğinize emin misiniz? Kuruculuk içerideki başka bir oyuncuya devredilecek.'
                  : 'Odayı kapatmak istediğinize emin misiniz?')
              : 'Odadan ayrılmak istiyor musunuz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              _leaveLobby();
              Navigator.of(context).pop(true);
            },
            child: const Text('Çık', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  void _waitForHostReopen(String matchId) {
    setState(() {
      _isLoading = true;
    });
    _matchSubscription?.cancel();
    _matchSubscription = FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots().listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oda kapatıldı.'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isLoading = false;
        });
        _matchSubscription?.cancel();
        Navigator.of(context).pop();
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] == 'waiting') {
        _matchSubscription?.cancel();
        setState(() {
          _myRoomCode = widget.initialRoomCode;
          _activeMatchId = matchId;
          _isHost = data['hostUid'] == myUid;
          _isInLobby = true;
          _isLoading = false;
        });
        _listenToLobbyStatus(matchId);
      }
    });
  }

  void _createRoom() async {
    AudioService.instance.playClick();
    setState(() => _isLoading = true);

    final result = await MatchService.instance.createPrivateMatch(matchMode: _gameMode);

    if (!mounted) {
      if (result != null && result['matchId'] != null) {
        await MatchService.instance.cancelMatchmaking(result['matchId']!);
      }
      return;
    }

    if (result != null) {
      String matchId = result['matchId'] ?? '';

      await MatchService.instance.updateLobbySettings(
        matchId,
        timeLimit: _timeLimit,
        passLimit: _passLimit,
      );

      if (!mounted) return;

      setState(() {
        _activeMatchId = matchId;
        _myRoomCode = result['roomCode'];
        _isHost = true;
        _isInLobby = true;
        _isLoading = false;
        _initialSettingsSynced = true;
      });
      UserService.instance.updateUserStatus('oyunda');
      _listenToLobbyStatus(_activeMatchId!);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oda kurulamadı!'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir 6 haneli kod girin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    AudioService.instance.playClick();
    setState(() => _isLoading = true);

    final result = await MatchService.instance.joinPrivateMatch(code);

    if (!mounted) {
      if (result != null && result != 'FULL') {
        await MatchService.instance.cancelMatchmaking(result);
      }
      return;
    }

    if (result == 'FULL') {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oda dolu! Maksimum 6 kişi girebilir.'), backgroundColor: Colors.redAccent),
      );
    } else if (result != null) {
      setState(() {
        _activeMatchId = result;
        _myRoomCode = code;
        _isHost = false;
        _isInLobby = true;
        _isLoading = false;
      });
      UserService.instance.updateUserStatus('oyunda');
      _listenToLobbyStatus(_activeMatchId!);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oda bulunamadı veya Oyun zaten başlamış!'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _listenToLobbyStatus(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots().listen((snapshot) {
      if (!mounted) return;

      if (!snapshot.exists) {
        if (_isInLobby) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oda kapatıldı.'), backgroundColor: Colors.redAccent),
          );
          setState(() {
            _isInLobby = false;
            _activeMatchId = null;
          });
          UserService.instance.updateUserStatus('çevrimiçi');
          Navigator.of(context).pop();
        }
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        _lobbyPlayers = Map<String, dynamic>.from(data['players'] ?? {});
        _isHost = data['hostUid'] == myUid;

        if (!_isHost || !_initialSettingsSynced) {
          _gameMode = data['gameMode'] ?? 'mix';
          _timeLimit = data['timeLimit'] ?? 120;
          _passLimit = data['passLimit'] ?? 3;
          _initialSettingsSynced = true;
        }
      });

      if (data['status'] == 'playing') {
        _matchSubscription?.cancel();
        _isInLobby = false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MultiplayerGameScreen(matchId: matchId)),
        );
      }
    });
  }

  void _updateSetting(String key, dynamic value) {
    if (!_isHost || _activeMatchId == null) return;
    AudioService.instance.playClick();

    setState(() {
      if (key == 'gameMode') _gameMode = value;
      if (key == 'timeLimit') _timeLimit = value;
      if (key == 'passLimit') _passLimit = value;
    });

    if (key == 'gameMode') {
      MatchService.instance.updateGameMode(_activeMatchId!, value);
    } else if (key == 'timeLimit') {
      MatchService.instance.updateLobbySettings(_activeMatchId!, timeLimit: value as int);
    } else if (key == 'passLimit') {
      MatchService.instance.updateLobbySettings(_activeMatchId!, passLimit: value as int);
    }
  }

  void _showTransferHostDialog(String targetUid, String targetName) {
    AudioService.instance.playClick();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        title: const Text('Kuruculuğu Devret', style: TextStyle(color: Colors.white)),
        content: Text(
          '$targetName adlı oyuncuya oda kuruculuğunu devretmek istiyor musun?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CEC9)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (_activeMatchId == null) return;
              try {
                await MatchService.instance.transferHost(_activeMatchId!, myUid, targetUid);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oda kuruculuğu devredildi!'), backgroundColor: Colors.green),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kuruculuk devredilemedi.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Devret', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _leaveLobby() {
    AudioService.instance.playClick();
    _matchSubscription?.cancel();

    final String? matchToLeave = _activeMatchId;
    setState(() {
      _isInLobby = false;
      _myRoomCode = null;
      _activeMatchId = null;
      _lobbyPlayers.clear();
    });

    // Hem Host hem normal oyuncu için atomik transaction ile odadan çık
    if (matchToLeave != null) {
      MatchService.instance.cancelMatchmaking(matchToLeave);
    }
    UserService.instance.updateUserStatus('çevrimiçi');
  }

  void _startGame() async {
    AudioService.instance.playClick();
    if (_activeMatchId != null) {
      await MatchService.instance.startMatch(_activeMatchId!, gameMode: _gameMode);
    }
  }

  void _showInviteFriendDialog() {
    AudioService.instance.playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1D1B36),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Arkadaş Davet Et', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: UserService.instance.getFriendsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00CEC9)));
                  }
                  final friends = snapshot.data ?? [];
                  if (friends.isEmpty) {
                    return const Center(child: Text('Davet edilecek arkadaş bulunamadı.', style: TextStyle(color: Colors.white54)));
                  }

                  return ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final friendUid = friend['uid'];
                      final friendName = friend['username'] ?? friend['name'] ?? 'Oyuncu';
                      final status = friend['status'] ?? 'çevrimdışı';

                      bool isOnline = status == 'çevrimiçi';
                      bool isIngame = status == 'oyunda';

                      return ListTile(
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF7C5CFC).withOpacity(0.2),
                              child: const Icon(Icons.person, color: Color(0xFF7C5CFC)),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : (isIngame ? Colors.orange : Colors.grey),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1D1B36), width: 2),
                              ),
                            ),
                          ],
                        ),
                        title: Text(friendName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: isOnline ? Colors.green : (isIngame ? Colors.orange : Colors.grey), fontSize: 10),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOnline ? const Color(0xFF00CEC9) : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isOnline
                              ? () {
                                  _sendRoomInvite(friendUid, friendName);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text('Davet Et', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendRoomInvite(String friendUid, String friendName) async {
    if (_myRoomCode == null) return;
    try {
      final me = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final myName = me.data()?['username'] ?? me.data()?['name'] ?? 'Oyuncu';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('room_invites')
          .doc(_myRoomCode)
          .set({
        'hostUid': myUid,
        'hostName': myName,
        'roomCode': _myRoomCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$friendName adlı kişiye davet gönderildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Davet gönderilemedi.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Özel Oda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading && !_isInLobby
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00CEC9)),
                      if (widget.waitForHostMatchId != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Kurucu odayı hazırlıyor...\nLütfen bekleyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ]
                    ],
                  ),
                )
              : _isInLobby
                  ? _buildLobbyView()
                  : _buildSelectionView(),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.meeting_room_rounded, color: Color(0xFF7C5CFC), size: 80),
        const SizedBox(height: 24),
        const Text('Grup Kapışması', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          '6 kişiye kadar arkadaşlarınla aynı anda kapış!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            label: const Text('Yeni Oda Kur (Host)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _createRoom,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('VEYA', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "KOD GİR",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 24, letterSpacing: 4),
                  filled: true,
                  fillColor: const Color(0xFF131127),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _joinRoom,
                  child: const Text('Odaya Katıl', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyView() {
    int playerCount = _lobbyPlayers.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7C5CFC), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ODA KODU', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    _myRoomCode ?? '------',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C5CFC), size: 24),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _myRoomCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kod Kopyalandı!'), backgroundColor: Color(0xFF00CEC9)),
                  );
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CEC9).withOpacity(0.2),
              side: const BorderSide(color: Color(0xFF00CEC9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF00CEC9)),
            label: const Text('Arkadaş Davet Et', style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold)),
            onPressed: _showInviteFriendDialog,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Oda Ayarları', style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                  if (!_isHost) const Text('(Sadece Kurucu)', style: TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Oyun Modu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  _isHost
                      ? DropdownButton<String>(
                          value: _gameMode,
                          dropdownColor: const Color(0xFF232042),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00CEC9)),
                          style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'mix', child: Text('Karışık')),
                            DropdownMenuItem(value: 'word', child: Text('Sadece Kelime')),
                            DropdownMenuItem(value: 'math', child: Text('Sadece İşlem')),
                          ],
                          onChanged: (val) => _updateSetting('gameMode', val!),
                        )
                      : Text(
                          _gameMode == 'mix' ? 'Karışık' : (_gameMode == 'word' ? 'Sadece Kelime' : 'Sadece İşlem'),
                          style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold),
                        ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Süre (Saniye)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      if (_isHost)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: _timeLimit > 10 ? () => _updateSetting('timeLimit', _timeLimit - 10) : null,
                        ),
                      Text('$_timeLimit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_isHost)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 20),
                          onPressed: _timeLimit < 150 ? () => _updateSetting('timeLimit', _timeLimit + 10) : null,
                        ),
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pas Hakkı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      if (_isHost)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: _passLimit > 0 ? () => _updateSetting('passLimit', _passLimit - 1) : null,
                        ),
                      Text('$_passLimit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_isHost)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 20),
                          onPressed: _passLimit < 9 ? () => _updateSetting('passLimit', _passLimit + 1) : null,
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isHost ? 'Oyuncular ($playerCount/6) - Devretmek için dokun' : 'Oyuncular ($playerCount/6)',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _lobbyPlayers.length,
            itemBuilder: (context, index) {
              String uid = _lobbyPlayers.keys.elementAt(index);
              var pData = _lobbyPlayers[uid];
              bool isHostPlayer = pData['isHost'] == true;
              bool isMe = uid == myUid;

              return GestureDetector(
                onTap: () {
                  if (_isHost && !isMe) {
                    _showTransferHostDialog(uid, pData['name']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF7C5CFC).withOpacity(0.2) : const Color(0xFF1D1B36),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMe ? const Color(0xFF7C5CFC) : Colors.white12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isHostPlayer ? Colors.amber.withOpacity(0.2) : const Color(0xFF00CEC9).withOpacity(0.2),
                        child: Icon(
                          isHostPlayer ? Icons.star_rounded : Icons.person,
                          size: 16,
                          color: isHostPlayer ? Colors.amber : const Color(0xFF00CEC9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pData['name'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (isHostPlayer)
                        const Text(
                          'KURUCU',
                          style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isHost) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: playerCount >= 2 ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: playerCount >= 2 ? _startGame : null,
              child: Text(
                playerCount >= 2 ? 'OYUNU BAŞLAT' : 'OYUNCU BEKLENİYOR...',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton(
          onPressed: () async {
            if (await _onWillPop()) {
              if (mounted) Navigator.pop(context);
            }
          },
          child: Text(
            _isHost && playerCount <= 1 ? 'Odayı Kapat' : 'Odadan Çık',
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}