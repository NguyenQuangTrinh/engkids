// lib/service/firebase_history_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_history_model.dart';

class FirebaseHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseHistoryService._privateConstructor();
  static final FirebaseHistoryService instance = FirebaseHistoryService._privateConstructor();

  String? get _userId => _auth.currentUser?.uid;

  // Thêm một hoạt động vào lịch sử
  Future<void> addActivityToHistory(ActivityHistory activity) async {
    final userId = _userId;
    if (userId == null) return; // Chỉ thêm khi người dùng đã đăng nhập

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('activity_history')
        .add(activity.toMap());
  }

  // Lấy danh sách lịch sử (dạng Stream để tự động cập nhật)
  Stream<List<ActivityHistory>> getHistoryStream() {
    final userId = _userId;
    if (userId == null) return Stream.value([]); // Trả về stream rỗng nếu chưa đăng nhập

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activity_history')
        .orderBy('completedAt', descending: true) // Sắp xếp theo ngày gần nhất
        .limit(50) // Giới hạn 50 hoạt động gần nhất
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ActivityHistory.fromMap(doc.data(), doc.id)).toList();
        });
  }
}