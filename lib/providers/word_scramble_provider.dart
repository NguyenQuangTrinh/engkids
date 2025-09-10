// lib/providers/word_scramble_provider.dart

import 'dart:async';
import 'package:engkids/models/activity_history_model.dart';
import 'package:engkids/service/firebase_history_service.dart';
import 'package:engkids/service/firebase_leaderboard_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard_item_model.dart';

// Class ScrambledLetter vẫn được dùng
class ScrambledLetter {
  final String letter;
  final int originalIndex;
  bool isUsed;
  ScrambledLetter({
    required this.letter,
    required this.originalIndex,
    this.isUsed = false,
  });
}

enum GameStatus { playing, ended }

// State class để chứa toàn bộ trạng thái của game
@immutable
class WordScrambleState {
  final List<FlashcardItem> roundWords;
  final int currentWordIndex;
  final FlashcardItem? currentTargetWord;
  final List<ScrambledLetter> displayedScrambledLetters;
  final List<ScrambledLetter?> userInputLetters;
  final int score;
  final String feedbackMessage;
  final GameStatus gameStatus;
  final int elapsedSeconds;
  final int incorrectGuessesThisWord;
  final Set<int> hintedIndices;
  final String? wordToSpeak;

  const WordScrambleState({
    required this.roundWords,
    required this.currentWordIndex,
    this.currentTargetWord,
    this.displayedScrambledLetters = const [],
    this.userInputLetters = const [],
    this.score = 0,
    this.feedbackMessage = "",
    this.gameStatus = GameStatus.playing,
    this.elapsedSeconds = 0,
    this.incorrectGuessesThisWord = 0,
    this.hintedIndices = const {},
    this.wordToSpeak,
  });

  WordScrambleState copyWith({
    List<FlashcardItem>? roundWords,
    int? currentWordIndex,
    FlashcardItem? currentTargetWord,
    List<ScrambledLetter>? displayedScrambledLetters,
    List<ScrambledLetter?>? userInputLetters,
    int? score,
    String? feedbackMessage,
    GameStatus? gameStatus,
    int? elapsedSeconds,
    int? incorrectGuessesThisWord,
    Set<int>? hintedIndices,
    String? wordToSpeak,

    bool resetWordToSpeak = false,
  }) {
    return WordScrambleState(
      roundWords: roundWords ?? this.roundWords,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      currentTargetWord: currentTargetWord ?? this.currentTargetWord,
      displayedScrambledLetters:
          displayedScrambledLetters ?? this.displayedScrambledLetters,
      userInputLetters: userInputLetters ?? this.userInputLetters,
      score: score ?? this.score,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      gameStatus: gameStatus ?? this.gameStatus,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      incorrectGuessesThisWord:
          incorrectGuessesThisWord ?? this.incorrectGuessesThisWord,
      hintedIndices: hintedIndices ?? this.hintedIndices,
      wordToSpeak: resetWordToSpeak ? null : wordToSpeak ?? this.wordToSpeak,
    );
  }
}

// Notifier quản lý logic
class WordScrambleNotifier extends StateNotifier<WordScrambleState> {
  final List<FlashcardItem> _allVocabularyItems;
  final int wordsPerRound = 15;
  Timer? _gameTimer;

  WordScrambleNotifier(this._allVocabularyItems)
    : super(_initialState(_allVocabularyItems, 15)) {
    _startTimer();
  }

  static WordScrambleState _initialState(
    List<FlashcardItem> allItems,
    int wordsPerRound,
  ) {
    List<FlashcardItem> roundWords =
        (List<FlashcardItem>.from(allItems)
          ..shuffle()).take(wordsPerRound).toList();
    if (roundWords.isEmpty) {
      return const WordScrambleState(
        roundWords: [],
        currentWordIndex: 0,
        gameStatus: GameStatus.ended,
        feedbackMessage: "Không có từ để chơi!",
      );
    }
    return _setupWordState(
      WordScrambleState(roundWords: roundWords, currentWordIndex: 0),
    );
  }

