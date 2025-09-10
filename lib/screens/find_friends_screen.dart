// lib/screens/find_friends_screen.dart

import 'dart:async';
import 'package:engkids/providers/friends_provider.dart';
import 'package:engkids/service/firebase_users_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/users_provider.dart';

class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // `searchQueryProvider` sẽ giữ chuỗi tìm kiếm hiện tại.
  // Điều này giúp tách biệt trạng thái query ra khỏi UI.
  final searchQueryProvider = StateProvider<String>((ref) => '');
  final Set<String> _sentRequestUids = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm xử lý khi người dùng gõ, có "debounce" để tránh gọi Firebase liên tục
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Sau 500ms không gõ, mới cập nhật provider để bắt đầu tìm kiếm
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  Future<void> _sendRequest(String recipientId) async {
    await FirebaseUsersService.instance.sendFriendRequest(recipientId);
    setState(() {
      _sentRequestUids.add(recipientId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã gửi lời mời kết bạn!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe chuỗi tìm kiếm
    final searchQuery = ref.watch(searchQueryProvider);
    // Lắng nghe kết quả tìm kiếm dựa trên chuỗi đó
    final searchResult = ref.watch(userSearchProvider(searchQuery));

    final friendsListAsync = ref.watch(friendsListProvider);

    final friendUids =
        friendsListAsync.asData?.value.map((doc) {
          // Lấy ID của người bạn (không phải ID của người dùng hiện tại)
          final List<dynamic> users =
              ((doc.data() as Map<String, dynamic>?)?['users']) ?? [];
          final currentUserId = FirebaseUsersService.instance.userId;
          return users.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
        }).toSet() ??
        <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tìm bạn bè"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Tìm theo tên hiển thị...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: searchResult.when(
              data: (users) {
                if (searchQuery.trim().isEmpty) {
                  return const Center(
                    child: Text("Nhập tên để bắt đầu tìm kiếm."),
                  );
                }
                if (users.isEmpty) {
                  return const Center(
                    child: Text("Không tìm thấy người dùng nào."),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final bool hasSentRequest = _sentRequestUids.contains(
                      user.uid,
                    );
                    final bool isAlreadyFriend = friendUids.contains(user.uid);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.photoURL),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                      trailing:
                          isAlreadyFriend
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                semanticLabel: "Đã là bạn",
                              )
                              : ElevatedButton(
                                onPressed:
                                    hasSentRequest
                                        ? null
                                        : () => _sendRequest(user.uid),
                                child: Text(
                                  hasSentRequest ? "Đã gửi" : "Kết bạn",
                                ),
                              ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text("Lỗi: $error")),
            ),
          ),
        ],
      ),
    );
  }
}
