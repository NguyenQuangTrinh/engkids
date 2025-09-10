// lib/providers/achievements_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/high_score_model.dart';
import '../service/high_scores_database_service.dart';

// 1. Tạo một class để chứa toàn bộ state của màn hình thành tích
class AchievementsState {
  final List<HighScoreModel> matchingScores;
  final List<HighScoreModel> scrambleScores;
  final bool isLoading;
  final String? error;

  const AchievementsState({
    this.matchingScores = const [],
    this.scrambleScores = const [],
    this.isLoading = true,
    this.error,
  });

  AchievementsState copyWith({
    List<HighScoreModel>? matchingScores,
    List<HighScoreModel>? scrambleScores,
    bool? isLoading,
    String? error,
  }) {
    return AchievementsState(
      matchingScores: matchingScores ?? this.matchingScores,
      scrambleScores: scrambleScores ?? this.scrambleScores,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}


// 2. Tạo Notifier để quản lý AchievementsState
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final _hsService = HighScoresDatabaseService.instance;

  AchievementsNotifier() : super(const AchievementsState()) {
    fetchScores();
  }

  Future<void> fetchScores() async {
    // Không set state loading ở đây để RefreshIndicator hoạt động mượt hơn
    // state = state.copyWith(isLoading: true, error: null);
    try {
      final matching = await _hsService.getTopScores("matching_game");
      final scramble = await _hsService.getTopScores("word_scramble");
      if (mounted) {
        state = state.copyWith(
          matchingScores: matching,
          scrambleScores: scramble,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: "Lỗi tải thành tích");
      }
    }
  }
}

// 3. Tạo StateNotifierProvider
final achievementsProvider = StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier();
});