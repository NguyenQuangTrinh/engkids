// lib/screens/settings_screen.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true; // Trạng thái đang tải cài đặt đã lưu
  bool _isSfxEnabled = true; // Giá trị mặc định cho Âm thanh hiệu ứng (SFX)
  // Thêm các biến state cho cài đặt khác ở đây (ví dụ: _isBgmEnabled)

  // Key để lưu vào SharedPreferences
  static const String sfxEnabledKey = 'settings_sfx_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Tải cài đặt đã lưu khi màn hình khởi tạo
  }

  // Hàm tải cài đặt từ SharedPreferences
  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; }); // Bắt đầu loading
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Lấy giá trị đã lưu, nếu chưa có thì dùng giá trị mặc định (true)
        _isSfxEnabled = prefs.getBool(sfxEnabledKey) ?? true;
        // Tải các cài đặt khác ở đây
      });
    } catch (e) {
      developer.log("Lỗi khi tải cài đặt: $e");
      // Có thể hiển thị lỗi cho người dùng nếu cần
    } finally {
      setState(() { _isLoading = false; }); // Kết thúc loading
    }
  }

  // Hàm lưu cài đặt vào SharedPreferences
  Future<void> _saveSfxSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(sfxEnabledKey, value);
      developer.log("Đã lưu cài đặt SFX: $value");
    } catch (e) {
      developer.log("Lỗi khi lưu cài đặt SFX: $e");
      // Có thể hiển thị lỗi cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu cài đặt âm thanh!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng context được ghi nhận vào lúc này (1:18 PM, 13/05/2025, TP. HCM)
    // để có thể thực hiện build giao diện.

    return Scaffold(
      appBar: AppBar(
        title: Text("Cài đặt EngKids"),
        backgroundColor: Colors.deepPurpleAccent, // Màu khác biệt cho màn hình cài đặt
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Hiển thị loading khi đang tải cài đặt
          : ListView( // Dùng ListView để dễ dàng thêm nhiều cài đặt sau này
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        children: [
          // --- Mục Âm thanh Hiệu ứng (SFX) ---
          ListTile(
            leading: Icon(Icons.volume_up_rounded, color: Colors.blueAccent), // Icon âm thanh
            title: Text(
              "Âm thanh hiệu ứng (SFX)",
              style: TextStyle(fontSize: 16),
            ),
            subtitle: Text("Bật/tắt âm thanh khi nhấn nút, đúng/sai..."),
            trailing: Switch(
              value: _isSfxEnabled,
              onChanged: (newValue) {
                setState(() {
                  _isSfxEnabled = newValue; // Cập nhật trạng thái trên UI
                });
                _saveSfxSetting(newValue); // Lưu giá trị mới vào SharedPreferences
                // TODO: Gọi hàm cập nhật trạng thái âm thanh thực tế trong ứng dụng (nếu cần)
              },
              activeColor: Colors.green, // Màu khi bật
            ),
          ),

          Divider(), // Đường kẻ phân cách

          // --- Placeholder cho các cài đặt khác ---
          ListTile(
            leading: Icon(Icons.music_note_rounded, color: Colors.grey),
            title: Text("Nhạc nền (BGM)", style: TextStyle(color: Colors.grey)),
            subtitle: Text("Bật/tắt nhạc nền"),
            trailing: Switch(
              value: false, // Giá trị placeholder
              onChanged: null, // Vô hiệu hóa
            ),
            enabled: false, // Làm mờ đi
          ),

          Divider(),

          ListTile(
            leading: Icon(Icons.color_lens_outlined, color: Colors.grey),
            title: Text("Chọn Giao diện (Theme)", style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            onTap: null, // Vô hiệu hóa
            enabled: false,
          ),

          Divider(),

          // Thêm các cài đặt khác tại đây...

        ],
      ),
    );
  }
}