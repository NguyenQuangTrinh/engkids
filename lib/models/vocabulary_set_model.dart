// lib/models/vocabulary_set_model.dart

class VocabularySetModel {
  final int? id;
  final String name;
  final String? description;
  final DateTime dateCreated;
  int wordCount; // Số lượng từ trong bộ, hữu ích để hiển thị

  VocabularySetModel({
    this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    this.wordCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setName': name, // Khớp với tên cột trong DBService
      'setDescription': description,
      'dateCreated': dateCreated.toIso8601String(),
      // wordCount không nhất thiết phải lưu trực tiếp vào bảng Sets
      // mà có thể tính toán khi query, hoặc cập nhật riêng.
      // Tuy nhiên, để đơn giản hiển thị, có thể thêm vào map nếu DB schema của bạn có
    };
  }

  factory VocabularySetModel.fromMap(Map<String, dynamic> map) {
    return VocabularySetModel(
      id: map['id'] as int?, // Khớp tên cột
      name: map['setName'] as String,
      description: map['setDescription'] as String?,
      dateCreated: DateTime.parse(map['dateCreated'] as String),
      wordCount: map['wordCount'] as int? ?? 0, // Lấy wordCount nếu có
    );
  }
}