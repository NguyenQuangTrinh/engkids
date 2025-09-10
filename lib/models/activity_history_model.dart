// lib/models/activity_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class ActivityHistory {
  final String? id;
  final String activityType; // ví dụ: 'quiz', 'matching_game', 'word_scramble'
  final String activityName; // Tên bài quiz hoặc tên bộ từ
  final int score;
  final int totalItems; // Tổng số câu hỏi hoặc số cặp từ
  final DateTime completedAt;

  const ActivityHistory({
    this.id,
    required this.activityType,
    required this.activityName,
    required this.score,
    required this.totalItems,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityType': activityType,
      'activityName': activityName,
      'score': score,
      'totalItems': totalItems,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  factory ActivityHistory.fromMap(Map<String, dynamic> map, String documentId) {
    return ActivityHistory(
      id: documentId,
      activityType: map['activityType'] as String? ?? 'unknown',
      activityName: map['activityName'] as String? ?? 'N/A',
      score: map['score'] as int? ?? 0,
      totalItems: map['totalItems'] as int? ?? 0,
      completedAt: (map['completedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}