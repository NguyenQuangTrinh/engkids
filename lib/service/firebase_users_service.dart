// lib/service/firebase_users_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';

class FirebaseUsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUsersService._privateConstructor();

  String? get userId => _auth.currentUser?.uid;

  static final FirebaseUsersService instance =
      FirebaseUsersService._privateConstructor();

  String _getFriendshipDocId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_${uid2}' : '${uid2}_${uid1}';
  }

  // Hàm tìm kiếm người dùng theo displayName
  // Lưu ý: Firestore yêu cầu phải tạo Index cho các truy vấn phức tạp.
  // Lần đầu chạy hàm này, bạn sẽ thấy một link lỗi màu đỏ trong logcat/debug console.
  // Hãy nhấn vào link đó để Firebase tự động tạo Index cho bạn.
  Future<List<UserProfile>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    // Tìm kiếm các tên bắt đầu bằng chuỗi truy vấn, và loại trừ người dùng hiện tại
    final snapshot =
        await _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: query)
            .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get();

    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data()))
        .where(
          (user) => user.uid != currentUserId,
        ) // Loại chính mình khỏi kết quả
        .toList();
  }

  // Gửi lời mời kết bạn
  Future<void> sendFriendRequest(String recipientId) async {
    final currentUserId = userId;
    if (currentUserId == null) return;
    if (currentUserId == recipientId) return; // Không thể tự kết bạn

    final docId = _getFriendshipDocId(currentUserId, recipientId);
    final docRef = _firestore.collection('friendships').doc(docId);

    await docRef.set({
      'users': [currentUserId, recipientId],
      'status': 'pending',
      'requestedBy': currentUserId,
      'createdAt': Timestamp.now(),
    });
  }

  // Chấp nhận lời mời
  Future<void> acceptFriendRequest(String senderId) async {
    final currentUserId = userId;
    if (currentUserId == null) return;

    final docId = _getFriendshipDocId(currentUserId, senderId);
    await _firestore.collection('friendships').doc(docId).update({
      'status': 'accepted',
    });
  }

  // Từ chối hoặc hủy kết bạn
  Future<void> removeOrDeclineFriendship(String otherUserId) async {
    final currentUserId = userId;
    if (currentUserId == null) return;

    final docId = _getFriendshipDocId(currentUserId, otherUserId);
    await _firestore.collection('friendships').doc(docId).delete();
  }

  // Lấy danh sách các lời mời đã nhận (Stream)
  Stream<QuerySnapshot> getFriendRequestsStream() {
    final currentUserId = userId;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUserId)
        .where('status', isEqualTo: 'pending')
        .where('requestedBy', isNotEqualTo: currentUserId)
        .snapshots();
  }

  // Lấy danh sách bạn bè đã chấp nhận (Stream)
  Stream<QuerySnapshot> getFriendsListStream() {
    final currentUserId = userId;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    // Thực hiện các truy vấn song song để tăng tốc độ
    final results = await Future.wait([
      // Đếm số bộ từ
      _firestore
          .collection('users')
          .doc(userId)
          .collection('vocabulary_sets')
          .count()
          .get(),
      // Đếm số bạn bè
      _firestore
          .collection('friendships')
          .where('users', arrayContains: userId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get(),
      // Đếm tổng số từ (truy vấn collection group)
      _firestore
          .collectionGroup('vocabulary_items')
          .where('ownerId', isEqualTo: userId)
          .count()
          .get(),
    ]);

    final setAggregateSnapshot = results[0];
    final friendAggregateSnapshot = results[1];
    final itemAggregateSnapshot = results[2];

    return {
      'setCount': setAggregateSnapshot.count ?? 0,
      'friendCount': friendAggregateSnapshot.count ?? 0,
      'wordCount': itemAggregateSnapshot.count ?? 0,
    };
  }

  Future<String> sendGameChallenge(String recipientId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Chưa đăng nhập");

    final challengeRef = _firestore.collection('challenges').doc();
    await challengeRef.set({
      'challengerId': currentUser.uid,
      'challengerName': currentUser.displayName,
      'recipientId': recipientId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return challengeRef.id; // Trả về ID của lời mời
  }

  // Lắng nghe stream các lời mời đã nhận
  Stream<QuerySnapshot> getGameChallengesStream() {
     final currentUserId = userId; 
    if (currentUserId == null) return const Stream.empty();
    return _firestore
        .collection('challenges')
        .where('recipientId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Lắng nghe một lời mời cụ thể (cho người gửi)
  Stream<DocumentSnapshot> getChallengeStream(String challengeId) {
    return _firestore.collection('challenges').doc(challengeId).snapshots();
  }

  

  // Chấp nhận lời mời
  Future<void> acceptGameChallenge(String challengeId, String sessionId) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
      'gameSessionId': sessionId,
    });
  }
}
