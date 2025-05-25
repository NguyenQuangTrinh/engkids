import 'dart:convert'; // Để dùng jsonEncode và jsonDecode

class SavedQuizModel {
  final int? id; // id từ database, có thể null nếu chưa được lưu
  final String name; // Tên bài tập (ví dụ: từ tên file PDF)
  final String? originalFilePath; // Đường dẫn file PDF gốc (tùy chọn, để tham khảo)
  final List<Map<String, dynamic>> questions; // Dữ liệu câu hỏi đã phân tích
  final DateTime dateAdded; // Ngày thêm vào thư viện
  // Thêm các trường khác nếu cần: lastPracticed, bestScore...

  SavedQuizModel({
    this.id,
    required this.name,
    this.originalFilePath,
    required this.questions,
    required this.dateAdded,
  });

  // Chuyển đổi từ Object sang Map để lưu vào DB
  // questions sẽ được chuyển thành chuỗi JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id, // SQLite sẽ tự tăng id nếu là PRIMARY KEY AUTOINCREMENT
      'name': name,
      'originalFilePath': originalFilePath,
      'questionsJson': jsonEncode(questions), // Chuyển List<Map> thành chuỗi JSON
      'dateAdded': dateAdded.toIso8601String(), // Lưu ngày giờ dưới dạng chuỗi ISO
    };
  }

  // Chuyển đổi từ Map (đọc từ DB) sang Object
  // questionsJson sẽ được chuyển ngược lại thành List<Map>
  factory SavedQuizModel.fromMap(Map<String, dynamic> map) {
    return SavedQuizModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      originalFilePath: map['originalFilePath'] as String?,
      // Chuyển chuỗi JSON ngược lại thành List<Map>
      questions: List<Map<String, dynamic>>.from(
          (jsonDecode(map['questionsJson'] as String) as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
      ),
      dateAdded: DateTime.parse(map['dateAdded'] as String),
    );
  }

  // Tiện ích copyWith (tùy chọn, hữu ích khi cập nhật)
  SavedQuizModel copyWith({
    int? id,
    String? name,
    String? originalFilePath,
    List<Map<String, dynamic>>? questions,
    DateTime? dateAdded,
  }) {
    return SavedQuizModel(
      id: id ?? this.id,
      name: name ?? this.name,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      questions: questions ?? this.questions,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}
