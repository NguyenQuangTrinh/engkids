// lib/providers/friends_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../service/firebase_users_service.dart';
import 'auth_provider.dart'; // <<< THÊM IMPORT QUAN TRỌNG NÀY

// Provider này lắng nghe stream các lời mời kết bạn đã nhận
final friendRequestsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  // <<< THAY ĐỔI LỚN BẮT ĐẦU TỪ ĐÂY
  // 1. Lắng nghe trạng thái đăng nhập
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

  // 2. Nếu người dùng chưa đăng nhập, trả về stream rỗng
  if (user == null) {
    return Stream.value([]);
  }

  // 3. Nếu đã đăng nhập, trả về stream dữ liệu của chính người dùng đó
  return FirebaseUsersService.instance
      .getFriendRequestsStream()
      .map((snapshot) => snapshot.docs);
  // KẾT THÚC THAY ĐỔI
});

// Provider này lắng nghe stream danh sách bạn bè đã được chấp nhận
final friendsListProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  // <<< ÁP DỤNG THAY ĐỔI TƯƠNG TỰ
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseUsersService.instance
      .getFriendsListStream()
      .map((snapshot) => snapshot.docs);
});

// Helper provider để lấy thông tin chi tiết của một user từ UID (không đổi)
final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  if (userId.isEmpty) return null;
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists) {
    return UserProfile.fromMap(doc.data()!);
  }
  return null;
});
