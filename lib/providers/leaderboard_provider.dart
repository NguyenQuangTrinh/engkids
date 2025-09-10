// lib/providers/leaderboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/high_score_model.dart';
import '../service/firebase_leaderboard_service.dart';

// Dùng .family để có thể lấy bảng xếp hạng cho từng game riêng biệt
final leaderboardProvider = StreamProvider.family<List<HighScoreModel>, String>(
  (ref, gameType) {
    return FirebaseLeaderboardService.instance.getTopScoresStream(gameType);
  },
);
