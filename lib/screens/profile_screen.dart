// lib/screens/profile_screen.dart

import 'package:engkids/models/user_profile_model.dart';
import 'package:engkids/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Hàm hiển thị dialog đổi tên
  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Đổi tên hiển thị"),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nhập tên mới"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    // Gọi hàm update từ provider
                    await ref
                        .read(authServiceProvider)
                        .updateDisplayName(newName);
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    developer.log("Lỗi dialog đổi tên: $e");
                    // Hiển thị lỗi nếu cần
                  }
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe provider mới để lấy tất cả dữ liệu
    final profileDataAsync = ref.watch(profileDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ EngLearn"),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(profileDataProvider),
        child: profileDataAsync.when(
          data: (data) {
            final user = data.userProfile;
            final stats = data.userStats;

            if (user == null) {
              return const Center(
                child: Text("Không tìm thấy thông tin người dùng."),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Phần thông tin cá nhân ---
                _buildProfileHeader(context, ref, user),
                const Divider(height: 40, thickness: 1),

                // --- Phần thống kê ---
                const Text(
                  "Thống kê & Thành tích",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _StatCard(
                      icon: Icons.style_rounded,
                      label: "Bộ từ",
                      value: stats?['setCount']?.toString() ?? '0',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.school_rounded,
                      label: "Từ đã học",
                      value: stats?['wordCount']?.toString() ?? '0',
                      color: Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.people_alt_rounded,
                      label: "Bạn bè",
                      value: stats?['friendCount']?.toString() ?? '0',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const Divider(height: 40),

                // --- Nút Đăng xuất ---
                _buildSignOutButton(context, ref),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            // 1. Log lỗi chi tiết ra terminal
            print("Lỗi tải hồ sơ: $err");
            // 2. Vẫn trả về widget để hiển thị lỗi trên UI cho người dùng
            return Center(child: Text("Lỗi tải hồ sơ: $err"));
          },
        ),
      ),
    );
  }

  // Widget con cho phần header
  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              user.photoURL.isNotEmpty ? NetworkImage(user.photoURL) : null,
          child:
              user.photoURL.isEmpty ? const Icon(Icons.person, size: 50) : null,
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Colors.grey,
              ),
              onPressed:
                  () => _showEditNameDialog(context, ref, user.displayName),
              tooltip: "Đổi tên",
            ),
          ],
        ),
        Text(
          user.email,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Widget con cho nút đăng xuất
  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        ref.read(authServiceProvider).signOut(context: context, ref: ref);
      },
      icon: const Icon(Icons.logout_rounded),
      label: const Text("Đăng xuất"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Widget con cho mỗi ô thống kê
  Widget _StatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
