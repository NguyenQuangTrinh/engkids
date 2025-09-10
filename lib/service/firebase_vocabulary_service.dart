// lib/service/firebase_vocabulary_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engkids/models/flashcard_item_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vocabulary_set_model.dart';

class FirebaseVocabularyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  FirebaseVocabularyService._privateConstructor();
  static final FirebaseVocabularyService instance =
      FirebaseVocabularyService._privateConstructor();

  // Lấy User ID của người dùng hiện tại
  String? get _userId => _auth.currentUser?.uid;

  // Hàm import mới, làm việc với Firestore
  Future<bool> importVocabularyFromJsonString(
    String jsonString,
    String setName, {
    String? setDescription,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception("Người dùng chưa đăng nhập.");

    if (jsonString.isEmpty) throw Exception("Chuỗi JSON rỗng.");
    final List<dynamic> jsonList = jsonDecode(jsonString);
    if (jsonList.isEmpty) throw Exception("JSON không chứa từ vựng nào.");

    // Tham chiếu đến collection của người dùng
    final setsCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary_sets');

    // 1. Kiểm tra tên bộ từ đã tồn tại chưa
    final querySnapshot =
        await setsCollection.where('name', isEqualTo: setName).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      throw Exception(
        "Tên bộ từ '$setName' đã tồn tại. Vui lòng chọn tên khác.",
      );
    }

    // 2. Tạo một document mới cho bộ từ và lấy ID của nó
    final setDocument = await setsCollection.add({
      'name': setName,
      'description': setDescription,
      'dateCreated': Timestamp.now(), // Dùng Timestamp của Firestore
      'ownerId': userId,
      'ownerName': _auth.currentUser?.displayName ?? 'Người dùng ẩn danh',
      'wordCount': jsonList.length, // Lưu wordCount trực tiếp
      'isPublic': false,
    });

    // 3. Dùng WriteBatch để thêm tất cả các từ vựng trong một lần cho hiệu quả
    final batch = _firestore.batch();
    final itemsCollection = setDocument.collection('vocabulary_items');

    for (var jsonObj in jsonList) {
      if (jsonObj is Map<String, dynamic>) {
        final String? term = jsonObj['term'] as String?;
        final String? definition = jsonObj['definition'] as String?;

        if (term != null &&
            term.isNotEmpty &&
            definition != null &&
            definition.isNotEmpty) {
          final newItemDoc =
              itemsCollection.doc(); // Tạo một document rỗng với ID tự động
          batch.set(newItemDoc, {
            'term': term,
            'definition': definition,
            'exampleSentence': jsonObj['exampleSentence'] as String?,
            'phonetic': jsonObj['phonetic'] as String?,
            'partOfSpeech': jsonObj['partOfSpeech'] as String?,
            'dateAdded': Timestamp.now(),
            'ownerId': userId,
            'isPublic': false,
          });
        }
      }
    }

    // 4. Commit batch
    await batch.commit();
    return true;
  }

  Future<void> toggleSetSharing(String setId, bool currentStatus) async {
    final userId = _userId;
    if (userId == null) return;

    final setDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary_sets')
        .doc(setId);
    final itemsCollectionRef = setDocRef.collection('vocabulary_items');
    final newStatus = !currentStatus;

    // Lấy tất cả các item con để cập nhật
    final itemsSnapshot = await itemsCollectionRef.get();

    final batch = _firestore.batch();

    // 1. Cập nhật trạng thái public của bộ từ cha
    batch.update(setDocRef, {'isPublic': newStatus});

    // 2. Cập nhật trạng thái public cho TẤT CẢ các từ vựng con
    for (var doc in itemsSnapshot.docs) {
      batch.update(doc.reference, {'isPublic': newStatus});
    }

    await batch.commit();
  }

  Future<List<VocabularySetModel>> getVocabularyFeed() async {
    final currentUserId = _userId;
    if (currentUserId == null) return [];

    // 1. Lấy danh sách ID của bạn bè
    final friendsSnapshot =
        await _firestore
            .collection('friendships')
            .where('users', arrayContains: currentUserId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final List<String> friendIds =
        friendsSnapshot.docs
            .map((doc) {
              final List<dynamic> users = doc.data()['users'];
              return users.firstWhere((id) => id != currentUserId);
            })
            .toList()
            .cast<String>();

    // 2. Tạo danh sách các ID cần truy vấn (bao gồm cả chính mình)
    final List<String> idsToQuery = [currentUserId, ...friendIds];

    // 3. Dùng truy vấn collectionGroup với 'whereIn' để lấy tất cả bộ từ của mình và bạn bè
    if (idsToQuery.isEmpty) return [];

    final setsSnapshot =
        await _firestore
            .collectionGroup('vocabulary_sets')
            .where('ownerId', whereIn: idsToQuery)
            .orderBy('dateCreated', descending: true)
            .limit(50) // Giới hạn 50 bộ từ gần nhất để tối ưu
            .get();

    return setsSnapshot.docs
        .map((doc) => VocabularySetModel.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<List<FlashcardItem>> getItemsFromMultipleSets(
    List<VocabularySetModel> sets,
  ) async {
    if (sets.isEmpty) return [];

    final List<Future<QuerySnapshot>> queries = [];

    // Tạo một truy vấn cho mỗi bộ từ được chọn
    for (final set in sets) {
      if (set.id != null && set.ownerId != null) {
        queries.add(
          _firestore
              .collection('users')
              .doc(set.ownerId)
              .collection('vocabulary_sets')
              .doc(set.id)
              .collection('vocabulary_items')
              .get(),
        );
      }
    }

    // Chạy tất cả các truy vấn song song để tăng tốc
    final List<QuerySnapshot> querySnapshots = await Future.wait(queries);

    // Gộp kết quả từ tất cả các truy vấn lại
    final List<FlashcardItem> allItems = [];
    for (final snapshot in querySnapshots) {
      for (final doc in snapshot.docs) {
        allItems.add(
          FlashcardItem.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        );
      }
    }

    allItems.shuffle(); // Xáo trộn danh sách cuối cùng
    return allItems;
  }

  Future<void> deleteVocabularySet(String setId) async {
    final userId = _userId;
    if (userId == null) throw Exception("Người dùng chưa đăng nhập.");

    final setDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary_sets')
        .doc(setId);

    // Firestore không tự động xóa subcollection, đây là một chủ đề nâng cao.
    // Tạm thời chúng ta chỉ xóa document của bộ từ.
    // TODO: Implement subcollection deletion for production.
    await setDocRef.delete();
  }

  // <<< HÀM MỚI: Xóa một từ vựng đơn lẻ
  Future<void> deleteVocabularyItem(String setId, String itemId) async {
    final userId = _userId;
    if (userId == null) throw Exception("Người dùng chưa đăng nhập.");

    // Tham chiếu đến document của từ vựng cần xóa
    final itemDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary_sets')
        .doc(setId)
        .collection('vocabulary_items')
        .doc(itemId);

    // Tham chiếu đến document của bộ từ cha
    final setDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary_sets')
        .doc(setId);

    // Dùng transaction để đảm bảo cả 2 hành động cùng thành công hoặc thất bại
    await _firestore.runTransaction((transaction) async {
      // 1. Xóa document của từ vựng
      transaction.delete(itemDocRef);
      // 2. Cập nhật (giảm) wordCount của bộ từ cha đi 1
      transaction.update(setDocRef, {'wordCount': FieldValue.increment(-1)});
    });
  }

  Future<List<FlashcardItem>> getVocabularyItemsBySetId(
    String ownerId,
    String setId,
  ) async {
    final userId = _userId;
    if (userId == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(ownerId)
            .collection('vocabulary_sets')
            .doc(setId)
            .collection('vocabulary_items')
            .orderBy('dateAdded', descending: false)
            .get();

    return snapshot.docs.map((doc) {
      // Truyền cả data và document ID vào model
      return FlashcardItem.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<List<FlashcardItem>> getRandomVocabularyItems({int limit = 15}) async {
    final userId = _userId;
    if (userId == null) return [];
    final setsCheckSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('vocabulary_sets')
            .limit(1)
            .get();

    // Nếu không có bộ từ nào, trả về danh sách rỗng ngay lập tức, tránh truy vấn lỗi.
    if (setsCheckSnapshot.docs.isEmpty) {
      return [];
    }

    // 1. Dùng collectionGroup để truy vấn tất cả các subcollection có tên 'vocabulary_items'
    //    thuộc về người dùng hiện tại.
    final snapshot =
        await _firestore
            .collectionGroup('vocabulary_items')
            .where(
              FieldPath.documentId,
              isGreaterThanOrEqualTo:
                  _firestore.collection('users').doc(userId).path,
            )
            .where(
              FieldPath.documentId,
              isLessThan: '${_firestore.collection('users').doc(userId).path}~',
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    // 2. Chuyển tất cả các document tìm được thành danh sách FlashcardItem
    List<FlashcardItem> allItems =
        snapshot.docs
            .map((doc) => FlashcardItem.fromMap(doc.data(), doc.id))
            .toList();

    // 3. Xáo trộn danh sách và lấy ra số lượng cần thiết
    allItems.shuffle();

    return allItems.take(limit).toList();
  }
}
