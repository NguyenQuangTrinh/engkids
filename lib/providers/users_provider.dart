// lib/providers/users_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../service/firebase_users_service.dart';

// Provider này nhận một chuỗi `query` và trả về một Future chứa danh sách kết quả.
// Chúng ta dùng `.family` vì provider này cần một tham số để hoạt động.
final userSearchProvider = FutureProvider.family<List<UserProfile>, String>((ref, query) {
  // Nếu query rỗng, không tìm kiếm
  if (query.trim().isEmpty) {
    return [];
  }
  
  // Lấy ID của người dùng hiện tại để loại chính họ ra khỏi kết quả
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Gọi service để thực hiện tìm kiếm
  return FirebaseUsersService.instance.searchUsers(query, currentUserId);
});