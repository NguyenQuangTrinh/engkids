// lib/service/firebase_leaderboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/high_score_model.dart'; // Chúng ta có thể tái sử dụng model này

class FirebaseLeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseLeaderboardService._privateConstructor();
  static final FirebaseLeaderboardService instance = FirebaseLeaderboardService._privateConstructor();

  // Gửi điểm số mới lên bảng xếp hạng
  Future<void> submitScore(String gameType, int scoreInSeconds) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final leaderboardRef = _firestore.collection('leaderboards').doc(gameType).collection('scores').doc(user.uid);
    
    final doc = await leaderboardRef.get();

    // Chỉ ghi điểm mới nếu nó tốt hơn (thấp hơn) điểm cũ hoặc chưa có điểm nào
    if (!doc.exists || scoreInSeconds < doc.data()!['score']) {
      await leaderboardRef.set({
        'score': scoreInSeconds,
        'displayName': user.displayName ?? 'EngKid Player',
        'photoURL': user.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid, // Lưu lại userId để tiện truy vấn sau này
      });
    }
  }

  // Lấy top 5 người chơi cho một game
  Stream<List<HighScoreModel>> getTopScoresStream(String gameType) {
    return _firestore
        .collection('leaderboards')
        .doc(gameType)
        .collection('scores')
        .orderBy('score', descending: false) // Sắp xếp theo thời gian tăng dần
        .limit(5)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            // Chuyển đổi một chút để tái sử dụng HighScoreModel
            return HighScoreModel(
              gameType: gameType,
              score: data['score'],
              playerName: data['displayName'],
              // Chuyển Timestamp về DateTime
              dateAchieved: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }
}