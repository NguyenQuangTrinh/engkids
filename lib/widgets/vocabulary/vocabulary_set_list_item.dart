// lib/widgets/vocabulary/vocabulary_set_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để định dạng ngày
import '../../models/vocabulary_set_model.dart';

class VocabularySetListItem extends StatelessWidget {
  final VocabularySetModel set;
  final VoidCallback onViewWords;
  final VoidCallback onDeleteSet;
  final VoidCallback onStudyWithFlashcards; // <<< THÊM CALLBACK MỚI

  const VocabularySetListItem({
    super.key,
    required this.set,
    required this.onViewWords,
    required this.onDeleteSet,
    required this.onStudyWithFlashcards, // <<< THÊM VÀO CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(set.dateCreated);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[set.name.hashCode % Colors.primaries.length].withValues(alpha: 0.8),
          child: Text(
            set.wordCount.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(set.name, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(set.description ?? "Ngày tạo: $formattedDate"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip( // <<< NÚT HỌC FLASHCARDS MỚI
              message: "Học với Flashcards",
              child: IconButton(
                icon: Icon(Icons.style_rounded, color: Colors.teal[600], size: 26), // Icon Flashcards
                onPressed: onStudyWithFlashcards,
              ),
            ),
            Tooltip(
              message: "Xem danh sách từ", // Đổi tooltip cho rõ ràng hơn
              child: IconButton(
                icon: Icon(Icons.list_alt_rounded, color: Colors.blue[700], size: 26),
                onPressed: onViewWords,
              ),
            ),
            Tooltip(
              message: "Xóa bộ từ",
              child: IconButton(
                icon: Icon(Icons.delete_forever_rounded, color: Colors.red[600], size: 26),
                onPressed: onDeleteSet,
              ),
            ),
          ],
        ),
        onTap: onStudyWithFlashcards, // <<< CHẠM VÀO ITEM CŨNG ĐỂ HỌC FLASHCARDS (HOẶC XEM TỪ TÙY BẠN)
        // Hiện tại để là học Flashcards cho tiện
      ),
    );
  }
}