import 'package:flutter/foundation.dart';

@immutable
class HighScoreModel {
  final int? id; // ID từ database
  final String gameType; // Ví dụ: "matching_game", "word_scramble"
  final int score; // Sẽ lưu thời gian hoàn thành (tính bằng giây, thấp hơn là tốt hơn)
  final String? playerName; // Tên người chơi (lấy từ profile nếu có)
  final DateTime dateAchieved;

  const HighScoreModel({
    this.id,
    required this.gameType,
    required this.score, // Đối với game tính giờ, score này là thời gian (giây)
    this.playerName,
    required this.dateAchieved,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameType': gameType,
      'score': score, // Thời gian tính bằng giây
      'playerName': playerName,
      'dateAchieved': dateAchieved.toIso8601String(),
    };
  }

  factory HighScoreModel.fromMap(Map<String, dynamic> map) {
    return HighScoreModel(
      id: map['id'] as int?,
      gameType: map['gameType'] as String,
      score: map['score'] as int,
      playerName: map['playerName'] as String?,
      dateAchieved: DateTime.parse(map['dateAchieved'] as String),
    );
  }
}