// lib/service/auth_service.dart

import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engkids/providers/achievements_provider.dart';
import 'package:engkids/providers/friends_provider.dart';
import 'package:engkids/providers/quiz_provider.dart';
import 'package:engkids/providers/vocabulary_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart'; // Cần thiết nếu bạn muốn hiển thị SnackBar từ service

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream để lắng nghe sự thay đổi trạng thái đăng nhập (AuthWrapper sẽ dùng)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Lấy người dùng hiện tại
  User? get currentUser => _firebaseAuth.currentUser;

  // --- Đăng nhập bằng Google ---
  Future<UserCredential?> signInWithGoogle({BuildContext? context}) async {
    // context là tùy chọn, chỉ cần nếu bạn muốn hiển thị SnackBar trực tiếp từ đây
    // Cách tốt hơn có thể là ném lỗi và để UI xử lý việc hiển thị thông báo
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        developer.log('Đăng nhập Google bị hủy bởi người dùng.');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã hủy đăng nhập bằng Google.')),
          );
        }
        return null;
      }

      final GoogleSignInAuthentication? googleAuth =
          await googleUser.authentication;
      if (googleAuth == null) {
        developer.log('Không thể lấy thông tin xác thực Google.');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy thông tin xác thực Google.'),
            ),
          );
        }
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      // <<< PHẦN MỚI: TẠO HỒ SƠ CÔNG KHAI KHI ĐĂNG NHẬP
      if (user != null) {
        // Tham chiếu đến document của người dùng trong collection 'users'
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final doc = await userDocRef.get();

        // Chỉ tạo document nếu nó chưa tồn tại
        if (!doc.exists) {
          await userDocRef.set({
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'email': user.email,
            'uid': user.uid,
            'createdAt': Timestamp.now(), // Thời gian tạo tài khoản
          });
          developer.log(
            'Đã tạo hồ sơ công khai cho người dùng mới: ${user.uid}',
          );
        }
      }
      // KẾT THÚC PHẦN MỚI

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Lỗi FirebaseAuthException khi đăng nhập Google: ${e.code} - ${e.message}',
      );
      String errorMessage = "Lỗi đăng nhập Google: ${e.message ?? e.code}";
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage =
            'Tài khoản này đã tồn tại với phương thức đăng nhập khác.';
      }
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      return null;
    } catch (e) {
      developer.log('Lỗi không xác định khi đăng nhập Google: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xảy ra lỗi không mong muốn trong quá trình đăng nhập.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(name);
        // Rất quan trọng: Tải lại thông tin user để thay đổi có hiệu lực ngay
        await user.reload();
        // Thông báo cho các stream về sự thay đổi user
        _firebaseAuth.currentUser!.reload();
      } catch (e) {
        developer.log("Lỗi khi cập nhật tên: $e");
        rethrow; // Ném lại lỗi để UI xử lý
      }
    }
  }

  // --- Đăng xuất ---
  Future<void> signOut({BuildContext? context, WidgetRef? ref}) async {
    try {
      await _googleSignIn.signOut(); // Quan trọng: Đăng xuất khỏi Google trước
      await _firebaseAuth.signOut(); // Sau đó đăng xuất khỏi Firebase
      ref!.invalidate(vocabularySetsProvider);
      ref.invalidate(friendsListProvider);
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(quizProvider);
      ref.invalidate(achievementsProvider);
      developer.log("Đã đăng xuất thành công.");
    } catch (e) {
      developer.log("Lỗi khi đăng xuất: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // TODO: Thêm các phương thức khác nếu cần (đăng ký/đăng nhập email, reset password...)
}
