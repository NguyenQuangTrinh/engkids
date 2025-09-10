// lib/widgets/home_screen_header.dart

import 'package:engkids/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <<< Import
import '../providers/auth_provider.dart';                 // <<< Import
import '../screens/settings_screen.dart';                 // Import để điều hướng

// <<< Chuyển thành ConsumerWidget
class HomeScreenHeader extends ConsumerWidget {
  final Color engColor;
  final Color kidsColor;
  final String? logoFontFamily;

  const HomeScreenHeader({
    super.key,
    required this.engColor,
    required this.kidsColor,
    this.logoFontFamily,
    // Bỏ các callback cũ: onSettingsPressed, onProfilePressed
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <<< Thêm WidgetRef ref
    // Lấy thông tin người dùng từ provider
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;

    final effectiveFontFamily = logoFontFamily ?? Theme.of(context).textTheme.titleLarge?.fontFamily ?? 'Arial';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Text
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: effectiveFontFamily,
              ),
              children: [
                TextSpan(text: 'Eng', style: TextStyle(color: engColor)),
                TextSpan(text: 'Learn', style: TextStyle(color: kidsColor)),
              ],
            ),
          ),

          // Các nút điều khiển
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Colors.blueGrey[600]),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                tooltip: 'Cài đặt',
              ),
              // Hiển thị Avatar và menu nếu đã đăng nhập
               if (user != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null ? const Icon(Icons.person_outline_rounded, size: 20, color: Colors.grey) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}