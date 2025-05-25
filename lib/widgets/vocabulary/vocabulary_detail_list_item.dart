import 'package:flutter/material.dart';
import '../../models/flashcard_item_model.dart'; // Import model FlashcardItem

class VocabularyDetailListItem extends StatelessWidget {
  final FlashcardItem word;

  const VocabularyDetailListItem({
    super.key,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.term, // Từ tiếng Anh
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                word.phonetic!, // Phiên âm
                style: TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 6.0),
            Text(
              word.definition, // Nghĩa
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.black87,
              ),
            ),
            if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Text(
                "Ví dụ:",
                style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              Text(
                word.exampleSentence!, // Câu ví dụ
                style: TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
              ),
            ],
            // TODO: Thêm nút Sửa/Xóa từ ở đây nếu cần trong tương lai
          ],
        ),
      ),
    );
  }
}