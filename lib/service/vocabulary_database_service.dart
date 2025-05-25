import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import '../models/flashcard_item_model.dart';
import '../models/vocabulary_set_model.dart';
import 'database_service.dart';
// import '../utils/pdf_parser.dart'; // PdfParsingException (nếu dùng lại)

// Tạo một Exception riêng cho Vocabulary nếu muốn
class VocabularyException implements Exception {
  final String message;
  VocabularyException(this.message);
  @override
  String toString() => 'VocabularyException: $message';
}


class VocabularyDatabaseService {
  static const String _logName = 'com.engkids.vocabularydbservice';

  Future<Database> get _db async => await DatabaseManager.instance.database;

  VocabularyDatabaseService._privateConstructor();
  static final VocabularyDatabaseService instance = VocabularyDatabaseService._privateConstructor();

  Future<int> insertVocabularySet(String name, {String? description}) async {
    final db = await _db;
    final setId = await db.insert(
      DatabaseManager.tableVocabularySets,
      {
        DatabaseManager.columnSetName: name,
        DatabaseManager.columnSetDescription: description,
        DatabaseManager.columnSetDateCreated: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Hoặc .ignore nếu không muốn ghi đè tên trùng
    );
    developer.log("Đã tạo bộ từ: '$name' với ID: $setId", name: _logName);
    return setId;
  }

  Future<List<VocabularySetModel>> getAllVocabularySets() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT vs.*, (SELECT COUNT(*) FROM ${DatabaseManager.tableVocabularyItems} vi WHERE vi.${DatabaseManager.columnItemSetId} = vs.${DatabaseManager.columnSetId}) as wordCount
      FROM ${DatabaseManager.tableVocabularySets} vs
      ORDER BY vs.${DatabaseManager.columnSetDateCreated} DESC
    ''');

    developer.log("Đã lấy ${maps.length} bộ từ vựng", name: _logName);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => VocabularySetModel.fromMap(maps[i]));
  }

  Future<void> deleteVocabularySet(int setId) async {
    final db = await _db;
    final count = await db.delete(
      DatabaseManager.tableVocabularySets,
      where: '${DatabaseManager.columnSetId} = ?',
      whereArgs: [setId],
    );
    developer.log("Đã xóa $count bộ từ (ID: $setId) và các từ liên quan (do ON DELETE CASCADE).", name: _logName);
  }

  Future<int> insertVocabularyItem(int setId, FlashcardItem item) async {
    final db = await _db;
    final itemId = await db.insert(
      DatabaseManager.tableVocabularyItems,
      {
        DatabaseManager.columnItemSetId: setId,
        DatabaseManager.columnItemTerm: item.term,
        DatabaseManager.columnItemDefinition: item.definition,
        DatabaseManager.columnItemExample: item.exampleSentence,
        DatabaseManager.columnItemPhonetic: item.phonetic,
        DatabaseManager.columnItemDateAdded: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // developer.log("Đã thêm từ '${item.term}' vào bộ ID: $setId với itemID: $itemId", name: _logName);
    return itemId;
  }

  Future<List<FlashcardItem>> getVocabularyItemsBySetId(int setId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableVocabularyItems,
      where: '${DatabaseManager.columnItemSetId} = ?',
      whereArgs: [setId],
      orderBy: '${DatabaseManager.columnItemDateAdded} ASC',
    );

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) {
      return FlashcardItem(
        id: maps[i][DatabaseManager.columnItemId].toString(),
        term: maps[i][DatabaseManager.columnItemTerm] as String,
        definition: maps[i][DatabaseManager.columnItemDefinition] as String,
        exampleSentence: maps[i][DatabaseManager.columnItemExample] as String?,
        phonetic: maps[i][DatabaseManager.columnItemPhonetic] as String?,
      );
    });
  }

  Future<bool> importVocabularyFromJson(String filePath, String setName, {String? setDescription}) async {
    developer.log("Bắt đầu nhập từ JSON: $filePath cho bộ: $setName", name: _logName);
    final db = await _db; // Lấy DB một lần

    try {
      final String jsonString = await File(filePath).readAsString();
      if (jsonString.isEmpty) throw VocabularyException("File JSON rỗng.");

      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isEmpty) throw VocabularyException("File JSON không chứa mục từ vựng nào.");

      // Kiểm tra tên bộ từ đã tồn tại chưa
      final existingSets = await db.query(
          DatabaseManager.tableVocabularySets,
          where: '${DatabaseManager.columnSetName} = ?',
          whereArgs: [setName]);
      if (existingSets.isNotEmpty) {
        throw VocabularyException("Tên bộ từ '$setName' đã tồn tại. Vui lòng chọn tên khác.");
      }

      final int setId = await insertVocabularySet(setName, description: setDescription); // Dùng hàm đã có
      if (setId <= 0) throw VocabularyException("Không thể tạo bộ từ mới trong database.");

      int itemsAddedCount = 0;
      // Sử dụng batch để tăng hiệu suất khi insert nhiều
      Batch batch = db.batch();
      for (var jsonObj in jsonList) {
        if (jsonObj is Map<String, dynamic>) {
          final String? term = jsonObj['term'] as String?;
          final String? definition = jsonObj['definition'] as String?;

          if (term != null && term.isNotEmpty && definition != null && definition.isNotEmpty) {
            // Không cần tạo FlashcardItem ở đây nữa, insert trực tiếp Map
            batch.insert(
                DatabaseManager.tableVocabularyItems,
                {
                  DatabaseManager.columnItemSetId: setId,
                  DatabaseManager.columnItemTerm: term,
                  DatabaseManager.columnItemDefinition: definition,
                  DatabaseManager.columnItemExample: jsonObj['exampleSentence'] as String?,
                  DatabaseManager.columnItemPhonetic: jsonObj['phonetic'] as String?,
                  DatabaseManager.columnItemDateAdded: DateTime.now().toIso8601String(),
                }
            );
            itemsAddedCount++;
          } else {
            developer.log("Bỏ qua mục từ không hợp lệ trong JSON: $jsonObj", name: _logName);
          }
        }
      }
      await batch.commit(noResult: true); // Commit batch
      developer.log("Đã thêm $itemsAddedCount mục từ vào bộ '$setName' (ID: $setId)", name: _logName);
      return itemsAddedCount > 0;

    } on VocabularyException { rethrow; }
    catch (e, s) {
      developer.log("Lỗi khi nhập từ vựng từ JSON: $filePath", name: _logName, error: e, stackTrace: s);
      throw VocabularyException("Lỗi đọc hoặc phân tích file JSON: ${e.toString()}");
    }
  }

  Future<List<FlashcardItem>> getRandomVocabularyItems({int limit = 15}) async {
    final db = await _db;
    developer.log("Đang lấy $limit từ vựng ngẫu nhiên từ database.", name: _logName);

    // Sử dụng RANDOM() của SQLite để lấy các hàng ngẫu nhiên hiệu quả
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableVocabularyItems,
      orderBy: 'RANDOM()', // SQLite sẽ tự sắp xếp ngẫu nhiên
      limit: limit,        // Giới hạn số lượng kết quả
    );

    if (maps.isEmpty) {
      developer.log("Không tìm thấy từ vựng nào trong database.", name: _logName);
      return [];
    }

    List<FlashcardItem> randomItems = List.generate(maps.length, (i) {
      return FlashcardItem(
        id: maps[i][DatabaseManager.columnItemId].toString(), // Lấy ID từ DB
        term: maps[i][DatabaseManager.columnItemTerm] as String,
        definition: maps[i][DatabaseManager.columnItemDefinition] as String,
        exampleSentence: maps[i][DatabaseManager.columnItemExample] as String?,
        phonetic: maps[i][DatabaseManager.columnItemPhonetic] as String?,
      );
    });
    developer.log("Đã lấy được ${randomItems.length} từ vựng ngẫu nhiên.", name: _logName);
    return randomItems;
  }
}