  static WordScrambleState _setupWordState(WordScrambleState currentState) {
    final currentWordItem =
        currentState.roundWords[currentState.currentWordIndex];
    final term = currentWordItem.term;

    List<ScrambledLetter> tempScrambled = [];
    for (int i = 0; i < term.length; i++) {
      tempScrambled.add(ScrambledLetter(letter: term[i], originalIndex: i));
    }

    if (term.length > 1) {
      String scrambled;
      do {
        tempScrambled.shuffle();
        scrambled = tempScrambled.map((e) => e.letter).join();
      } while (scrambled == term);
    }

    return currentState.copyWith(
      currentTargetWord: currentWordItem,
      userInputLetters: List.filled(term.length, null),
      displayedScrambledLetters: tempScrambled,
      feedbackMessage: "",
      incorrectGuessesThisWord: 0,
      hintedIndices: {},
      resetWordToSpeak: true,
    );
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      } else {
        timer.cancel();
      }
    });
  }

  void handleScrambledLetterTap(ScrambledLetter tappedLetter) {
    if (tappedLetter.isUsed) return;
    int emptySlotIndex = state.userInputLetters.indexWhere(
      (slot) => slot == null,
    );
    if (emptySlotIndex != -1) {
      final newUserInput = List<ScrambledLetter?>.from(state.userInputLetters);
      final newScrambled = List<ScrambledLetter>.from(
        state.displayedScrambledLetters,
      );

      tappedLetter.isUsed = true;
      newUserInput[emptySlotIndex] = tappedLetter;

      state = state.copyWith(
        userInputLetters: newUserInput,
        displayedScrambledLetters: newScrambled,
      );

      if (state.userInputLetters.every((slot) => slot != null)) {
        checkAnswer();
      }
    }
  }

  void revealHintForIndex(int index) {
    if (state.hintedIndices.contains(index) ||
        state.userInputLetters[index] != null)
      return;

    final correctLetter = state.currentTargetWord!.term[index];
    ScrambledLetter? letterFromPool;
    for (var sl in state.displayedScrambledLetters) {
      if (sl.letter == correctLetter && !sl.isUsed) {
        letterFromPool = sl;
        break;
      }
    }

    if (letterFromPool != null) {
      final newUserInput = List<ScrambledLetter?>.from(state.userInputLetters);
      newUserInput[index] = letterFromPool;
      letterFromPool.isUsed = true;

      final newHintedIndices = Set<int>.from(state.hintedIndices)..add(index);

      state = state.copyWith(
        userInputLetters: newUserInput,
        hintedIndices: newHintedIndices,
      );

      if (state.userInputLetters.every((slot) => slot != null)) {
        checkAnswer();
      }
    }
  }

  void handleUserInputLetterTap(int indexInUserInput) {
    // Không cho phép xóa ô đã được gợi ý
    if (state.hintedIndices.contains(indexInUserInput)) return;

    if (state.userInputLetters.length <= indexInUserInput ||
        state.userInputLetters[indexInUserInput] == null)
      return;

    final newUserInput = List<ScrambledLetter?>.from(state.userInputLetters);
    ScrambledLetter letterToReturn = newUserInput[indexInUserInput]!;
    letterToReturn.isUsed = false;
    newUserInput[indexInUserInput] = null;

    state = state.copyWith(userInputLetters: newUserInput, feedbackMessage: "");
  }

  void clearWordToSpeak() {
    state = state.copyWith(resetWordToSpeak: true);
  }

  void checkAnswer() {
    String userAnswer =
        state.userInputLetters
            .where((l) => l != null)
            .map((l) => l!.letter)
            .join();
    if (userAnswer.toLowerCase() ==
        state.currentTargetWord!.term.toLowerCase()) {
      state = state.copyWith(
        score: state.score + 10,
        feedbackMessage: "Chính xác! +10 điểm",
        wordToSpeak: state.currentTargetWord!.term, // <<< Kích hoạt TTS
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _moveToNextWord();
      });
    } else {
      state = state.copyWith(
        feedbackMessage: "Chưa đúng, thử lại nhé!",
        incorrectGuessesThisWord:
            state.incorrectGuessesThisWord + 1, // <<< Đếm lỗi sai
      );
    }
  }

  void _moveToNextWord() {
    if (state.currentWordIndex < state.roundWords.length - 1) {
      state = _setupWordState(
        state.copyWith(currentWordIndex: state.currentWordIndex + 1),
      );
    } else {
      _endRound();
    }
  }

  void skipWord() {
    state = state.copyWith(
      feedbackMessage: "Bạn đã bỏ qua từ: ${state.currentTargetWord!.term}",
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _moveToNextWord();
    });
  }

  void _endRound() {
    _gameTimer?.cancel();
    state = state.copyWith(gameStatus: GameStatus.ended);

    FirebaseLeaderboardService.instance.submitScore(
      "word_scramble",
      state.elapsedSeconds,
    );

    // <<< THÊM LOGIC LƯU LỊCH SỬ Ở ĐÂY
    final historyEntry = ActivityHistory(
      activityType: 'word_scramble',
      activityName: 'Giải Đố Chữ',
      score: state.score ~/ 10, // Giả sử mỗi từ đúng được 10 điểm
      totalItems: state.roundWords.length,
      completedAt: DateTime.now(),
    );
    FirebaseHistoryService.instance.addActivityToHistory(historyEntry);
  }

  void startNewRound() {
    _gameTimer?.cancel();
    state = _initialState(_allVocabularyItems, wordsPerRound);
    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

// Provider
final wordScrambleProvider = StateNotifierProvider.autoDispose
    .family<WordScrambleNotifier, WordScrambleState, List<FlashcardItem>>((
      ref,
      vocabularyItems,
    ) {
      return WordScrambleNotifier(vocabularyItems);
    });
