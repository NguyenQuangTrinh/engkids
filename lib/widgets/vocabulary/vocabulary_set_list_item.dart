// lib/widgets/vocabulary/vocabulary_set_list_item.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để định dạng ngày
import '../../models/vocabulary_set_model.dart';

class VocabularySetListItem extends StatelessWidget {
  final VocabularySetModel set;
  final VoidCallback onViewWords;
  final VoidCallback onDeleteSet;
  final VoidCallback onStudyWithFlashcards;
  final VoidCallback onShare;

  const VocabularySetListItem({
    super.key,
    required this.set,
    required this.onViewWords,
    required this.onDeleteSet,
    required this.onStudyWithFlashcards,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'dd/MM/yyyy',
    ).format(set.dateCreated);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isMySet = set.ownerId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors
              .primaries[set.name.hashCode % Colors.primaries.length]
              .withValues(alpha: 0.8),
          child: Text(
            set.wordCount.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(set.name, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (set.description != null && set.description!.isNotEmpty)
              Text(set.description!),
            // Hiển thị tên chủ sở hữu nếu đó không phải là bộ từ của mình
            if (!isMySet)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "bởi ${set.ownerName ?? '...'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            Text(
              "Ngày tạo: $formattedDate",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: "Xem danh sách từ", // Đổi tooltip cho rõ ràng hơn
              child: IconButton(
                icon: Icon(
                  Icons.list_alt_rounded,
                  color: Colors.blue[700],
                  size: 26,
                ),
                onPressed: onViewWords,
              ),
            ),
            if (isMySet) // Chỉ hiển thị nút Chia sẻ và Xóa nếu là bộ từ của mình
              Tooltip(
                message: set.isPublic ? "Dừng chia sẻ" : "Chia sẻ với bạn bè",
                child: IconButton(
                  icon: Icon(
                    set.isPublic
                        ? Icons.public_rounded
                        : Icons.public_off_rounded,
                    color: set.isPublic ? Colors.blue : Colors.grey,
                  ),
                  onPressed: onShare, // <<< GỌI CALLBACK
                ),
              ),
            Tooltip(
              message: "Xóa bộ từ",
              child: IconButton(
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red[600],
                  size: 26,
                ),
                onPressed: onDeleteSet,
              ),
            ),
          ],
        ),
        onTap:
            onViewWords, // <<< CHẠM VÀO ITEM CŨNG ĐỂ HỌC FLASHCARDS (HOẶC XEM TỪ TÙY BẠN)
        // Hiện tại để là học Flashcards cho tiện
      ),
    );
  }
}
