// lib/providers/history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_history_model.dart';
import '../service/firebase_history_service.dart';
import 'auth_provider.dart';

// StreamProvider sẽ tự động lắng nghe và cung cấp dữ liệu mới nhất
final historyProvider = StreamProvider<List<ActivityHistory>>((ref) {
  // Lắng nghe trạng thái đăng nhập, nếu user thay đổi, provider này sẽ tự reset
  ref.watch(authStateChangesProvider);
  
  return FirebaseHistoryService.instance.getHistoryStream();
});