// lib/providers/listen_type_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard_item_model.dart';

enum ListenTypeStatus { playing, showingResult, ended }

@immutable
class ListenTypeState {
  final List<FlashcardItem> gameWords;
  final int currentWordIndex;
  final ListenTypeStatus status;
  final String userAnswer;
  final bool? wasCorrect; // null: chưa trả lời, true: đúng, false: sai

  const ListenTypeState({
    required this.gameWords,
    this.currentWordIndex = 0,
    this.status = ListenTypeStatus.playing,
    this.userAnswer = '',
    this.wasCorrect,
  });

  FlashcardItem? get currentWord => gameWords.isNotEmpty ? gameWords[currentWordIndex] : null;

  ListenTypeState copyWith({
    List<FlashcardItem>? gameWords,
    int? currentWordIndex,
    ListenTypeStatus? status,
    String? userAnswer,
    bool? wasCorrect,
  }) {
    return ListenTypeState(
      gameWords: gameWords ?? this.gameWords,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      status: status ?? this.status,
      userAnswer: userAnswer ?? this.userAnswer,
      wasCorrect: wasCorrect ?? this.wasCorrect,
    );
  }
}

class ListenTypeNotifier extends StateNotifier<ListenTypeState> {
  ListenTypeNotifier(List<FlashcardItem> vocabularyItems)
      : super(ListenTypeState(gameWords: _prepareGameWords(vocabularyItems)));

  static List<FlashcardItem> _prepareGameWords(List<FlashcardItem> items) {
    final shuffled = List<FlashcardItem>.from(items)..shuffle();
    return shuffled.take(1).toList(); // Lấy 10 từ cho mỗi vòng
  }

  void checkAnswer(String answer) {
    if (state.status != ListenTypeStatus.playing) return;
    
    final correctAnswer = state.currentWord?.term ?? '';
    final isCorrect = answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    state = state.copyWith(
      userAnswer: answer,
      wasCorrect: isCorrect,
      status: ListenTypeStatus.showingResult,
    );
  }

  void nextWord() {
    if (state.currentWordIndex < state.gameWords.length - 1) {
      state = state.copyWith(
        currentWordIndex: state.currentWordIndex + 1,
        status: ListenTypeStatus.playing,
        userAnswer: '',
        wasCorrect: null,
      );
    } else {
      // Hết từ
      state = state.copyWith(status: ListenTypeStatus.ended);
    }
  }

  void startNewGame() {
    state = ListenTypeState(gameWords: _prepareGameWords(state.gameWords));
  }
}

final listenTypeProvider = StateNotifierProvider.family<ListenTypeNotifier, ListenTypeState, List<FlashcardItem>>((ref, vocabularyItems) {
  return ListenTypeNotifier(vocabularyItems);
});