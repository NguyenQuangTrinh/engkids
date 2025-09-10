// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <<< Import
import '../providers/auth_provider.dart'; // <<< Import

// Chuyển sang ConsumerStatefulWidget để vừa quản lý state cục bộ (_isSigningIn)
// vừa có thể dùng `ref`
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
    });

    // Dùng `ref.read` để gọi hàm từ provider
    // `read` được dùng trong các hàm callback như onPressed
    await ref.read(authServiceProvider).signInWithGoogle(context: context);

    if (mounted) {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện không thay đổi nhiều
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Eng',
                      style: TextStyle(color: Colors.redAccent[700]),
                    ),
                    TextSpan(
                      text: 'Learn',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Học tiếng Anh thật vui!",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              _isSigningIn
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/logogoogle.webp',
                      height: 24.0,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Đăng nhập với Google",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    onPressed: _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
