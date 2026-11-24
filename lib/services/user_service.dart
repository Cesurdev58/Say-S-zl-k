import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'secure_storage_service.dart';
import '../main.dart';
import '../screens/splash_screen.dart';

class UserService {
  UserService._privateConstructor();
  static final UserService instance = UserService._privateConstructor();

  UserProfile? _currentUser;
  UserProfile? get cachedUser => _currentUser;

  Future<UserProfile>? _loadingFuture;

  String _localDeviceId = '';
  String get localDeviceId => _localDeviceId;

  StreamSubscription<DocumentSnapshot>? _deviceConflictSub;
  bool _isShowingConflictDialog = false;

  // --- GÜVENİLİR SUNUCU/SERVİS KATALOĞU (İstemci fiyat/ödül manipülasyonunu önler) ---
  static const Map<String, Map<String, int>> questCatalog = {
    'dq_play_3': {'goal': 3, 'reward': 15},
    'dq_score_200': {'goal': 200, 'reward': 25},
    'dq_math_exact_1': {'goal': 1, 'reward': 20},
    'dq_word_see_10': {'goal': 10, 'reward': 15},
    'q_play_50': {'goal': 50, 'reward': 100},
    'q_play_250': {'goal': 250, 'reward': 500},
    'q_play_1000': {'goal': 1000, 'reward': 2000},
    'q_score_3000': {'goal': 3000, 'reward': 200},
    'q_score_10000': {'goal': 10000, 'reward': 1000},
    'q_score_50000': {'goal': 50000, 'reward': 5000},
    'q_word_len_7': {'goal': 7, 'reward': 150},
    'q_word_len_8': {'goal': 8, 'reward': 500},
    'q_word_correct_100': {'goal': 100, 'reward': 300},
    'q_math_exact_25': {'goal': 25, 'reward': 250},
    'q_math_exact_100': {'goal': 100, 'reward': 1000},
    'q_math_correct_100': {'goal': 100, 'reward': 300},
    'q_rank_5': {'goal': 12000, 'reward': 1000},
  };

  static const Set<String> validAvatarIds = {
    'boy', 'girl', 'shark', 'bee', 'turtle', 'chick', 'dog', 'kitty', 'kitty-1',
    'knight', 'swordsman', 'wizard', 'magician', 'hacker', 'freelance', 'manager',
    'tax-inspector', 'graduate', 'graduate-1', 'muslim', 'girl1', 'girl-2', 'children'
  };

  static const Set<String> validBorderIds = {
    'border_arcane', 'border_bronze', 'border_champion', 'border_diamond', 'border_epic',
    'border_fire', 'border_forest', 'border_gold', 'border_halloween', 'border_holy',
    'border_ice', 'border_legendary', 'border_love', 'border_mythic', 'border_nature',
    'border_ninja', 'border_pirate', 'border_royal', 'border_shadow', 'border_silver',
    'border_space', 'border_steampunk', 'border_steel', 'border_sun', 'border_tech',
    'border_unicorn', 'border_water', 'border_winter'
  };

  Future<UserProfile> getCurrentUser() {
    if (_currentUser != null) return Future.value(_currentUser!);
    if (_loadingFuture != null) return _loadingFuture!;
    _loadingFuture = _fetchUserLogic().whenComplete(() {
      _loadingFuture = null;
    });
    return _loadingFuture!;
  }

