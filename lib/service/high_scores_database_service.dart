// lib/service/high_scores_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import '../models/high_score_model.dart';
import 'database_service.dart';

class HighScoresDatabaseService {
  static const String _logName = 'com.engkids.highscoresservice';
  static const int maxHighScoresPerGame = 5; // Giới hạn top 5

  Future<Database> get _db async => await DatabaseManager.instance.database;

  HighScoresDatabaseService._privateConstructor();
  static final HighScoresDatabaseService instance = HighScoresDatabaseService._privateConstructor();

  // Thêm một thành tích mới, chỉ giữ lại top 5
  Future<void> addHighScore(String gameType, int scoreInSeconds, {String? playerName}) async {
    final db = await _db;
    final now = DateTime.now();

    // Lấy danh sách top 5 hiện tại cho gameType này
    // Đối với game tính giờ, điểm thấp hơn là tốt hơn (ORDER BY score ASC)
    final List<Map<String, dynamic>> currentTopScoresMap = await db.query(
      DatabaseManager.tableHighScores,
      where: '${DatabaseManager.columnGameType} = ?',
      whereArgs: [gameType],
      orderBy: '${DatabaseManager.columnScore} ASC', // Sắp xếp theo thời gian tăng dần
      limit: maxHighScoresPerGame,
    );

    List<HighScoreModel> currentTopScores = currentTopScoresMap.map((map) => HighScoreModel.fromMap(map)).toList();

    bool canInsert = false;
    if (currentTopScores.length < maxHighScoresPerGame) {
      // Nếu chưa đủ top 5, luôn có thể chèn
      canInsert = true;
    } else {
      // Nếu đã đủ top 5, kiểm tra xem điểm mới có tốt hơn điểm tệ nhất trong top 5 không
      // (điểm tệ nhất là điểm cao nhất về thời gian)
      if (scoreInSeconds < currentTopScores.last.score) {
        canInsert = true;
      }
    }

    if (canInsert) {
      final newHighScore = HighScoreModel(
        gameType: gameType,
        score: scoreInSeconds,
        playerName: playerName, // Sẽ lấy từ profile sau này
        dateAchieved: now,
      );
      await db.insert(DatabaseManager.tableHighScores, newHighScore.toMap());
      developer.log("Đã thêm high score mới cho $gameType: $scoreInSeconds giây bởi $playerName", name: _logName);

      // Sau khi chèn, nếu số lượng vượt quá maxHighScoresPerGame, xóa bản ghi tệ nhất
      // (bản ghi có score cao nhất - tức thời gian dài nhất)
      final allScoresForGame = await db.query(
        DatabaseManager.tableHighScores,
        where: '${DatabaseManager.columnGameType} = ?',
        whereArgs: [gameType],
        orderBy: '${DatabaseManager.columnScore} ASC', // Thời gian tăng dần
      );

      if (allScoresForGame.length > maxHighScoresPerGame) {
        // Lấy ID của bản ghi tệ nhất (bản ghi cuối cùng sau khi đã sắp xếp ASC)
        // Tuy nhiên, SQLite không có cách xóa "hàng cuối cùng" dễ dàng sau ORDER BY + LIMIT.
        // Cách an toàn hơn: lấy tất cả, sắp xếp, rồi xóa những cái thừa.
        // Hoặc, truy vấn ID của bản ghi có score cao nhất (nếu có nhiều bản ghi hơn max)
        final scoresToDelete = await db.query(
            DatabaseManager.tableHighScores,
            where: '${DatabaseManager.columnGameType} = ?',
            whereArgs: [gameType],
            orderBy: '${DatabaseManager.columnScore} DESC', // Sắp xếp thời gian giảm dần
            limit: allScoresForGame.length - maxHighScoresPerGame // Số lượng cần xóa
        );
        for (var scoreMap in scoresToDelete) {
          final idToDelete = scoreMap[DatabaseManager.columnId] as int?;
          if (idToDelete != null) {
            await db.delete(
                DatabaseManager.tableHighScores,
                where: '${DatabaseManager.columnId} = ?',
                whereArgs: [idToDelete]
            );
            developer.log("Đã xóa high score cũ ID: $idToDelete để giữ top $maxHighScoresPerGame", name: _logName);
          }
        }
      }
    } else {
      developer.log("Điểm $scoreInSeconds giây không đủ tốt để vào top $maxHighScoresPerGame của $gameType", name: _logName);
    }
  }

  // Lấy top X thành tích cho một loại game
  Future<List<HighScoreModel>> getTopScores(String gameType, {int limit = maxHighScoresPerGame}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableHighScores,
      where: '${DatabaseManager.columnGameType} = ?',
      whereArgs: [gameType],
      orderBy: '${DatabaseManager.columnScore} ASC', // Sắp xếp theo thời gian tăng dần (tốt nhất lên đầu)
      limit: limit,
    );

    developer.log("Đã lấy ${maps.length} top scores cho game $gameType", name: _logName);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return HighScoreModel.fromMap(maps[i]);
    });
  }
}