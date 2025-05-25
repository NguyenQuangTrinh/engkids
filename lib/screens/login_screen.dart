import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';    // Import UserCredential
import 'package:flutter/material.dart';

import '../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // Tạo instance AuthService
  bool _isSigningIn = false; // State để quản lý trạng thái đang đăng nhập

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return; // Không cho phép nhấn nhiều lần khi đang xử lý

    setState(() {
      _isSigningIn = true; // Bắt đầu quá trình đăng nhập
    });

    UserCredential? userCredential = await _authService.signInWithGoogle(context: context);

    if (mounted) { // Kiểm tra widget còn tồn tại không
      setState(() {
        _isSigningIn = false; // Kết thúc quá trình đăng nhập
      });
    }

    if (userCredential != null) {
      // Đăng nhập thành công. AuthWrapper sẽ tự động điều hướng.
      developer.log("LoginScreen: Đăng nhập Google thành công cho ${userCredential.user?.displayName}");
    } else {
      // Đăng nhập thất bại hoặc bị hủy (thông báo lỗi có thể đã được AuthService hiển thị)
      developer.log("LoginScreen: Đăng nhập Google thất bại hoặc bị hủy.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo hoặc tên ứng dụng
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                    shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.2), offset: Offset(1.0, 1.0))],
                  ),
                  children: <TextSpan>[
                    TextSpan(text: 'Eng', style: TextStyle(color: Colors.redAccent[700])),
                    TextSpan(text: 'Kids', style: TextStyle(color: Colors.green[700])),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Học tiếng Anh thật vui!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.blueGrey[700]),
              ),
              SizedBox(height: 50),

              // Nút Đăng nhập bằng Google
              _isSigningIn
                  ? Center(child: CircularProgressIndicator()) // Hiển thị loading khi đang đăng nhập
                  : ElevatedButton.icon(
                icon: Image.asset(
                  'assets/images/logogoogle.webp', // Đảm bảo bạn có file này trong assets
                  height: 24.0,
                  width: 24.0, // Thêm width để đảm bảo tỷ lệ
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text("Đăng nhập với Google", style: TextStyle(fontSize: 16)),
                ),
                onPressed: _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2,
                ),
              ),

              SizedBox(height: 20),
              // TODO: Thêm các tùy chọn đăng nhập khác (Email/Password) hoặc nút Đăng ký nếu cần
              // TextButton(
              //   onPressed: () {
              //     // Điều hướng đến màn hình đăng ký (nếu có)
              //   },
              //   child: Text("Chưa có tài khoản? Đăng ký ngay!"),
              // )
            ],
          ),
        ),
      ),
    );
  }
}