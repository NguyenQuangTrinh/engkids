// lib/models/vocabulary_set_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularySetModel {
  final String? id;
  final String name;
  final String? description;
  final DateTime dateCreated;
  final String? ownerId;
  final String? ownerName;
  final bool isPublic;

  int wordCount; // Số lượng từ trong bộ, hữu ích để hiển thị

  VocabularySetModel({
    this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    this.ownerId,
    this.ownerName,
    this.wordCount = 0,
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setName': name, // Khớp với tên cột trong DBService
      'setDescription': description,
      'dateCreated': Timestamp.fromDate(dateCreated),
      // wordCount không nhất thiết phải lưu trực tiếp vào bảng Sets
      // mà có thể tính toán khi query, hoặc cập nhật riêng.
      // Tuy nhiên, để đơn giản hiển thị, có thể thêm vào map nếu DB schema của bạn có
    };
  }

  factory VocabularySetModel.fromMap(Map<String, dynamic> map) {
    return VocabularySetModel(
      id: map['id'] as String?, // Khớp tên cột
      name: map['name'] as String? ?? 'Bộ từ không tên',
      description: map['setDescription'] as String?,
      dateCreated: (map['dateCreated'] as Timestamp).toDate(),
      ownerId: map['ownerId'] as String?,
      ownerName: map['ownerName'] as String?,
      wordCount: map['wordCount'] as int? ?? 0, // Lấy wordCount nếu có
      isPublic: map['isPublic'] as bool? ?? false,
    );
  }
}
