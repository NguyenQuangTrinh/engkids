// lib/widgets/auth_wrapper.dart

import 'dart:developer' as developer;
import 'package:engkids/screens/home_screen.dart';
import 'package:engkids/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <<< Import
import '../providers/auth_provider.dart';                 // <<< Import

// Chuyển sang ConsumerWidget
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dùng ref.watch để lắng nghe trạng thái đăng nhập từ provider
    final authState = ref.watch(authStateChangesProvider);

    // Dùng .when() để xử lý các trạng thái một cách an toàn và rõ ràng
    return authState.when(
      data: (user) {
        // Nếu có dữ liệu (user không phải null), người dùng đã đăng nhập
        if (user != null) {
          developer.log("AuthWrapper: User is signed in (${user.uid}). Navigating to HomeScreen.");
          return const HomeScreen();
        } 
        // Nếu dữ liệu là null, người dùng chưa đăng nhập
        else {
          developer.log("AuthWrapper: User is not signed in. Navigating to LoginScreen.");
          return const LoginScreen();
        }
      },
      // Khi provider đang chờ kết nối stream, hiển thị loading
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // Khi có lỗi, hiển thị thông báo
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Đã xảy ra lỗi: $error')),
      ),
    );
  }
}