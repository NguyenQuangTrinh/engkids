// lib/providers/quiz_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_quiz_model.dart';
import '../service/quiz_database_service.dart';

// Class Notifier để quản lý state của danh sách quiz
class QuizNotifier extends StateNotifier<AsyncValue<List<SavedQuizModel>>> {
  final _quizDbService = QuizDatabaseService.instance;

  QuizNotifier() : super(const AsyncValue.loading()) {
    fetchQuizzes(); // Tải dữ liệu lần đầu
  }

  // Hàm tải danh sách quiz từ database
  Future<void> fetchQuizzes() async {
    state = const AsyncValue.loading();
    try {
      final quizzes = await _quizDbService.getAllQuizzes();
      if (mounted) {
        state = AsyncValue.data(quizzes);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Hàm xóa một quiz
  Future<void> deleteQuiz(int quizId) async {
    try {
      await _quizDbService.deleteQuiz(quizId);
      await fetchQuizzes(); // Tải lại danh sách sau khi xóa
    } catch (e, s) {
      // Nếu có lỗi, cập nhật state để UI hiển thị
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }
}

// StateNotifierProvider để cung cấp Notifier cho ứng dụng
final quizProvider = StateNotifierProvider<QuizNotifier, AsyncValue<List<SavedQuizModel>>>((ref) {
  return QuizNotifier();
});