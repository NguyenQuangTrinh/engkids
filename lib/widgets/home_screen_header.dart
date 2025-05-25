import 'package:flutter/material.dart';

class HomeScreenHeader extends StatelessWidget {
  final Color engColor;
  final Color kidsColor;
  final String? logoFontFamily; // Tùy chọn: có thể lấy từ Theme
  final VoidCallback onSettingsPressed;
  final VoidCallback onProfilePressed;

  const HomeScreenHeader({
    super.key,
    required this.engColor,
    required this.kidsColor,
    this.logoFontFamily,
    required this.onSettingsPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy font từ Theme nếu logoFontFamily không được cung cấp
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
                fontFamily: effectiveFontFamily, // Sử dụng font đã xác định
              ),
              children: [
                TextSpan(text: 'Eng', style: TextStyle(color: engColor)),
                TextSpan(text: 'Kids', style: TextStyle(color: kidsColor)),
              ],
            ),
          ),
          // Placeholder Icons (Settings, Profile)
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Colors.blueGrey[600]),
                onPressed: onSettingsPressed, // Gọi callback được truyền vào
                tooltip: 'Cài đặt',
              ),
              IconButton(
                icon: Icon(Icons.person_outline_rounded, color: Colors.blueGrey[600]),
                onPressed: onProfilePressed, // Gọi callback được truyền vào
                tooltip: 'Tài khoản',
              ),
            ],
          ),
        ],
      ),
    );
  }
}