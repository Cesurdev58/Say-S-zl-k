import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/math_service.dart';
import '../services/word_service.dart';

class _RoomCodeCollisionException implements Exception {
  const _RoomCodeCollisionException();
}

class MatchService {
  MatchService._privateConstructor();

  static final MatchService instance =
      MatchService._privateConstructor();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const int publicRoomCapacity = 6;
  static const int privateRoomCapacity = 6;
  static const int minimumPlayersToStart = 2;

  static const int defaultTimeLimit = 120;
  static const int defaultPassLimit = 3;

  String _sanitizeMode(String mode) {
    if (mode == 'word' ||
        mode == 'math' ||
        mode == 'mix') {
      return mode;
    }

    return 'mix';
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is! Map) return null;

    return Map<String, dynamic>.from(value);
  }

  Future<String> _getUserName(
    String uid,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          userSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>? data =
          userSnapshot.data();

      if (userSnapshot.exists && data != null) {
        final dynamic rawName =
            data['username'] ?? data['name'];

        if (rawName is String &&
            rawName.trim().isNotEmpty) {
          return rawName.trim();
        }
      }
    } catch (_) {}

    return 'Oyuncu';
  }

  Map<String, dynamic> _generateGameData({
    String matchMode = 'mix',
  }) {
    final String safeMode =
        _sanitizeMode(matchMode);

    final List<Map<String, dynamic>> rounds = [];

    final Set<String> usedWordSignatures = {};
    final Set<String> usedMathSignatures = {};

    const int totalRoundCount = 30;

    for (int index = 0;
        index < totalRoundCount;
        index++) {
      String roundType;

      if (safeMode == 'mix') {
        roundType =
            index.isEven ? 'word' : 'math';
      } else {
        roundType = safeMode;
      }

      if (roundType == 'word') {
        rounds.add(
          _generateUniqueWordRound(
            usedWordSignatures,
          ),
        );
      } else {
        rounds.add(
          _generateUniqueMathRound(
            usedMathSignatures,
          ),
        );
      }
    }

    return {
      'rounds': rounds,
    };
  }

  Map<String, dynamic> _generateUniqueWordRound(
    Set<String> usedSignatures,
  ) {
    for (int attempt = 0;
        attempt < 150;
        attempt++) {
      final List<String> letters =
          List<String>.from(
        WordService.instance.generateLetters(),
      );

      final String signature =
          (List<String>.from(letters)..sort())
              .join('|');

      if (usedSignatures.add(signature)) {
        return {
          'type': 'word',
          'letters': letters,
        };
      }
    }

    return {
      'type': 'word',
      'letters': List<String>.from(
        WordService.instance.generateLetters(),
      ),
    };
  }

  Map<String, dynamic> _generateUniqueMathRound(
    Set<String> usedSignatures,
  ) {
    final MathPuzzle puzzle =
        MathService.instance.generatePuzzle(
      usedSignatures: usedSignatures,
    );

    return {
      'type': 'math',
      'target': puzzle.target,
      'numbers': List<int>.from(
        puzzle.numbers,
      ),
    };
  }

  Future<String?> findOrCreateMatch({
    String matchMode = 'mix',
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) return null;

    final String myUid = user.uid;
    final String myName =
        await _getUserName(myUid);

    final String safeMode =
        _sanitizeMode(matchMode);

    final int now =
        DateTime.now().millisecondsSinceEpoch;

    try {
      final QuerySnapshot<Map<String, dynamic>>
          querySnapshot = await _firestore
              .collection('matches')
              .where(
                'status',
                isEqualTo: 'waiting',
              )
              .where(
                'isPrivate',
                isEqualTo: false,
              )
              .where(
                'gameMode',
                isEqualTo: safeMode,
              )
              .where(
                'searchEndTime',
                isGreaterThan: now,
              )
              .limit(10)
              .get();

      for (final QueryDocumentSnapshot<
              Map<String, dynamic>>
          document in querySnapshot.docs) {
        final bool joined =
            await _firestore.runTransaction<bool>(
          (Transaction transaction) async {
            final DocumentSnapshot<
                    Map<String, dynamic>>
                freshSnapshot =
                await transaction.get(
              document.reference,
            );

            final Map<String, dynamic>? data =
                freshSnapshot.data();

            if (!freshSnapshot.exists ||
                data == null) {
              return false;
            }

            final String currentStatus =
                data['status']?.toString() ?? '';

            final bool isPrivate =
                data['isPrivate'] == true;

            final String roomMode =
                data['gameMode']?.toString() ?? '';

            final int freshEndTime = _readInt(
              data['searchEndTime'],
            );

            final Map<String, dynamic>? players =
                _readMap(data['players']);

            if (players == null) return false;

            if (isPrivate ||
                currentStatus != 'waiting' ||
                roomMode != safeMode ||
                freshEndTime <=
                    DateTime.now()
                        .millisecondsSinceEpoch) {
              return false;
            }

            if (players.containsKey(myUid)) {
              return true;
            }

            if (players.length >=
                publicRoomCapacity) {
              return false;
            }

            players[myUid] = {
              'name': myName,
              'score': 0,
              'isHost': false,
            };

            transaction.update(
              document.reference,
              {
                'players': players,
                'playerCount': players.length,
              },
            );

            return true;
          },
        );

        if (joined) {
          return document.id;
        }
      }

      final DocumentReference<Map<String, dynamic>>
          matchReference =
          _firestore.collection('matches').doc();

      await matchReference.set({
        'hostUid': myUid,
        'status': 'waiting',
        'isPrivate': false,
        'gameMode': safeMode,
        'createdAt': FieldValue.serverTimestamp(),
        'searchEndTime':
            DateTime.now().millisecondsSinceEpoch +
                20000,
        'gameData': _generateGameData(
          matchMode: safeMode,
        ),
        'players': {
          myUid: {
            'name': myName,
            'score': 0,
            'isHost': true,
          },
        },
        'playerCount': 1,
      });

      return matchReference.id;
    } catch (error) {
      return null;
    }
  }

  Future<Map<String, String>?> createPrivateMatch({
    String matchMode = 'mix',
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) return null;

    final String myUid = user.uid;
    final String myName =
        await _getUserName(myUid);

    final String safeMode =
        _sanitizeMode(matchMode);

    const String roomCodeCharacters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    final Random random = Random();

    final Map<String, dynamic> gameData =
        _generateGameData(
      matchMode: safeMode,
    );

    for (int attempt = 0;
        attempt < 10;
        attempt++) {
      final String candidateCode =
          String.fromCharCodes(
        Iterable<int>.generate(
          6,
          (_) => roomCodeCharacters.codeUnitAt(
            random.nextInt(
              roomCodeCharacters.length,
            ),
          ),
        ),
      );

      final DocumentReference<Map<String, dynamic>>
          codeReference = _firestore
              .collection('privateRoomCodes')
              .doc(candidateCode);

      final DocumentReference<Map<String, dynamic>>
          matchReference =
          _firestore.collection('matches').doc();

      try {
        await _firestore.runTransaction<void>(
          (Transaction transaction) async {
            final DocumentSnapshot<
                    Map<String, dynamic>>
                codeSnapshot =
                await transaction.get(
              codeReference,
            );

            final Map<String, dynamic>?
                existingCodeData =
                codeSnapshot.data();

            if (codeSnapshot.exists &&
                existingCodeData != null) {
              final String? existingMatchId =
                  existingCodeData['matchId']
                      ?.toString();

              if (existingMatchId != null &&
                  existingMatchId.isNotEmpty) {
                final DocumentReference<
                        Map<String, dynamic>>
                    existingMatchReference =
                    _firestore
                        .collection('matches')
                        .doc(existingMatchId);

                final DocumentSnapshot<
                        Map<String, dynamic>>
                    existingMatchSnapshot =
                    await transaction.get(
                  existingMatchReference,
                );

                final Map<String, dynamic>?
                    existingMatchData =
                    existingMatchSnapshot.data();

                final String? existingStatus =
                    existingMatchData?['status']
                        ?.toString();

                if (existingMatchSnapshot.exists &&
                    (existingStatus == 'waiting' ||
                        existingStatus ==
                            'playing')) {
                  throw const _RoomCodeCollisionException();
                }
              }
            }

            transaction.set(
              codeReference,
              {
                'matchId': matchReference.id,
                'hostUid': myUid,
                'createdAt':
                    FieldValue.serverTimestamp(),
              },
            );

            transaction.set(
              matchReference,
              {
                'hostUid': myUid,
                'status': 'waiting',
                'isPrivate': true,
                'gameMode': safeMode,
                'roomCode': candidateCode,
                'timeLimit': defaultTimeLimit,
                'passLimit': defaultPassLimit,
                'createdAt':
                    FieldValue.serverTimestamp(),
                'gameData': gameData,
                'players': {
                  myUid: {
                    'name': myName,
                    'score': 0,
                    'isHost': true,
                  },
                },
                'playerCount': 1,
              },
            );
          },
        );

        return {
          'matchId': matchReference.id,
          'roomCode': candidateCode,
        };
      } on _RoomCodeCollisionException {
        continue;
      } catch (error) {
        return null;
      }
    }

    return null;
  }

  Future<void> updateGameMode(
    String matchId,
    String newMode,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final String safeMode =
        _sanitizeMode(newMode);

    final Map<String, dynamic> newGameData =
        _generateGameData(
      matchMode: safeMode,
    );

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return;
        }

        if (data['hostUid'] != user.uid ||
            data['status'] != 'waiting') {
          return;
        }

        transaction.update(
          matchReference,
          {
            'gameMode': safeMode,
            'gameData': newGameData,
          },
        );
      },
    );
  }

  Future<void> updateLobbySettings(
    String matchId, {
    int? timeLimit,
    int? passLimit,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return;
        }

        if (data['hostUid'] != user.uid ||
            data['status'] != 'waiting') {
          return;
        }

        final Map<String, dynamic> updates = {};

        if (timeLimit != null) {
          updates['timeLimit'] =
              timeLimit.clamp(10, 150);
        }

        if (passLimit != null) {
          updates['passLimit'] =
              passLimit.clamp(0, 9);
        }

        if (updates.isNotEmpty) {
          transaction.update(
            matchReference,
            updates,
          );
        }
      },
    );
  }

  Future<void> resetPrivateMatchForRematch(
    String matchId,
    String matchMode,
    Map<String, dynamic> currentPlayers,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final String safeMode =
        _sanitizeMode(matchMode);

    final Map<String, dynamic> newGameData =
        _generateGameData(
      matchMode: safeMode,
    );

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return;
        }

        if (data['isPrivate'] != true ||
            data['status'] != 'finished') {
          return;
        }

        final String currentHostUid =
            data['hostUid']?.toString() ?? '';

        if (currentHostUid != user.uid) {
          return;
        }

        final Map<String, dynamic>? livePlayers =
            _readMap(data['players']);

        if (livePlayers == null ||
            !livePlayers.containsKey(user.uid)) {
          return;
        }

        final Map<String, dynamic> resetPlayers =
            {};

        livePlayers.forEach((
          String playerUid,
          dynamic playerValue,
        ) {
          final Map<String, dynamic>? playerData =
              _readMap(playerValue);

          if (playerData == null) return;

          playerData['score'] = 0;
          playerData['isHost'] =
              playerUid == currentHostUid;

          resetPlayers[playerUid] = playerData;
        });

        transaction.update(
          matchReference,
          {
            'status': 'waiting',
            'gameMode': safeMode,
            'gameData': newGameData,
            'endTime': FieldValue.delete(),
            'startedAt': FieldValue.delete(),
            'lastMessage': FieldValue.delete(),
            'players': resetPlayers,
            'playerCount': resetPlayers.length,
          },
        );
      },
    );
  }

  Future<void> transferHost(
    String matchId,
    String oldHostUid,
    String newHostUid,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('Giriş yapılmamış.');
    }

    if (oldHostUid == newHostUid) return;

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          throw StateError('Oda bulunamadı.');
        }

        if (data['status'] != 'waiting') {
          throw StateError(
            'Kuruculuk yalnızca bekleme odasında devredilebilir.',
          );
        }

        final String actualHostUid =
            data['hostUid']?.toString() ?? '';

        final Map<String, dynamic>? players =
            _readMap(data['players']);

        if (players == null) {
          throw StateError(
            'Oyuncu verisi bozuk.',
          );
        }

        if (actualHostUid != user.uid ||
            oldHostUid != user.uid ||
            !players.containsKey(newHostUid)) {
          throw StateError(
            'Kuruculuk devretme yetkiniz yok.',
          );
        }

        transaction.update(
          matchReference,
          {
            'hostUid': newHostUid,
            'players.$oldHostUid.isHost': false,
            'players.$newHostUid.isHost': true,
          },
        );
      },
    );
  }

  Future<String?> joinPrivateMatch(
    String roomCode,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) return null;

    final String myUid = user.uid;
    final String myName =
        await _getUserName(myUid);

    final String normalizedCode =
        roomCode.trim().toUpperCase();

    if (normalizedCode.length != 6) {
      return null;
    }

    try {
      DocumentReference<Map<String, dynamic>>?
          targetMatchReference;

      final DocumentReference<Map<String, dynamic>>
          codeReference = _firestore
              .collection('privateRoomCodes')
              .doc(normalizedCode);

      final DocumentSnapshot<Map<String, dynamic>>
          codeSnapshot =
          await codeReference.get();

      final Map<String, dynamic>? codeData =
          codeSnapshot.data();

      if (codeSnapshot.exists &&
          codeData != null) {
        final String? reservedMatchId =
            codeData['matchId']?.toString();

        if (reservedMatchId != null &&
            reservedMatchId.isNotEmpty) {
          targetMatchReference = _firestore
              .collection('matches')
              .doc(reservedMatchId);
        }
      }

      // Daha önce oluşturulmuş ve rezervasyon
      // belgesi olmayan odalar için geriye
      // dönük arama.
      if (targetMatchReference == null) {
        final QuerySnapshot<Map<String, dynamic>>
            querySnapshot = await _firestore
                .collection('matches')
                .where(
                  'roomCode',
                  isEqualTo: normalizedCode,
                )
                .where(
                  'status',
                  isEqualTo: 'waiting',
                )
                .where(
                  'isPrivate',
                  isEqualTo: true,
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) {
          return null;
        }

        targetMatchReference =
            querySnapshot.docs.first.reference;
      }

      final DocumentReference<Map<String, dynamic>>
          finalMatchReference =
          targetMatchReference;

      return await _firestore
          .runTransaction<String?>(
        (Transaction transaction) async {
          final DocumentSnapshot<
                  Map<String, dynamic>>
              freshSnapshot =
              await transaction.get(
            finalMatchReference,
          );

          final Map<String, dynamic>? data =
              freshSnapshot.data();

          if (!freshSnapshot.exists ||
              data == null) {
            return null;
          }

          if (data['status'] != 'waiting' ||
              data['isPrivate'] != true) {
            return null;
          }

          final String documentRoomCode =
              data['roomCode']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  '';

          if (documentRoomCode !=
              normalizedCode) {
            return null;
          }

          final Map<String, dynamic>? players =
              _readMap(data['players']);

          if (players == null) {
            return null;
          }

          if (players.containsKey(myUid)) {
            return finalMatchReference.id;
          }

          if (players.length >=
              privateRoomCapacity) {
            return 'FULL';
          }

          players[myUid] = {
            'name': myName,
            'score': 0,
            'isHost': false,
          };

          transaction.update(
            finalMatchReference,
            {
              'players': players,
              'playerCount': players.length,
            },
          );

          return finalMatchReference.id;
        },
      );
    } catch (error) {
      return null;
    }
  }

  Future<void> startMatch(
    String matchId, {
    String? gameMode,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final Map<String, dynamic>? generatedData =
        gameMode == null
            ? null
            : _generateGameData(
                matchMode: _sanitizeMode(
                  gameMode,
                ),
              );

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return;
        }

        if (data['status'] != 'waiting') {
          return;
        }

        if (data['hostUid'] != user.uid) {
          return;
        }

        final Map<String, dynamic>? players =
            _readMap(data['players']);

        if (players == null) return;

        if (!players.containsKey(user.uid) ||
            players.length <
                minimumPlayersToStart) {
          return;
        }

        final int timeLimitSeconds = _readInt(
          data['timeLimit'],
          fallback: defaultTimeLimit,
        ).clamp(10, 150);

        final int calculatedEndTime =
            DateTime.now()
                    .millisecondsSinceEpoch +
                (timeLimitSeconds * 1000);

        final Map<String, dynamic> updates = {
          'status': 'playing',
          'startedAt':
              FieldValue.serverTimestamp(),
          'endTime': calculatedEndTime,
        };

        if (generatedData != null) {
          updates['gameData'] = generatedData;
          updates['gameMode'] =
              _sanitizeMode(gameMode!);
        }

        transaction.update(
          matchReference,
          updates,
        );
      },
    );
  }

  Future<void> cancelMatchmaking(
    String matchId,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final String myUid = user.uid;

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    try {
      await _firestore.runTransaction<void>(
        (Transaction transaction) async {
          final DocumentSnapshot<
                  Map<String, dynamic>>
              snapshot =
              await transaction.get(
            matchReference,
          );

          final Map<String, dynamic>? data =
              snapshot.data();

          if (!snapshot.exists || data == null) {
            return;
          }

          final Map<String, dynamic>? players =
              _readMap(data['players']);

          if (players == null ||
              !players.containsKey(myUid)) {
            return;
          }

          players.remove(myUid);

          if (players.isEmpty) {
            final String? roomCode =
                data['roomCode']?.toString();

            if (roomCode != null &&
                roomCode.isNotEmpty) {
              final DocumentReference<
                      Map<String, dynamic>>
                  codeReference = _firestore
                      .collection(
                        'privateRoomCodes',
                      )
                      .doc(roomCode);

              transaction.delete(codeReference);
            }

            transaction.delete(matchReference);
            return;
          }

          String currentHostUid =
              data['hostUid']?.toString() ?? '';

          if (currentHostUid == myUid) {
            final String nextHostUid =
                players.keys.first;

            currentHostUid = nextHostUid;

            final Map<String, dynamic>?
                previousHostData =
                _readMap(
              data['players'] is Map
                  ? (data['players']
                      as Map)[myUid]
                  : null,
            );

            if (previousHostData != null) {
              previousHostData['isHost'] = false;
            }

            final Map<String, dynamic>?
                nextHostData =
                _readMap(players[nextHostUid]);

            if (nextHostData != null) {
              nextHostData['isHost'] = true;
              players[nextHostUid] =
                  nextHostData;
            }
          }

          transaction.update(
            matchReference,
            {
              'hostUid': currentHostUid,
              'players': players,
              'playerCount': players.length,
            },
          );
        },
      );
    } catch (_) {}
  }

  /// Aktif maç sırasında oyuncuyu tamamen silmek
  /// yerine pes etmiş olarak işaretler.
  Future<void> forfeitMatch(
    String matchId,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final String myUid = user.uid;

    final DocumentReference<Map<String, dynamic>>
        matchReference =
        _firestore.collection('matches').doc(
              matchId,
            );

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(matchReference);

        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return;
        }

        if (data['status'] != 'playing') {
          return;
        }

        final Map<String, dynamic>? players =
            _readMap(data['players']);

        if (players == null ||
            !players.containsKey(myUid)) {
          return;
        }

        final Map<String, dynamic>? myPlayerData =
            _readMap(players[myUid]);

        if (myPlayerData == null) return;

        if (myPlayerData['state'] ==
            'forfeited') {
          return;
        }

        transaction.update(
          matchReference,
          {
            'players.$myUid.state':
                'forfeited',
            'players.$myUid.forfeitedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}