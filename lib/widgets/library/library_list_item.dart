import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để định dạng ngày
import '../../models/saved_quiz_model.dart';

class LibraryListItem extends StatelessWidget {
  final SavedQuizModel quiz;
  final VoidCallback onPractice; // Callback khi nhấn "Làm bài"
  final VoidCallback onDelete;   // Callback khi nhấn "Xóa"

  const LibraryListItem({
    super.key,
    required this.quiz,
    required this.onPractice,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Định dạng ngày thêm cho đẹp hơn
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(quiz.dateAdded);

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[quiz.name.hashCode % Colors.primaries.length].withValues(alpha: 0.7), // Màu ngẫu nhiên dựa trên tên
          child: Text(
            quiz.questions.length.toString(), // Hiển thị số câu hỏi
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          quiz.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("Ngày thêm: $formattedDate"),
            if (quiz.originalFilePath != null && quiz.originalFilePath!.isNotEmpty)
              Text(
                "File gốc: ${quiz.originalFilePath!.split(Platform.isWindows ? '\\' : '/').last}", // Chỉ hiển thị tên file
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Để Row co lại vừa đủ nội dung
          children: [
            Tooltip(
              message: "Làm bài",
              child: IconButton(
                icon: Icon(Icons.play_circle_outline_rounded, color: Colors.green, size: 28),
                onPressed: onPractice,
              ),
            ),
            Tooltip(
              message: "Xóa bài",
              child: IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
        onTap: onPractice, // Nhấn vào cả item cũng là làm bài
      ),
    );
  }
}