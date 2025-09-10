// lib/service/database_service.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

class DatabaseManager {
  static const String _databaseName = "EngKidsLibrary.db";
  static const int _databaseVersion = 2; // Tăng version nếu thay đổi schema sau này
  static const String _logName = 'com.engkids.databasemanager';

  // --- Tên bảng và cột cho Bài tập đã lưu (Saved Quizzes) ---
  static const String tableSavedQuizzes = 'saved_quizzes';
  static const String columnQuizId = 'id'; // Chung
  static const String columnQuizName = 'name';
  static const String columnQuizOriginalFilePath = 'originalFilePath';
  static const String columnQuizQuestionsJson = 'questionsJson';
  static const String columnQuizDateAdded = 'dateAdded'; // Chung

  // --- Tên bảng và cột cho Bộ Từ Vựng (Vocabulary Sets) ---
  static const String tableVocabularySets = 'vocabulary_sets';
  static const String columnSetId = 'id'; // Chung
  static const String columnSetName = 'setName';
  static const String columnSetDescription = 'setDescription';
  static const String columnSetDateCreated = 'dateCreated';

  // --- Tên bảng và cột cho Mục Từ Vựng (Vocabulary Items) ---
  static const String tableVocabularyItems = 'vocabulary_items';
  static const String columnItemId = 'id'; // Chung
  static const String columnItemSetId = 'setId'; // Khóa ngoại tới tableVocabularySets
  static const String columnItemTerm = 'term';
  static const String columnItemDefinition = 'definition';
  static const String columnItemExample = 'exampleSentence';
  static const String columnItemPartOfSpeech = 'part_of_speech';
  static const String columnItemPhonetic = 'phonetic';
  static const String columnItemDateAdded = 'dateAdded'; // Chung

  //
  static const String tableHighScores = 'high_scores';
  static const String columnId = 'id';
  static const String columnGameType = 'gameType';
  static const String columnScore = 'score'; // Sẽ lưu thời gian (giây)
  static const String columnPlayerName = 'playerName';
  static const String columnDateAchieved = 'dateAchieved';

  // Singleton pattern
  DatabaseManager._privateConstructor();
  static final DatabaseManager instance = DatabaseManager._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    developer.log("Đường dẫn DB: $path", name: _logName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Thêm hàm _onUpgrade vào DatabaseManager
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  developer.log("Nâng cấp database từ version $oldVersion lên $newVersion", name: _logName);
  if (oldVersion < 3) {
    // Lệnh thêm cột cho người dùng cũ
    await db.execute(
      'ALTER TABLE $tableVocabularyItems ADD COLUMN $columnItemPartOfSpeech TEXT'
    );
    developer.log("Đã nâng cấp: Thêm cột $columnItemPartOfSpeech", name: _logName);
  }
}

  Future<void> _onCreate(Database db, int version) async {
    developer.log("Đang tạo các bảng trong database...", name: _logName);
    // Tạo bảng SavedQuizzes
    await db.execute('''
      CREATE TABLE $tableSavedQuizzes (
        $columnQuizId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnQuizName TEXT NOT NULL,
        $columnQuizOriginalFilePath TEXT,
        $columnQuizQuestionsJson TEXT NOT NULL,
        $columnQuizDateAdded TEXT NOT NULL
      )
    ''');
    developer.log("Đã tạo bảng $tableSavedQuizzes", name: _logName);

    // Tạo bảng VocabularySets
    await db.execute('''
      CREATE TABLE $tableVocabularySets (
        $columnSetId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnSetName TEXT NOT NULL UNIQUE,
        $columnSetDescription TEXT,
        $columnSetDateCreated TEXT NOT NULL
      )
    ''');
    developer.log("Đã tạo bảng $tableVocabularySets", name: _logName);

    // Tạo bảng VocabularyItems
    await db.execute('''
      CREATE TABLE $tableVocabularyItems (
        $columnItemId INTEGER PRIMARY KEY AUTOINCREMENT, 
        $columnItemSetId INTEGER NOT NULL,
        $columnItemTerm TEXT NOT NULL,
        $columnItemDefinition TEXT NOT NULL,
        $columnItemExample TEXT,
        $columnItemPartOfSpeech TEXT,
        $columnItemPhonetic TEXT,
        $columnItemDateAdded TEXT NOT NULL,
        FOREIGN KEY ($columnItemSetId) REFERENCES $tableVocabularySets ($columnSetId) ON DELETE CASCADE
      )
    ''');
    developer.log("Đã tạo bảng $tableVocabularyItems", name: _logName);

    await db.execute('''
      CREATE TABLE $tableHighScores (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnGameType TEXT NOT NULL,
        $columnScore INTEGER NOT NULL, 
        $columnPlayerName TEXT,
        $columnDateAchieved TEXT NOT NULL 
      )
    ''');
    developer.log("Đã nâng cấp: Tạo bảng $tableHighScores", name: _logName);
  }

// Hàm đóng DB (tùy chọn, sqflite thường tự quản lý)
// Future<void> close() async {
//   final db = await instance.database;
//   db.close();
//   _database = null;
// }
}