// lib/providers/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:engkids/models/user_profile_model.dart';
import 'package:engkids/providers/auth_provider.dart';
import 'package:engkids/service/firebase_users_service.dart';

// Class để chứa tất cả dữ liệu cho màn hình profile
class ProfileData {
  final UserProfile? userProfile;
  final Map<String, int>? userStats;

  const ProfileData({this.userProfile, this.userStats});
}

// Provider chính, sử dụng FutureProvider để tải dữ liệu bất đồng bộ
final profileDataProvider = FutureProvider<ProfileData>((ref) async {
  // Lắng nghe authStateChangesProvider
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    throw Exception("Người dùng chưa đăng nhập");
  }

  // Chuyển user của Firebase thành UserProfile model của chúng ta
  final userProfile = UserProfile(
    uid: user.uid, 
    displayName: user.displayName ?? 'Chưa có tên', 
    email: user.email ?? '', 
    photoURL: user.photoURL ?? ''
  );
  
  // Gọi service để lấy thống kê
  final userStats = await FirebaseUsersService.instance.getUserStats(user.uid);

  return ProfileData(userProfile: userProfile, userStats: userStats);
});