  Future<UserProfile> _fetchUserLogic() async {
    String step = "0. Başlangıç";
    try {
      step = "1. Firebase Oturum Kontrolü";
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        step = "2. Anonim Giriş";
        UserCredential userCredential =
            await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 6));
        firebaseUser = userCredential.user;
      }
      String uid = firebaseUser!.uid;

      _localDeviceId = await SecureStorageService.instance.readData('localDeviceId') ?? '';
      if (_localDeviceId.isEmpty) {
        _localDeviceId = 'DEV_${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 5)}';
        await SecureStorageService.instance.writeData('localDeviceId', _localDeviceId);
      }

      step = "3. Cloud Sync";
      bool serverFetchSucceeded = false;
      bool remoteDocExists = false;

      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 4));

        serverFetchSucceeded = true;
        remoteDocExists = doc.exists;

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Future<void> safeW(String key, dynamic val) async {
            if (val != null) await SecureStorageService.instance.writeData(key, val.toString());
          }

          await safeW('username', data['username']);
          await safeW('avatar', data['avatar']);
          await safeW('selectedBorder', data['selectedBorder']);
          await safeW('totalScore', data['totalScore']);
          await safeW('highestSingleMatchScore', data['highestSingleMatchScore'] ?? 0);
          await safeW('gems', data['gems']);
          await safeW('xp', data['xp'] ?? 0);
          await safeW('gamesPlayed', data['gamesPlayed']);
          await safeW('hasUsedFreeNameChange', data['hasUsedFreeNameChange']);
          await safeW('isStatsHidden', data['isStatsHidden'] ?? false);
          await safeW('longestWord', data['longestWord']);
          await safeW('exactMathMatches', data['exactMathMatches']);
          await safeW('totalWordScore', data['totalWordScore']);
          await safeW('totalMathScore', data['totalMathScore']);
          await safeW('wordQuestionsSeen', data['wordQuestionsSeen']);
          await safeW('wordPasses', data['wordPasses']);
          await safeW('wordCorrectAnswers', data['wordCorrectAnswers']);
          await safeW('mathQuestionsSeen', data['mathQuestionsSeen']);
          await safeW('mathPasses', data['mathPasses']);
          await safeW('mathCorrectAnswers', data['mathCorrectAnswers']);
          await safeW('totalAnswerTimeSeconds', data['totalAnswerTimeSeconds']);
          await safeW('lastAdResetTime', data['lastAdResetTime']?.toString() ?? '0');
          await safeW('adRewardCount', data['adRewardCount']?.toString() ?? '0');
          if (data['purchasedAvatars'] != null) {
            await safeW('purchasedAvatars', json.encode(data['purchasedAvatars']));
          }
          if (data['purchasedBorders'] != null) {
            await safeW('purchasedBorders', json.encode(data['purchasedBorders']));
          }
          if (data['claimedQuests'] != null) {
            await safeW('claimedQuests', json.encode(data['claimedQuests']));
          }
        }
      } catch (e) {
        debugPrint("Firestore Okuma Hatası (Offline/Timeout): $e");
      }
      await SecureStorageService.instance.writeData('uid', uid);

      step = "4. Yerel Veri Okuma";
      String today = DateTime.now().toIso8601String().split('T')[0];
      final keys = [
        'username', 'avatar', 'selectedBorder', 'lastResetDate', 'claimedQuests',
        'purchasedAvatars', 'purchasedBorders', 'hasUsedFreeNameChange', 'isStatsHidden', 'longestWord',
        'gems', 'totalScore', 'highestSingleMatchScore', 'xp', 'gamesPlayed', 'dailyGamesPlayed', 'dailyScore',
        'dailyExactMathMatches', 'dailyWordQuestionsSeen', 'exactMathMatches',
        'totalWordScore', 'totalMathScore', 'wordQuestionsSeen', 'wordPasses',
        'wordCorrectAnswers', 'mathQuestionsSeen', 'mathPasses', 'mathCorrectAnswers',
        'totalAnswerTimeSeconds'
      ];
      List<String?> vals = [];
      for (String k in keys) {
        vals.add(await SecureStorageService.instance.readData(k));
      }
      final dMap = Map<String, String?>.fromIterables(keys, vals);
      int pInt(String key, [int d = 0]) {
        final v = dMap[key];
        return v != null ? int.tryParse(v) ?? d : d;
      }

      String sDate = dMap['lastResetDate'] ?? '';
      String? cStr = dMap['claimedQuests'];
      List<String> cQuests = cStr != null ? List<String>.from(json.decode(cStr)) : [];

      if (sDate != today) {
        await SecureStorageService.instance.writeData('lastResetDate', today);
        await SecureStorageService.instance.writeData('dailyGamesPlayed', '0');
        await SecureStorageService.instance.writeData('dailyScore', '0');
        await SecureStorageService.instance.writeData('dailyExactMathMatches', '0');
        await SecureStorageService.instance.writeData('dailyWordQuestionsSeen', '0');
        cQuests.removeWhere((id) => id.startsWith('dq_'));
        await SecureStorageService.instance.writeData('claimedQuests', json.encode(cQuests));
      }

      _currentUser = UserProfile(
        uid: uid,
        username: dMap['username'] ?? 'Oyuncu',
        avatar: dMap['avatar'] ?? 'boy',
        gems: pInt('gems'),
        totalScore: pInt('totalScore'),
        highestSingleMatchScore: pInt('highestSingleMatchScore'),
        xp: pInt('xp'),
        gamesPlayed: pInt('gamesPlayed'),
        hasUsedFreeNameChange: dMap['hasUsedFreeNameChange'] == 'true',
        isStatsHidden: dMap['isStatsHidden'] == 'true',
        claimedQuests: cQuests,
        purchasedAvatars: dMap['purchasedAvatars'] != null
            ? List<String>.from(json.decode(dMap['purchasedAvatars']!))
            : ['boy', 'girl'],
        purchasedBorders: dMap['purchasedBorders'] != null
            ? List<String>.from(json.decode(dMap['purchasedBorders']!))
            : [],
        selectedBorder: dMap['selectedBorder'] ?? 'none',
        lastResetDate: sDate.isNotEmpty ? sDate : today,
        dailyGamesPlayed: sDate != today ? 0 : pInt('dailyGamesPlayed'),
        dailyScore: sDate != today ? 0 : pInt('dailyScore'),
        dailyExactMathMatches: sDate != today ? 0 : pInt('dailyExactMathMatches'),
        dailyWordQuestionsSeen: sDate != today ? 0 : pInt('dailyWordQuestionsSeen'),
        longestWord: dMap['longestWord'] ?? '',
        exactMathMatches: pInt('exactMathMatches'),
        totalWordScore: pInt('totalWordScore'),
        totalMathScore: pInt('totalMathScore'),
        wordQuestionsSeen: pInt('wordQuestionsSeen'),
        wordPasses: pInt('wordPasses'),
        wordCorrectAnswers: pInt('wordCorrectAnswers'),
        mathQuestionsSeen: pInt('mathQuestionsSeen'),
        mathPasses: pInt('mathPasses'),
        mathCorrectAnswers: pInt('mathCorrectAnswers'),
        totalAnswerTimeSeconds: pInt('totalAnswerTimeSeconds'),
      );

      // KRİTİK KORUMA: Sunucu okuması başarısız olduysa yerel (eski/sıfır) veriyi buluta YAZMA!
      if (serverFetchSucceeded) {
        if (!remoteDocExists) {
          // Sadece sunucuda henüz hiç profil yoksa ilk kez oluştur
          await _syncToFirestore(claimDeviceSession: true);
        } else {
          // Sunucuda profil varsa sadece çevrimiçi durumunu, günlük sıfırlanan görevleri ve cihaz ID'sini güncelle
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'lastActive': FieldValue.serverTimestamp(),
            'status': 'çevrimiçi',
            'activeDeviceId': _localDeviceId,
            'claimedQuests': _currentUser!.claimedQuests,
          }, SetOptions(merge: true));
        }
      }

      _startDeviceConflictListener();
      return _currentUser!;
    } catch (e) {
      throw Exception("HATA NOKTASI [$step] -> $e");
    }
  }

  // --- TEK MERKEZLİ ÇOKLU CİHAZ GÜVENLİK KALKANI ---
  void _startDeviceConflictListener() {
    if (_currentUser == null) return;

    _deviceConflictSub?.cancel();
    _deviceConflictSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists || _isShowingConflictDialog) return;
      String activeDevice = doc.data()?['activeDeviceId']?.toString() ?? '';

      if (activeDevice.isNotEmpty && activeDevice != _localDeviceId) {
        _isShowingConflictDialog = true;
        _deviceConflictSub?.cancel();

        await forceSignOutAndMakeAnon();

        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1D1B36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Oturum Kapatıldı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'Hesabınıza başka bir cihazdan giriş yapıldı. Güvenliğiniz ve oyun adaletini sağlamak için bu cihazdaki oturumunuz sonlandırıldı.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5CFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _isShowingConflictDialog = false;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Anladım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        } else {
          _isShowingConflictDialog = false;
        }
      }
    });
  }

  // Not: Normal güncellemelerde activeDeviceId gönderilmez (cihazların birbiriyle savaşmasını önler)
  Future<void> _syncToFirestore({bool claimDeviceSession = false}) async {
    if (_currentUser == null) return;
    try {
      final Map<String, dynamic> payload = {
        'username': _currentUser!.username,
        'usernameLower': _currentUser!.username.toLowerCase(),
        'avatar': _currentUser!.avatar,
        'selectedBorder': _currentUser!.selectedBorder,
        'totalScore': _currentUser!.totalScore,
        'highestSingleMatchScore': _currentUser!.highestSingleMatchScore,
        'gems': _currentUser!.gems,
        'xp': _currentUser!.xp,
        'rankLevel': _currentUser!.rankLevel,
        'rankName': _currentUser!.rankName,
        'level': _currentUser!.level,
        'dominantIntelligence': _currentUser!.dominantIntelligence,
        'gamesPlayed': _currentUser!.gamesPlayed,
        'hasUsedFreeNameChange': _currentUser!.hasUsedFreeNameChange,
        'isStatsHidden': _currentUser!.isStatsHidden,
        'longestWord': _currentUser!.longestWord,
        'exactMathMatches': _currentUser!.exactMathMatches,
        'totalWordScore': _currentUser!.totalWordScore,
        'totalMathScore': _currentUser!.totalMathScore,
        'wordQuestionsSeen': _currentUser!.wordQuestionsSeen,
        'wordPasses': _currentUser!.wordPasses,
        'wordCorrectAnswers': _currentUser!.wordCorrectAnswers,
        'mathQuestionsSeen': _currentUser!.mathQuestionsSeen,
        'mathPasses': _currentUser!.mathPasses,
        'mathCorrectAnswers': _currentUser!.mathCorrectAnswers,
        'totalAnswerTimeSeconds': _currentUser!.totalAnswerTimeSeconds,
        'purchasedAvatars': _currentUser!.purchasedAvatars,
        'purchasedBorders': _currentUser!.purchasedBorders,
        'claimedQuests': _currentUser!.claimedQuests,
        'lastActive': FieldValue.serverTimestamp(),
        'status': 'çevrimiçi',
      };

      if (claimDeviceSession && _localDeviceId.isNotEmpty) {
        payload['activeDeviceId'] = _localDeviceId;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Sync Hatası: $e");
    }
  }

  Future<UserProfile?> getUserProfileById(String targetUid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> claimedQuests =
            data['claimedQuests'] != null ? List<String>.from(data['claimedQuests']) : [];
        List<String> purchasedAvatars = data['purchasedAvatars'] != null
            ? List<String>.from(data['purchasedAvatars'])
            : ['boy', 'girl'];
        List<String> purchasedBorders =
            data['purchasedBorders'] != null ? List<String>.from(data['purchasedBorders']) : [];

        return UserProfile(
          uid: targetUid,
          username: data['username'] ?? 'Oyuncu',
          avatar: data['avatar'] ?? 'boy',
          gems: data['gems'] ?? 0,
          totalScore: data['totalScore'] ?? 0,
          highestSingleMatchScore: data['highestSingleMatchScore'] ?? 0,
          xp: data['xp'] ?? 0,
          gamesPlayed: data['gamesPlayed'] ?? 0,
          hasUsedFreeNameChange: data['hasUsedFreeNameChange'] ?? false,
          isStatsHidden: data['isStatsHidden'] ?? false,
          claimedQuests: claimedQuests,
          purchasedAvatars: purchasedAvatars,
          purchasedBorders: purchasedBorders,
          selectedBorder: data['selectedBorder'] ?? 'none',
          lastResetDate: '',
          dailyGamesPlayed: 0,
          dailyScore: 0,
          dailyExactMathMatches: 0,
          dailyWordQuestionsSeen: 0,
          longestWord: data['longestWord'] ?? '',
          exactMathMatches: data['exactMathMatches'] ?? 0,
          totalWordScore: data['totalWordScore'] ?? 0,
          totalMathScore: data['totalMathScore'] ?? 0,
          wordQuestionsSeen: data['wordQuestionsSeen'] ?? 0,
          wordPasses: data['wordPasses'] ?? 0,
          wordCorrectAnswers: data['wordCorrectAnswers'] ?? 0,
          mathQuestionsSeen: data['mathQuestionsSeen'] ?? 0,
          mathPasses: data['mathPasses'] ?? 0,
          mathCorrectAnswers: data['mathCorrectAnswers'] ?? 0,
          totalAnswerTimeSeconds: data['totalAnswerTimeSeconds'] ?? 0,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> toggleStatsVisibility(bool isHidden) async {
    if (_currentUser == null) return;
    _currentUser!.isStatsHidden = isHidden;
    await SecureStorageService.instance.writeData('isStatsHidden', isHidden.toString());
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
      'isStatsHidden': isHidden,
    }).catchError((_) {});
  }

  Future<void> updateUserStatus(String status) async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'status': status,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot> getFriendRequestsStream() {
    final uid = _currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .snapshots();
  }

  Future<void> acceptFriendRequest(String senderUid, String senderName) async {
    final myUid = _currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final myName = _currentUser?.username ?? 'Oyuncu';

    try {
      // Gönderenin gerçek kullanıcı adını doğrula
      String verifiedSenderName = senderName;
      final senderDoc = await FirebaseFirestore.instance.collection('users').doc(senderUid).get();
      if (senderDoc.exists && senderDoc.data() != null) {
        verifiedSenderName =
            (senderDoc.data()!['username'] ?? senderDoc.data()!['name'] ?? senderName).toString();
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference myFriendRef =
          FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').doc(senderUid);
      batch.set(myFriendRef, {
        'uid': senderUid,
        'name': verifiedSenderName,
        'username': verifiedSenderName,
        'addedAt': FieldValue.serverTimestamp()
      });

      DocumentReference hisFriendRef =
          FirebaseFirestore.instance.collection('users').doc(senderUid).collection('friends').doc(myUid);
      batch.set(hisFriendRef, {
        'uid': myUid,
        'name': myName,
        'username': myName,
        'addedAt': FieldValue.serverTimestamp()
      });

      DocumentReference requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friendRequests')
          .doc(senderUid);
      batch.delete(requestRef);
      await batch.commit();
    } catch (e) {
      debugPrint("Arkadaş kabul hatası: $e");
    }
  }

  Future<void> rejectFriendRequest(String senderUid) async {
    final myUid = _currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friendRequests')
          .doc(senderUid)
          .delete();
    } catch (_) {}
  }

  Future<void> removeFriend(String friendUid) async {
    final myUid = _currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(
          FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').doc(friendUid));
      batch.delete(
          FirebaseFirestore.instance.collection('users').doc(friendUid).collection('friends').doc(myUid));
      await batch.commit();
    } catch (_) {}
  }

  // 30-50 arkadaş sınırını desteklemek için parçalı (chunked) whereIn sorgusu
  Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final myUid = _currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      List<String> friendUids = snapshot.docs.map((doc) => doc.id).take(50).toList();

      List<List<String>> chunks = [];
      for (int i = 0; i < friendUids.length; i += 30) {
        chunks.add(friendUids.sublist(i, min(i + 30, friendUids.length)));
      }

      final snapshots = await Future.wait(
        chunks.map((chunk) => FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get()),
      );

      List<Map<String, dynamic>> result = [];
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          Map<String, dynamic> friendData = Map<String, dynamic>.from(doc.data());
          friendData['uid'] = doc.id;
          result.add(friendData);
        }
      }
      return result;
    });
  }

  Future<void> addGems(int amount) async {
    if (_currentUser == null || amount <= 0) return;
    _currentUser!.gems += amount;
    await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
      'gems': FieldValue.increment(amount),
    }).catchError((_) {});
  }

  Future<bool> spendGems(int amount) async {
    if (_currentUser == null || amount <= 0) return false;
    if (_currentUser!.gems >= amount) {
      _currentUser!.gems -= amount;
      await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'gems': _currentUser!.gems,
      }).catchError((_) {});
      return true;
    }
    return false;
  }

  // ATOMİK SATIN ALMA VE KUŞANMA (Cevher düşümü ve ürün ekleme tek transaction'da)
  Future<bool> buyAvatar(String avatar, [int? ignoredPrice]) async {
    if (_currentUser == null) return false;
    if (!validAvatarIds.contains(avatar)) return false;
    if (_currentUser!.purchasedAvatars.contains(avatar)) return true;

    const int officialPrice = 250;
    if (_currentUser!.gems < officialPrice) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final bool bought = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return false;

        final data = snap.data()!;
        final int serverGems = (data['gems'] is int) ? (data['gems'] as int) : _currentUser!.gems;
        final List<String> owned = data['purchasedAvatars'] != null
            ? List<String>.from(data['purchasedAvatars'])
            : List<String>.from(_currentUser!.purchasedAvatars);

        if (owned.contains(avatar)) {
          transaction.update(docRef, {'avatar': avatar});
          return true;
        }

        if (serverGems < officialPrice) return false;

        owned.add(avatar);
        final int nextGems = serverGems - officialPrice;

        transaction.update(docRef, {
          'gems': nextGems,
          'purchasedAvatars': owned,
          'avatar': avatar,
        });

        _currentUser!.gems = nextGems;
        _currentUser!.purchasedAvatars = owned;
        _currentUser!.avatar = avatar;
        return true;
      });

      if (bought) {
        await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
        await SecureStorageService.instance
            .writeData('purchasedAvatars', json.encode(_currentUser!.purchasedAvatars));
        await SecureStorageService.instance.writeData('avatar', _currentUser!.avatar);
      }
      return bought;
    } catch (e) {
      debugPrint("Avatar satın alma hatası: $e");
      return false;
    }
  }

  Future<bool> buyBorder(String borderId, [int? ignoredPrice]) async {
    if (_currentUser == null) return false;
    if (!validBorderIds.contains(borderId)) return false;
    if (_currentUser!.purchasedBorders.contains(borderId)) return true;

    const int officialPrice = 750;
    if (_currentUser!.gems < officialPrice) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final bool bought = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return false;

        final data = snap.data()!;
        final int serverGems = (data['gems'] is int) ? (data['gems'] as int) : _currentUser!.gems;
        final List<String> owned = data['purchasedBorders'] != null
            ? List<String>.from(data['purchasedBorders'])
            : List<String>.from(_currentUser!.purchasedBorders);

        if (owned.contains(borderId)) {
          transaction.update(docRef, {'selectedBorder': borderId});
          return true;
        }

        if (serverGems < officialPrice) return false;

        owned.add(borderId);
        final int nextGems = serverGems - officialPrice;

        transaction.update(docRef, {
          'gems': nextGems,
          'purchasedBorders': owned,
          'selectedBorder': borderId,
        });

        _currentUser!.gems = nextGems;
        _currentUser!.purchasedBorders = owned;
        _currentUser!.selectedBorder = borderId;
        return true;
      });

      if (bought) {
        await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
        await SecureStorageService.instance
            .writeData('purchasedBorders', json.encode(_currentUser!.purchasedBorders));
        await SecureStorageService.instance.writeData('selectedBorder', _currentUser!.selectedBorder);
      }
      return bought;
    } catch (e) {
      debugPrint("Çerçeve satın alma hatası: $e");
      return false;
    }
  }

  Future<void> setBorder(String borderId) async {
    if (_currentUser == null) return;
    if (borderId != 'none' && !_currentUser!.purchasedBorders.contains(borderId)) return;
    _currentUser!.selectedBorder = borderId;
    await SecureStorageService.instance.writeData('selectedBorder', borderId);
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
      'selectedBorder': borderId,
    }).catchError((_) {});
  }

  Future<void> updateAvatar(String newAvatar) async {
    if (_currentUser == null) return;
    if (!_currentUser!.purchasedAvatars.contains(newAvatar)) return;
    _currentUser!.avatar = newAvatar;
    await SecureStorageService.instance.writeData('avatar', newAvatar);
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
      'avatar': newAvatar,
    }).catchError((_) {});
  }

  int _getQuestProgressForValidation(String id) {
    if (_currentUser == null) return 0;
    if (id == 'dq_play_3') return _currentUser!.dailyGamesPlayed;
    if (id == 'dq_score_200') return _currentUser!.dailyScore;
    if (id == 'dq_math_exact_1') return _currentUser!.dailyExactMathMatches;
    if (id == 'dq_word_see_10') return _currentUser!.dailyWordQuestionsSeen;
    if (id.startsWith('q_play')) return _currentUser!.gamesPlayed;
    if (id.startsWith('q_score')) return _currentUser!.totalScore;
    if (id.startsWith('q_word_len')) return _currentUser!.longestWord.length;
    if (id.startsWith('q_math_exact')) return _currentUser!.exactMathMatches;
    if (id.startsWith('q_word_correct')) return _currentUser!.wordCorrectAnswers;
    if (id.startsWith('q_math_correct')) return _currentUser!.mathCorrectAnswers;
    if (id.startsWith('q_rank')) return _currentUser!.totalScore;
    return 0;
  }

  // ATOMİK GÖREV ÖDÜLÜ ALMA (Katalogdan gerçek ödülü doğrular ve ilerlemeyi kontrol eder)
  Future<bool> claimQuestReward(String questId, [int? ignoredRewardAmount]) async {
    if (_currentUser == null) return false;
    final questMeta = questCatalog[questId];
    if (questMeta == null) return false;

    final int goal = questMeta['goal']!;
    final int officialReward = questMeta['reward']!;

    if (_getQuestProgressForValidation(questId) < goal) return false;
    if (_currentUser!.claimedQuests.contains(questId)) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final bool claimed = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return false;

        final data = snap.data()!;
        final List<String> serverClaimed = data['claimedQuests'] != null
            ? List<String>.from(data['claimedQuests'])
            : List<String>.from(_currentUser!.claimedQuests);

        // Günlük görevse ve yerelde sıfırlanmışsa ama sunucuda eski günden kalmışsa senkronize et
        if (!questId.startsWith('dq_') && serverClaimed.contains(questId)) {
          return false;
        }
        if (questId.startsWith('dq_') && _currentUser!.claimedQuests.contains(questId)) {
          return false;
        }

        if (!serverClaimed.contains(questId)) {
          serverClaimed.add(questId);
        }

        final int serverGems = (data['gems'] is int) ? (data['gems'] as int) : _currentUser!.gems;
        final int nextGems = serverGems + officialReward;

        transaction.update(docRef, {
          'claimedQuests': serverClaimed,
          'gems': nextGems,
        });

        _currentUser!.claimedQuests = serverClaimed;
        _currentUser!.gems = nextGems;
        return true;
      });

      if (claimed) {
        await SecureStorageService.instance
            .writeData('claimedQuests', json.encode(_currentUser!.claimedQuests));
        await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
      }
      return claimed;
    } catch (e) {
      debugPrint("Görev ödülü hatası: $e");
      return false;
    }
  }

  Future<bool> updateUsername(String newName) async {
    if (_currentUser == null) return false;
    final String cleanName = newName.trim();
    if (cleanName.isEmpty) return false;

    if (!_currentUser!.hasUsedFreeNameChange) {
      _currentUser!.username = cleanName;
      _currentUser!.hasUsedFreeNameChange = true;
      await SecureStorageService.instance.writeData('username', cleanName);
      await SecureStorageService.instance.writeData('hasUsedFreeNameChange', 'true');
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'username': cleanName,
        'usernameLower': cleanName.toLowerCase(),
        'hasUsedFreeNameChange': true,
      }).catchError((_) {});
      return true;
    }
    if (_currentUser!.gems >= 1000) {
      _currentUser!.gems -= 1000;
      _currentUser!.username = cleanName;
      await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
      await SecureStorageService.instance.writeData('username', cleanName);
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'username': cleanName,
        'usernameLower': cleanName.toLowerCase(),
        'gems': _currentUser!.gems,
      }).catchError((_) {});
      return true;
    }
    return false;
  }

  Future<void> addGameResult({
    required int totalEarned,
    required int wordEarned,
    required int mathEarned,
    required String currentLongestWord,
    required int exactMathCount,
    required int wordSeen,
    required int wordPassed,
    required int wordCorrect,
    required int mathSeen,
    required int mathPassed,
    required int mathCorrect,
    required int answerTime,
  }) async {
    if (_currentUser == null) return;

    bool isFirstMatch = _currentUser!.dailyGamesPlayed == 0;
    int wordXp = wordCorrect * 5;
    int mathXp = (exactMathCount * 15) + ((mathCorrect - exactMathCount) * 10);
    int matchCompletionXp = 10;
    int dailyBonusXp = isFirstMatch ? 50 : 0;

    int totalXpEarned = max(0, wordXp + mathXp + matchCompletionXp + dailyBonusXp);

    int oldLevel = _currentUser!.level;
    _currentUser!.xp += totalXpEarned;
    int newLevel = _currentUser!.level;

    if (newLevel > oldLevel) {
      int gemsToGive = 0;
      for (int i = oldLevel + 1; i <= newLevel; i++) {
        if (i <= 1000) {
          gemsToGive += (i * 5);
        }
      }
      if (gemsToGive > 0) {
        _currentUser!.gems += gemsToGive;
        await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
      }
    }

    _currentUser!.totalScore += max(0, totalEarned);
    _currentUser!.gamesPlayed += 1;
    if (totalEarned > _currentUser!.highestSingleMatchScore) {
      _currentUser!.highestSingleMatchScore = totalEarned;
      await SecureStorageService.instance.writeData('highestSingleMatchScore', totalEarned.toString());
    }

    _currentUser!.totalWordScore += max(0, wordEarned);
    _currentUser!.totalMathScore += max(0, mathEarned);
    _currentUser!.exactMathMatches += max(0, exactMathCount);
    _currentUser!.wordQuestionsSeen += max(0, wordSeen);
    _currentUser!.wordPasses += max(0, wordPassed);
    _currentUser!.wordCorrectAnswers += max(0, wordCorrect);
    _currentUser!.mathQuestionsSeen += max(0, mathSeen);
    _currentUser!.mathPasses += max(0, mathPassed);
    _currentUser!.mathCorrectAnswers += max(0, mathCorrect);
    _currentUser!.totalAnswerTimeSeconds += max(0, answerTime);

    if (currentLongestWord.length > _currentUser!.longestWord.length) {
      _currentUser!.longestWord = currentLongestWord;
      await SecureStorageService.instance.writeData('longestWord', currentLongestWord);
    }

    _currentUser!.dailyGamesPlayed += 1;
    _currentUser!.dailyScore += max(0, totalEarned);
    _currentUser!.dailyExactMathMatches += max(0, exactMathCount);
    _currentUser!.dailyWordQuestionsSeen += max(0, wordSeen);

    await SecureStorageService.instance.writeData('xp', _currentUser!.xp.toString());
    await SecureStorageService.instance.writeData('dailyGamesPlayed', _currentUser!.dailyGamesPlayed.toString());
    await SecureStorageService.instance.writeData('dailyScore', _currentUser!.dailyScore.toString());
    await SecureStorageService.instance
        .writeData('dailyExactMathMatches', _currentUser!.dailyExactMathMatches.toString());
    await SecureStorageService.instance
        .writeData('dailyWordQuestionsSeen', _currentUser!.dailyWordQuestionsSeen.toString());
    await SecureStorageService.instance.writeData('totalScore', _currentUser!.totalScore.toString());
    await SecureStorageService.instance.writeData('gamesPlayed', _currentUser!.gamesPlayed.toString());
    await SecureStorageService.instance.writeData('totalWordScore', _currentUser!.totalWordScore.toString());
    await SecureStorageService.instance.writeData('totalMathScore', _currentUser!.totalMathScore.toString());
    await SecureStorageService.instance.writeData('exactMathMatches', _currentUser!.exactMathMatches.toString());
    await SecureStorageService.instance
        .writeData('wordQuestionsSeen', _currentUser!.wordQuestionsSeen.toString());
    await SecureStorageService.instance.writeData('wordPasses', _currentUser!.wordPasses.toString());
    await SecureStorageService.instance
        .writeData('wordCorrectAnswers', _currentUser!.wordCorrectAnswers.toString());
    await SecureStorageService.instance
        .writeData('mathQuestionsSeen', _currentUser!.mathQuestionsSeen.toString());
    await SecureStorageService.instance.writeData('mathPasses', _currentUser!.mathPasses.toString());
    await SecureStorageService.instance
        .writeData('mathCorrectAnswers', _currentUser!.mathCorrectAnswers.toString());
    await SecureStorageService.instance
        .writeData('totalAnswerTimeSeconds', _currentUser!.totalAnswerTimeSeconds.toString());

    await _syncToFirestore(claimDeviceSession: false);
  }

  Future<void> deleteAccount({String? password}) async {
    if (_currentUser == null) throw Exception("Kullanıcı bulunamadı.");
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      if (!firebaseUser.isAnonymous && password != null && password.isNotEmpty) {
        AuthCredential credential =
            EmailAuthProvider.credential(email: firebaseUser.email!, password: password);
        await firebaseUser.reauthenticateWithCredential(credential);
      }
      _deviceConflictSub?.cancel();
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).delete();
      try {
        await firebaseUser.delete();
      } catch (e) {
        await FirebaseAuth.instance.signOut();
      }
      await _clearAllLocalData();
      _currentUser = null;
    }
  }

  Future<void> forceSignOutAndMakeAnon() async {
    _deviceConflictSub?.cancel();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _clearAllLocalData();
    _currentUser = null;
    _loadingFuture = null;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Anonim oturum açma hatası: $e");
    }
  }

  Future<void> linkOrLoginAccount(String email, String password, bool isLoginMode) async {
    User? oldFirebaseUser = FirebaseAuth.instance.currentUser;
    bool isOldAnon = oldFirebaseUser?.isAnonymous ?? false;
    String? oldUid = oldFirebaseUser?.uid;

    if (isLoginMode) {
      _deviceConflictSub?.cancel();
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (isOldAnon && oldUid != null && oldUid != FirebaseAuth.instance.currentUser?.uid) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(oldUid)
            .delete()
            .catchError((e) => debugPrint(e.toString()));
      }
      await _clearAllLocalData();
      _currentUser = null;
      _loadingFuture = null;
      await getCurrentUser();
    } else {
      if (oldFirebaseUser != null && isOldAnon) {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await oldFirebaseUser.linkWithCredential(credential);
      } else {
        if (oldFirebaseUser != null && !isOldAnon) {
          _deviceConflictSub?.cancel();
          await FirebaseAuth.instance.signOut();
          await _clearAllLocalData();
          _currentUser = null;
          _loadingFuture = null;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }

      if (_currentUser == null) {
        await getCurrentUser();
      } else {
        await _syncToFirestore(claimDeviceSession: true);
      }
    }
  }

  Future<void> _clearAllLocalData() async {
    final Map<String, String> defaultValues = {
      'uid': '',
      'privacyAccepted': '',
      'username': 'Oyuncu',
      'avatar': 'boy',
      'selectedBorder': 'none',
      'totalScore': '0',
      'highestSingleMatchScore': '0',
      'gems': '0',
      'xp': '0',
      'gamesPlayed': '0',
      'hasUsedFreeNameChange': 'false',
      'isStatsHidden': 'false',
      'longestWord': '',
      'exactMathMatches': '0',
      'totalWordScore': '0',
      'totalMathScore': '0',
      'wordQuestionsSeen': '0',
      'wordPasses': '0',
      'wordCorrectAnswers': '0',
      'mathQuestionsSeen': '0',
      'mathPasses': '0',
      'mathCorrectAnswers': '0',
      'totalAnswerTimeSeconds': '0',
      'dailyGamesPlayed': '0',
      'dailyScore': '0',
      'dailyExactMathMatches': '0',
      'dailyWordQuestionsSeen': '0',
      'purchasedAvatars': json.encode(['boy', 'girl']),
      'purchasedBorders': json.encode([]),
      'claimedQuests': json.encode([]),
    };
    for (var entry in defaultValues.entries) {
      await SecureStorageService.instance.writeData(entry.key, entry.value);
    }
  }

  Future<int> _getRealNetworkTime() async {
    try {
      final request =
          await HttpClient().headUrl(Uri.parse('https://google.com')).timeout(const Duration(seconds: 3));
      final response = await request.close();
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader != null) return HttpDate.parse(dateHeader).millisecondsSinceEpoch;
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<Map<String, dynamic>> getAdRewardStatus() async {
    if (_currentUser == null) return {'count': 0, 'nextReset': 0};
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int count = data['adRewardCount'] ?? 0;
        int lastTime = data['lastAdResetTime'] ?? 0;
        int realNowMs = await _getRealNetworkTime();
        if (lastTime == 0 || (realNowMs - lastTime) >= 8 * 60 * 60 * 1000) {
          count = 0;
          lastTime = realNowMs;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .update({'adRewardCount': count, 'lastAdResetTime': lastTime});
        }
        return {'count': count, 'nextReset': lastTime + (8 * 60 * 60 * 1000)};
      }
    } catch (_) {}
    return {'count': 2, 'nextReset': DateTime.now().millisecondsSinceEpoch + (8 * 60 * 60 * 1000)};
  }

  // ATOMİK REKLAM ÖDÜLÜ ALMA (Çift ödül yarışını önler)
  Future<bool> watchAdAndClaimReward() async {
    if (_currentUser == null) return false;
    final int realNowMs = await _getRealNetworkTime();
    final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

    try {
      final bool rewarded = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return false;

        final data = snap.data()!;
        int count = (data['adRewardCount'] is int) ? (data['adRewardCount'] as int) : 0;
        int lastTime = (data['lastAdResetTime'] is int) ? (data['lastAdResetTime'] as int) : 0;
        int currentGems = (data['gems'] is int) ? (data['gems'] as int) : _currentUser!.gems;

        if (lastTime == 0 || (realNowMs - lastTime) >= 8 * 60 * 60 * 1000) {
          count = 0;
          lastTime = realNowMs;
        }

        if (count >= 2) return false;

        final int nextCount = count + 1;
        final int nextGems = currentGems + 25;

        transaction.update(docRef, {
          'adRewardCount': nextCount,
          'lastAdResetTime': lastTime,
          'gems': nextGems,
        });

        _currentUser!.gems = nextGems;
        return true;
      });

      if (rewarded) {
        await SecureStorageService.instance.writeData('gems', _currentUser!.gems.toString());
      }
      return rewarded;
    } catch (e) {
      debugPrint("Reklam ödülü hatası: $e");
      return false;
    }
  }

  Future<bool> checkAndTriggerInterstitial() async {
    String? countStr = await SecureStorageService.instance.readData('interstitialGameCount');
    int count = (countStr != null ? int.parse(countStr) : 0) + 1;
    await SecureStorageService.instance.writeData('interstitialGameCount', count.toString());
    return count % 3 == 0;
  }
}