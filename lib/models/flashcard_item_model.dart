// lib/models/flashcard_item_model.dart
import 'package:flutter/foundation.dart'; // Cho @required (nếu dùng phiên bản Flutter cũ hơn) hoặc cho kiểu dữ liệu

@immutable // Đề xuất: làm cho class này không thể thay đổi sau khi tạo
class FlashcardItem {
  final String id; // ID duy nhất cho mỗi thẻ
  final String term; // Từ/cụm từ tiếng Anh (mặt trước)
  final String
  definition; // Nghĩa/dịch tiếng Việt hoặc định nghĩa tiếng Anh (mặt sau)
  final String? exampleSentence; // Câu ví dụ (tùy chọn)
  final String? phonetic; // Phiên âm (tùy chọn)
  final String? partOfSpeech;
  // Thêm các trường khác nếu cần: imageUrl, audioUrl, ...

  const FlashcardItem({
    required this.id,
    required this.term,
    required this.definition,
    this.exampleSentence,
    this.phonetic,
    this.partOfSpeech,
  });

  factory FlashcardItem.fromMap(Map<String, dynamic> map, String documentId) {
    return FlashcardItem(
      id: documentId,
      term: map['term'] as String? ?? 'N/A',
      definition: map['definition'] as String? ?? 'N/A',
      exampleSentence: map['exampleSentence'] as String?,
      phonetic: map['phonetic'] as String?,
      partOfSpeech: map['partOfSpeech'] as String?,
    );
  }
}
