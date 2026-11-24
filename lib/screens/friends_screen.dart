import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  void _acceptRequest(String senderUid, String senderName) async {
    AudioService.instance.playClick();
    await UserService.instance.acceptFriendRequest(senderUid, senderName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$senderName ile arkadaş oldunuz!'), backgroundColor: Colors.green),
      );
    }
  }

  void _rejectRequest(String senderUid) async {
    AudioService.instance.playClick();
    await UserService.instance.rejectFriendRequest(senderUid);
  }

  void _confirmRemoveFriend(String friendUid, String friendName) {
    AudioService.instance.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Arkadaşı Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '$friendName adlı kişiyi arkadaş listenden çıkarmak istediğine emin misin?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playClick();
              Navigator.pop(context);
            },
            child: const Text('İptal', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friendUid, friendName);
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _removeFriend(String friendUid, String friendName) async {
    await UserService.instance.removeFriend(friendUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$friendName silindi.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddFriendDialog(int currentFriendCount) {
    AudioService.instance.playClick();

    if (currentFriendCount >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimum 50 arkadaşa sahip olabilirsin! Önce listeden yer açmalısın.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController idController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF1D1B36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Arkadaş Ekle', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131127),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Senin Oyuncu ID\'n:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Text(
                                myUid,
                                style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C5CFC)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: myUid));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ID Kopyalandı!'), backgroundColor: Color(0xFF7C5CFC)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: idController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Arkadaşının ID'sini gir",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: const Color(0xFF131127),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CEC9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              String targetUid = idController.text.trim();
                              if (targetUid.isEmpty || targetUid == myUid) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Geçerli bir ID girin!'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              setDialogState(() => isSubmitting = true);

                              try {
                                final userCheck = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
                                if (!userCheck.exists) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bu ID ile eşleşen bir oyuncu bulunamadı.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final existingFriend = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(myUid)
                                    .collection('friends')
                                    .doc(targetUid)
                                    .get();
                                if (existingFriend.exists) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(content: Text('Bu kişiyle zaten arkadaşsınız!'), backgroundColor: Colors.orange),
                                    );
                                  }
                                  return;
                                }

                                String myName = UserService.instance.cachedUser?.username ?? '';
                                if (myName.isEmpty) {
                                  final me = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
                                  myName = me.data()?['username'] ?? me.data()?['name'] ?? 'Oyuncu';
                                }

                                // Karşı tarafın friendRequests koleksiyonunu .get() ile okumadan doğrudan yazıyoruz
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(targetUid)
                                    .collection('friendRequests')
                                    .doc(myUid)
                                    .set({
                                  'uid': myUid,
                                  'fromUid': myUid,
                                  'name': myName,
                                  'username': myName,
                                  'timestamp': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Arkadaşlık isteği gönderildi!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                debugPrint("Arkadaş ekleme hatası: $e");
                                setDialogState(() => isSubmitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('İstek gönderilemedi. Bağlantınızı kontrol edin.'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('İstek Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showFriendProfile(Map<String, dynamic> friendData) {
    AudioService.instance.playClick();

    final String username = friendData['username'] ?? friendData['name'] ?? 'Oyuncu';
    final String avatar = friendData['avatar'] ?? 'boy';
    final String border = friendData['selectedBorder'] ?? 'none';
    final int totalScore = friendData['totalScore'] ?? 0;
    final int gamesPlayed = friendData['gamesPlayed'] ?? 0;
    final String rankName = friendData['rankName'] ?? 'Çaylak';
    final String status = friendData['status'] ?? 'çevrimdışı';

    final int highestScore = friendData['highestSingleMatchScore'] ?? 0;
    final String longestWord = friendData['longestWord'] ?? '-';
    final int mathMatches = friendData['exactMathMatches'] ?? 0;

    Color statusColor = Colors.grey;
    if (status == 'çevrimiçi') statusColor = Colors.green;
    if (status == 'oyunda') statusColor = Colors.orange;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B36),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00CEC9).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF131127),
                    backgroundImage: AssetImage('assets/avatars/$avatar.png'),
                  ),
                  if (border != 'none')
                    Image.asset(
                      'assets/borders/$border.png',
                      width: 104,
                      height: 104,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(username, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CFC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF7C5CFC).withValues(alpha: 0.5)),
                ),
                child: Text(rankName, style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Puan', _formatNumber(totalScore), Icons.star_rounded, Colors.amber),
                  _buildStatColumn('Oynanan', '$gamesPlayed', Icons.sports_esports_rounded, const Color(0xFF00CEC9)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF131127), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tek Maç Rekoru:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('$highestScore P', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('En Uzun Kelime:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(longestWord, style: const TextStyle(color: Color(0xFF7C5CFC), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sayısal Tam İsabet:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('$mathMatches', style: const TextStyle(color: Color(0xFFFD79A8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131127),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  onPressed: () {
                    AudioService.instance.playClick();
                    Navigator.pop(context);
                  },
                  child: const Text('Kapat', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF131127),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D1B36),
          elevation: 0,
          title: const Text('Sosyal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00CEC9),
            labelColor: Color(0xFF00CEC9),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Arkadaşlarım', icon: Icon(Icons.people_alt_rounded)),
              Tab(text: 'Gelen İstekler', icon: Icon(Icons.mail_rounded)),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: UserService.instance.getFriendsStream(),
          builder: (context, friendSnapshot) {
            final friends = friendSnapshot.data ?? [];
            return Stack(
              children: [
                TabBarView(
                  children: [
                    _buildFriendsList(friends),
                    _buildRequestsList(),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showAddFriendDialog(friends.length),
                    backgroundColor: const Color(0xFF7C5CFC),
                    icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                    label: const Text('ID ile Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendsList(List<Map<String, dynamic>> friends) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, color: Colors.white.withValues(alpha: 0.2), size: 64),
            const SizedBox(height: 16),
            Text('Henüz hiç arkadaşın yok.\n(0/50)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
          child: Text('Kota: ${friends.length}/50', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final friendUid = friend['uid'];
              final friendName = friend['username'] ?? friend['name'] ?? 'Oyuncu';
              final status = friend['status'] ?? 'çevrimdışı';
              final border = friend['selectedBorder'] ?? 'none';

              Color statusColor = Colors.grey;
              if (status == 'çevrimiçi') statusColor = Colors.green;
              if (status == 'oyunda') statusColor = Colors.orange;

              return GestureDetector(
                onTap: () => _showFriendProfile(friend),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1B36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF00CEC9).withValues(alpha: 0.2),
                                backgroundImage: AssetImage('assets/avatars/${friend['avatar'] ?? 'boy'}.png'),
                              ),
                              if (border != 'none')
                                Image.asset(
                                  'assets/borders/$border.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                ),
                            ],
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1D1B36), width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(friendName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                        onPressed: () => _confirmRemoveFriend(friendUid, friendName),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: UserService.instance.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFC)));
        }
        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded, color: Colors.white.withValues(alpha: 0.2), size: 64),
                const SizedBox(height: 16),
                Text('Bekleyen arkadaşlık isteği yok.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index].data() as Map<String, dynamic>;
            final senderUid = req['uid'] ?? requests[index].id;
            final senderName = req['name'] ?? req['username'] ?? 'Gizemli Oyuncu';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1B36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF7C5CFC).withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Color(0xFF7C5CFC)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(senderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                        onPressed: () => _acceptRequest(senderUid, senderName),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                        onPressed: () => _rejectRequest(senderUid),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}