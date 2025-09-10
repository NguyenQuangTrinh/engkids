// lib/widgets/vocabulary/vocabulary_detail_list_item.dart

import 'package:flutter/material.dart';
import '../../models/flashcard_item_model.dart'; // Import model FlashcardItem

class VocabularyDetailListItem extends StatelessWidget {
  final FlashcardItem word;
  final VoidCallback onLongPress; // Thay onDelete bằng onLongPress
  final VoidCallback onTermTap; // Callback khi chạm vào từ
  final VoidCallback onExampleTap; // Callback khi chạm vào ví dụ

  const VocabularyDetailListItem({
    super.key,
    required this.word,
    required this.onLongPress,
    required this.onTermTap,
    required this.onExampleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onLongPress: onLongPress, // Gán sự kiện giữ yên
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onTermTap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        word.term,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                      // HIỂN THỊ LOẠI TỪ
                      if (word.partOfSpeech != null &&
                          word.partOfSpeech!.isNotEmpty) ...[
                        const SizedBox(width: 8.0),
                        Text(
                          "(${word.partOfSpeech})",
                          style: TextStyle(
                            fontSize: 14.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ],
                  ),
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
                style: TextStyle(fontSize: 15.0, color: Colors.black87),
              ),
              if (word.exampleSentence != null &&
                  word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                // Bọc câu ví dụ trong GestureDetector
                GestureDetector(
                  onTap: onExampleTap,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Ví dụ: ${word.exampleSentence!}",
                            style: TextStyle(
                              fontSize: 14.0,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
