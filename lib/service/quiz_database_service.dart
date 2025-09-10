// lib/service/quiz_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import '../models/saved_quiz_model.dart';
import 'database_service.dart';

class QuizDatabaseService {
  static const String _logName = 'com.engkids.quizdbservice';

  // Lấy instance Database từ DatabaseManager
  Future<Database> get _db async => await DatabaseManager.instance.database;

  // Singleton pattern (tùy chọn, có thể tạo instance trực tiếp nếu muốn)
  QuizDatabaseService._privateConstructor();
  static final QuizDatabaseService instance = QuizDatabaseService._privateConstructor();

  Future<int> insertQuiz(SavedQuizModel quiz) async {
    final db = await _db;
    Map<String, dynamic> row = quiz.toMap();
    if (row.containsKey('id') && row['id'] == null) {
      row.remove('id');
    }
    final id = await db.insert(DatabaseManager.tableSavedQuizzes, row);
    developer.log("Đã chèn quiz '${quiz.name}' với ID: $id", name: _logName);
    return id;
  }

  Future<List<SavedQuizModel>> getAllQuizzes() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableSavedQuizzes,
      orderBy: "${DatabaseManager.columnQuizDateAdded} DESC",
    );

    developer.log("Đã lấy ${maps.length} saved quizzes từ DB", name: _logName);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return SavedQuizModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteQuiz(int id) async {
    final db = await _db;
    developer.log("Đang xóa saved quiz ID: $id", name: _logName);
    final count = await db.delete(
      DatabaseManager.tableSavedQuizzes,
      where: '${DatabaseManager.columnQuizId} = ?',
      whereArgs: [id],
    );
    developer.log("Đã xóa $count saved quiz(zes) với ID: $id", name: _logName);
    return count;
  }

// Thêm các hàm khác cho quiz nếu cần (getQuizById, updateQuiz, ...)
}