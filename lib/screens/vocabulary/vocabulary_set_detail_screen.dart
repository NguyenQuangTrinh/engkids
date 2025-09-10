// lib/screens/vocabulary/vocabulary_set_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/flashcard_item_model.dart';
import '../../providers/vocabulary_providers.dart';
import '../../service/vocabulary_database_service.dart'; // Vẫn cần để xóa
import '../../widgets/vocabulary/vocabulary_detail_list_item.dart';

class VocabularySetDetailScreen extends ConsumerWidget {
  // <<< Chuyển sang ConsumerWidget
  final String setId;
  final String setName;
  final String ownerId;

  const VocabularySetDetailScreen({
    super.key,
    required this.setId,
    required this.setName,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dùng ref.watch và truyền setId vào provider.family
    final args = SetDetailsArgs(ownerId: ownerId, setId: setId);
    final asyncItems = ref.watch(vocabularyItemsProvider(args));
    final tts = FlutterTts(); // Có thể tạo provider riêng cho TTS sau này

    // Hàm đọc text
    Future<void> speak(String text) async {
      if (text.isNotEmpty) {
        await tts.setLanguage("en-US");
        await tts.setSpeechRate(0.5);
        await tts.speak(text);
      }
    }

    // Hàm xóa từ
    Future<void> deleteWord(FlashcardItem word) async {
      // Dialog xác nhận
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Xác nhận xóa"),
            content: Text("Bạn có chắc chắn muốn xóa từ '${word.term}' không?"),
            actions: <Widget>[
              TextButton(
                child: Text("Hủy"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Xóa", style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        try {
          // Vẫn gọi service local để xóa (Cần sửa lại service này để xóa trên Firebase)
          await VocabularyDatabaseService.instance.deleteVocabularyItem(
            int.parse(word.id),
          );

          // Làm mới cả provider của danh sách từ và danh sách bộ từ
          ref.invalidate(vocabularyItemsProvider(args));
          ref.invalidate(vocabularySetsProvider);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Đã xóa từ '${word.term}'")));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi khi xóa từ.")));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(setName), backgroundColor: Colors.blueAccent),
      body: asyncItems.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text("Bộ từ này chưa có từ nào."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: words.length,
            itemBuilder: (context, index) {
              final word = words[index];
              return VocabularyDetailListItem(
                word: word,
                onLongPress: () => deleteWord(word),
                onTermTap: () => speak(word.term),
                onExampleTap: () => speak(word.exampleSentence ?? ''),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Lỗi tải từ vựng: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Chức năng 'Thêm từ mới' sắp ra mắt!"),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text("Thêm Từ"),
      ),
    );
  }
}
