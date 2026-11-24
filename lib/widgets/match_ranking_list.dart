import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Çok oyunculu maç sonu sıralama listesi (arkadaş ekleme düğmesiyle).
class MatchRankingList extends StatelessWidget {
  const MatchRankingList({
    super.key,
    required this.sortedPlayers,
    required this.myUid,
    required this.friendUids,
    required this.pendingRequestUids,
    required this.onAddFriend,
  });

  /// Skora göre azalan sıralı oyuncular (uid -> {name, score, ...}).
  final List<MapEntry<String, dynamic>> sortedPlayers;
  final String myUid;
  final Set<String> friendUids;
  final Set<String> pendingRequestUids;
  final void Function(String uid, String name) onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Container(
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedPlayers.length,
                        itemBuilder: (context, index) {
                          var p = sortedPlayers[index];
                          bool isMe = p.key == myUid;

                          bool isFriend = friendUids.contains(p.key);
                          bool isPending = pendingRequestUids.contains(p.key);

                          Color rankColor = index == 0
                              ? Colors.amber
                              : (index == 1 ? Colors.grey[400]! : (index == 2 ? Colors.brown[300]! : Colors.white54));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: isMe ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isMe ? AppColors.primary : Colors.transparent)),
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
                                        : () => onAddFriend(p.key, p.value['name'].toString()),
                                    icon: Icon(
                                      isPending ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded,
                                      color: isPending ? Colors.greenAccent : AppColors.accent,
                                      size: 24,
                                    ),
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    );
  }
}
