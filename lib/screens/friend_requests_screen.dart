// lib/screens/friends_screen.dart

import 'dart:developer' as developer;

import 'package:engkids/providers/challenges_provider.dart';
import 'package:engkids/screens/game/tic_tac_toe_screen.dart';
import 'package:engkids/screens/game/waiting_screen.dart';
import 'package:engkids/service/realtime_game_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/friends_provider.dart';
import '../service/firebase_users_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'find_friends_screen.dart'; // Import để có nút tìm bạn

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe cả 2 stream: lời mời và danh sách bạn bè
    final challengesAsyncValue = ref.watch(gameChallengesProvider);
    final friendsAsyncValue = ref.watch(friendsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bạn bè"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FindFriendsScreen()));
            },
            tooltip: "Tìm bạn mới",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Làm mới cả hai provider khi người dùng kéo
          ref.invalidate(friendRequestsProvider);
          ref.invalidate(friendsListProvider);
        },
        child: ListView(
          children: [
            // --- KHU VỰC LỜI MỜI KẾT BẠN ---
            challengesAsyncValue.when(
              data: (challengeDocs) {
                if (challengeDocs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Lời mời thách đấu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: challengeDocs.length,
                      itemBuilder: (context, index) {
                        return _GameChallengeTile(challengeDoc: challengeDocs[index]);
                      },
                    ),
                    const Divider(height: 30, thickness: 1),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Lỗi tải lời mời: $err", style: const TextStyle(color: Colors.red)),
              ),
            ),

            // --- KHU VỰC DANH SÁCH BẠN BÈ ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Danh sách bạn bè", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            friendsAsyncValue.when(
              data: (friendDocs) {
                if (friendDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text("Hãy tìm và kết bạn để cùng nhau học tập!"),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friendDocs.length,
                  itemBuilder: (context, index) {
                    return _FriendTile(friendDoc: friendDocs[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Lỗi tải danh sách bạn bè: $err", style: const TextStyle(color: Colors.red))),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CON CHO MỘT LỜI MỜI KẾT BẠN ---
class _FriendRequestTile extends ConsumerWidget {
  final DocumentSnapshot requestDoc;
  const _FriendRequestTile({required this.requestDoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestData = requestDoc.data() as Map<String, dynamic>;
    final senderId = requestData['requestedBy'];
    final senderProfile = ref.watch(userProfileProvider(senderId));
    final usersService = FirebaseUsersService.instance;

    return senderProfile.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(profile.photoURL)),
            title: Text(profile.displayName),
            subtitle: Text("${profile.email} muốn kết bạn."),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => usersService.acceptFriendRequest(senderId),
                  tooltip: "Chấp nhận",
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => usersService.removeOrDeclineFriendship(senderId),
                  tooltip: "Từ chối",
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const ListTile(title: Text("Đang tải...")),
      error: (err, stack) => ListTile(title: Text("Lỗi tải profile: $err")),
    );
  }
}

class _GameChallengeTile extends ConsumerWidget {
  final DocumentSnapshot challengeDoc;
  const _GameChallengeTile({required this.challengeDoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeData = challengeDoc.data() as Map<String, dynamic>;
    final challengerId = challengeData['challengerId'];
    final challengerProfile = ref.watch(userProfileProvider(challengerId));
    
    return challengerProfile.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Card(
          color: Colors.orange[50],
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(profile.photoURL)),
            title: Text("${profile.displayName} thách đấu bạn!"),
            trailing: ElevatedButton(
              // <<< THÊM LOG VÀ TRY-CATCH VÀO ĐÂY
               onPressed: () async {
                // <<< THAY ĐỔI Ở ĐÂY: Truyền cả object `profile` vào
                final sessionId = await RealtimeGameService.instance.createGameSession(profile);
                
                if (sessionId != null && context.mounted) {
                  await FirebaseUsersService.instance.acceptGameChallenge(challengeDoc.id, sessionId);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TicTacToeScreen(sessionId: sessionId)));
                }
              },
              child: const Text("Chấp nhận"),
            ),
          ),
        );
      },
      loading: () => const ListTile(title: Text("Đang tải lời mời...")),
      error: (err, stack) => ListTile(title: Text("Lỗi: $err")),
    );
  }
}


// --- WIDGET CON CHO MỘT NGƯỜI BẠN ---
class _FriendTile extends ConsumerWidget {
  final DocumentSnapshot friendDoc;
  const _FriendTile({required this.friendDoc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendData = friendDoc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseUsersService.instance.userId;
    final friendId = (friendData['users'] as List).firstWhere((id) => id != currentUserId);
    final friendProfile = ref.watch(userProfileProvider(friendId));

    return friendProfile.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(profile.photoURL)),
          title: Text(profile.displayName),
          subtitle: Text(profile.email),
          // <<< THÊM NÚT THÁCH ĐẤU
          trailing: IconButton(
            icon: const Icon(Icons.gamepad_rounded, color: Colors.indigo),
            onPressed: () async {
              final challengeId = await FirebaseUsersService.instance.sendGameChallenge(profile.uid);
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingScreen(challengeId: challengeId)));
              }
            },
            tooltip: "Thách đấu",
          ),
        );
      },
      loading: () => const ListTile(title: Text("Đang tải...")),
      error: (err, stack) => ListTile(title: Text("Lỗi tải profile: $err")),
    );
  }
}

