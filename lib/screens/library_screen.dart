// lib/screens/library_screen.dart

import 'package:engkids/providers/quiz_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_quiz_model.dart';
import '../widgets/library/library_list_item.dart'; // Import widget item
import 'loading_screen.dart';
import 'question_screen.dart'; // Import màn hình câu hỏi

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   LibraryScreenState createState() => LibraryScreenState();
// }

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _practiceQuiz(BuildContext context, SavedQuizModel quiz) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(questions: quiz.questions),
      ),
    );
  }

  Future<void> _deleteQuiz(
    BuildContext context,
    WidgetRef ref,
    SavedQuizModel quiz,
  ) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận xóa"),
          content: Text(
            "Bạn có chắc chắn muốn xóa bài tập '${quiz.name}' không?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && quiz.id != null) {
      await ref.read(quizProvider.notifier).deleteQuiz(quiz.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xóa bài tập '${quiz.name}'"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _pickAndProcessNewPdfFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        await Navigator.push<List<Map<String, dynamic>>?>(
          context,
          MaterialPageRoute(
            builder:
                (context) => LoadingScreen(filePath: result.files.single.path!),
          ),
        );
        // Sau khi LoadingScreen đóng, chúng ta chỉ cần làm mới provider
        ref.read(quizProvider.notifier).fetchQuizzes();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuizzes = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thư Viện Bài Tập"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            // Khi nhấn refresh, gọi trực tiếp hàm fetchQuizzes của Notifier
            onPressed: () => ref.read(quizProvider.notifier).fetchQuizzes(),
            tooltip: "Tải lại danh sách",
          ),
        ],
      ),
      body: asyncQuizzes.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.library_books_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Thư viện của bạn còn trống!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Hãy mở một file PDF bài tập để EngKids tự động lưu vào đây nhé.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(quizProvider.notifier).fetchQuizzes(),
            child: ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return LibraryListItem(
                  quiz: quiz,
                  onPractice: () => _practiceQuiz(context, quiz),
                  onDelete: () => _deleteQuiz(context, ref, quiz),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Text(
                "Lỗi tải thư viện: ${error.toString()}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndProcessNewPdfFile(context, ref),
        tooltip: 'Thêm bài tập mới từ PDF',
        icon: const Icon(Icons.add_rounded),
        label: const Text("Thêm PDF"),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}
