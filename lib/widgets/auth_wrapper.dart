import 'dart:developer' as developer;

import 'package:engkids/screens/home_screen.dart';    // Import HomeScreen
import 'package:engkids/screens/login_screen.dart';  // Import LoginScreen (sẽ tạo ở bước sau)
import 'package:firebase_auth/firebase_auth.dart';    // Import User từ firebase_auth
import 'package:flutter/material.dart';

import '../service/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // Tạo instance của AuthService

    return StreamBuilder<User?>(
      stream: authService.authStateChanges, // Lắng nghe stream trạng thái đăng nhập
      builder: (context, snapshot) {
        // Trường hợp đang chờ kết nối hoặc kiểm tra trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(), // Hiển thị loading
            ),
          );
        }

        // Trường hợp có lỗi với stream (hiếm gặp với authStateChanges)
        if (snapshot.hasError) {
          developer.log("Lỗi Stream AuthStateChanges: ${snapshot.error}");
          return const Scaffold(
            body: Center(
              child: Text("Đã xảy ra lỗi. Vui lòng thử lại!"),
            ),
          );
        }

        // Kiểm tra dữ liệu từ snapshot
        if (snapshot.hasData) {
          // Nếu snapshot.data (User) không null -> Người dùng đã đăng nhập
          developer.log("Người dùng đã đăng nhập: ${snapshot.data!.uid}");
          return HomeScreen(); // Hiển thị HomeScreen
        } else {
          // Nếu snapshot.data là null -> Người dùng chưa đăng nhập
          developer.log("Người dùng chưa đăng nhập.");
          return LoginScreen(); // Hiển thị LoginScreen
        }
      },
    );
  }
}