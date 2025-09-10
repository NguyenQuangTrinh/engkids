// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth_service.dart';

// Provider này chỉ đơn giản là cung cấp một instance của AuthService
// để các provider hoặc widget khác có thể gọi các hàm của nó (signIn, signOut).
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider này lắng nghe stream `authStateChanges` từ Firebase.
// Nó sẽ tự động thông báo cho các widget đang "watch" nó mỗi khi
// trạng thái đăng nhập thay đổi (từ đăng nhập sang đăng xuất và ngược lại).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  // Nó "watch" authServiceProvider để lấy instance và truy cập stream.
  return ref.watch(authServiceProvider).authStateChanges;
});