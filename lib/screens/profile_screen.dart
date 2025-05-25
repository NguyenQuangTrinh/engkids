import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>(); // Key cho Form

  // Key để lưu tên vào SharedPreferences
  static const String userNameKey = 'profile_user_name';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    setState(() { _isLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedName = prefs.getString(userNameKey);
      if (savedName != null) {
        _nameController.text = savedName;
      }
    } catch (e) {
      developer.log("Lỗi khi tải tên người dùng: $e");
      // Xử lý lỗi (ví dụ: hiển thị SnackBar)
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _saveUserName() async {
    if (_formKey.currentState?.validate() ?? false) { // Kiểm tra form hợp lệ
      final String nameToSave = _nameController.text.trim();
      setState(() { _isLoading = true; });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userNameKey, nameToSave);
        developer.log("Đã lưu tên: $nameToSave");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu thông tin!'),
              backgroundColor: Colors.green,
            ),
          );
          // Trả về true để báo hiệu HomeScreen cần cập nhật
          Navigator.pop(context, true);
        }
      } catch (e) {
        developer.log("Lỗi khi lưu tên: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi lưu thông tin!'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Quan trọng: giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin EngKid"),
        backgroundColor: Colors.teal, // Màu sắc riêng cho ProfileScreen
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form( // Bọc nội dung bằng Form để validate
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Tên của bé:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Nhập tên của bé...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.face_retouching_natural_rounded),
                ),
                validator: (value) { // Validate tên không được trống
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên của bé';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words, // Viết hoa chữ cái đầu mỗi từ
              ),
              SizedBox(height: 30),
              // TODO: Thêm phần chọn Avatar ở đây (nâng cấp sau)
              // Ví dụ:
              // Text("Chọn Avatar:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              // SizedBox(height: 10),
              // Container(height: 100, color: Colors.grey[200], child: Center(child: Text("Khu vực chọn Avatar (Sắp có)"))),
              // SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveUserName,
                icon: Icon(Icons.save_alt_rounded),
                label: Text("Lưu thông tin"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}