// lib/providers/word_guess_provider.dart

import 'dart:math';
import 'package:engkids/models/activity_history_model.dart';
import 'package:engkids/service/firebase_history_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard_item_model.dart';

// Enum để quản lý trạng thái của game
enum GameStatus { playing, win, lose }

// Class để chứa toàn bộ state của game
@immutable
class WordGuessState {
  final List<FlashcardItem> allWords;
  final List<FlashcardItem> remainingWords;
  final String secretWord;
  final String hint;
  final Set<String> guessedLetters;
  final int remainingLives;
  final GameStatus status;

  const WordGuessState({
    required this.allWords,
    required this.remainingWords,
    required this.secretWord,
    required this.hint,
    required this.guessedLetters,
    required this.remainingLives,
    required this.status,
  });

  // Constructor khởi tạo
  factory WordGuessState.initial(List<FlashcardItem> vocabularyItems) {
    if (vocabularyItems.isEmpty) {
      return const WordGuessState(
        allWords: [],
        remainingWords: [],
        secretWord: '',
        hint: '',
        guessedLetters: {},
        remainingLives: 0,
        status: GameStatus.lose,
      );
    }
    final remaining = List<FlashcardItem>.from(vocabularyItems);
    final randomWordItem = remaining.removeAt(
      Random().nextInt(remaining.length),
    );

    return WordGuessState(
      allWords: vocabularyItems,
      remainingWords: remaining,
      secretWord: randomWordItem.term.toUpperCase().replaceAll(' ', ''),
      hint: randomWordItem.definition,
      guessedLetters: {},
      remainingLives: 6,
      status: GameStatus.playing,
    );
  }

  // Hàm copyWith để dễ dàng tạo state mới
  WordGuessState copyWith({
    List<FlashcardItem>? remainingWords,
    String? secretWord,
    String? hint,
    Set<String>? guessedLetters,
    int? remainingLives,
    GameStatus? status,
  }) {
    return WordGuessState(
      allWords: allWords,
      remainingWords: remainingWords ?? this.remainingWords,
      secretWord: secretWord ?? this.secretWord,
      hint: hint ?? this.hint,
      guessedLetters: guessedLetters ?? this.guessedLetters,
      remainingLives: remainingLives ?? this.remainingLives,
      status: status ?? this.status,
    );
  }
}

// Notifier để quản lý logic game
class WordGuessNotifier extends StateNotifier<WordGuessState> {
  WordGuessNotifier(List<FlashcardItem> vocabularyItems)
    : super(WordGuessState.initial(vocabularyItems));

  void handleKeyPress(String letter) {
    if (state.status != GameStatus.playing ||
        state.guessedLetters.contains(letter)) {
      return;
    }

    final newGuessedLetters = Set<String>.from(state.guessedLetters)
      ..add(letter);
    int newRemainingLives = state.remainingLives;

    if (!state.secretWord.contains(letter)) {
      newRemainingLives--;
    }

    state = state.copyWith(
      guessedLetters: newGuessedLetters,
      remainingLives: newRemainingLives,
    );

    _checkGameState();
  }

  void _checkGameState() {
    bool wordGuessed = state.secretWord
        .split('')
        .every((letter) => state.guessedLetters.contains(letter));
    bool isGameOver = false;

    if (wordGuessed) {
      state = state.copyWith(status: GameStatus.win);
    } else if (state.remainingLives <= 0) {
      state = state.copyWith(status: GameStatus.lose);
      isGameOver = true;
    }
    if (isGameOver) {
      final historyEntry = ActivityHistory(
        activityType: 'word_guess',
        activityName: 'Đoán Từ Bí Ẩn',
        score: wordGuessed ? 1 : 0, // 1 điểm nếu thắng, 0 nếu thua
        totalItems: 1, // Mỗi lần chỉ đoán 1 từ
        completedAt: DateTime.now(),
      );
      FirebaseHistoryService.instance.addActivityToHistory(historyEntry);
    }
  }

  void startNewGame() {
    List<FlashcardItem> newRemainingWords = List.from(state.remainingWords);
    if (newRemainingWords.isEmpty) {
      newRemainingWords = List.from(state.allWords);
    }

    final randomWordItem = newRemainingWords.removeAt(
      Random().nextInt(newRemainingWords.length),
    );

    state = state.copyWith(
      remainingWords: newRemainingWords,
      secretWord: randomWordItem.term.toUpperCase().replaceAll(' ', ''),
      hint: randomWordItem.definition,
      guessedLetters: {},
      remainingLives: 6,
      status: GameStatus.playing,
    );
  }
}

// Provider để cung cấp Notifier cho UI
final wordGuessProvider = StateNotifierProvider.autoDispose
    .family<WordGuessNotifier, WordGuessState, List<FlashcardItem>>((
      ref,
      vocabularyItems,
    ) {
      return WordGuessNotifier(vocabularyItems);
    });
