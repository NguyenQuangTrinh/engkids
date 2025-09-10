// lib/providers/matching_game_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:engkids/models/activity_history_model.dart';
import 'package:engkids/service/firebase_history_service.dart';
import 'package:engkids/service/firebase_leaderboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/flashcard_item_model.dart';
import '../widgets/vocabulary/matchable_item_widget.dart'; // Cho MatchItemState

// Các class helper
class DisplayItem {
  final String id;
  final String text;
  final bool isTerm;
  MatchItemState uiState;
  DisplayItem({
    required this.id,
    required this.text,
    required this.isTerm,
    this.uiState = MatchItemState.normal,
  });
}

class ItemPlacement {
  final Point<double> position;
  final double rotation;
  ItemPlacement(this.position, this.rotation);
}

// Tham số đầu vào cho provider
@immutable
class MatchGameArgs {
  final List<FlashcardItem> vocabularyItems;
  final Size screenSize;
  const MatchGameArgs(this.vocabularyItems, this.screenSize);

  @override
  bool operator ==(Object other) =>
      other is MatchGameArgs &&
      other.vocabularyItems == vocabularyItems &&
      other.screenSize == screenSize;
  @override
  int get hashCode => Object.hash(vocabularyItems, screenSize);
}

// State class
@immutable
class MatchingGameState {
  final List<DisplayItem> displayItems;
  final Map<String, ItemPlacement> itemPlacements;
  final int matchedPairsCount;
  final int totalPairsInRound;
  final int elapsedSeconds;
  final bool isGameOver;
  final DisplayItem? selectedTerm;
  final DisplayItem? selectedDefinition;

  final List<FlashcardItem> allVocabulary;
  final List<FlashcardItem> unplayedWords;

  const MatchingGameState({
    this.displayItems = const [],
    this.itemPlacements = const {},
    this.matchedPairsCount = 0,
    this.totalPairsInRound = 0,
    this.elapsedSeconds = 0,
    this.isGameOver = false,
    this.selectedTerm,
    this.selectedDefinition,
    this.allVocabulary = const [],
    this.unplayedWords = const [],
  });

  MatchingGameState copyWith({
    List<DisplayItem>? displayItems,
    Map<String, ItemPlacement>? itemPlacements,
    int? matchedPairsCount,
    int? totalPairsInRound,
    int? elapsedSeconds,
    bool? isGameOver,
    DisplayItem? selectedTerm,
    DisplayItem? selectedDefinition,
    List<FlashcardItem>? unplayedWords,
    bool clearSelectedTerm = false,
    bool clearSelectedDefinition = false,
  }) {
    return MatchingGameState(
      displayItems: displayItems ?? this.displayItems,
      itemPlacements: itemPlacements ?? this.itemPlacements,
      matchedPairsCount: matchedPairsCount ?? this.matchedPairsCount,
      totalPairsInRound: totalPairsInRound ?? this.totalPairsInRound,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isGameOver: isGameOver ?? this.isGameOver,
      selectedTerm:
          clearSelectedTerm ? null : selectedTerm ?? this.selectedTerm,
      selectedDefinition:
          clearSelectedDefinition
              ? null
              : selectedDefinition ?? this.selectedDefinition,
      allVocabulary: allVocabulary, // Không thay đổi
      unplayedWords: unplayedWords ?? this.unplayedWords,
    );
  }
}

// Notifier
class MatchingGameNotifier extends StateNotifier<MatchingGameState> {
  final MatchGameArgs _args;
  Timer? _gameTimer;
  final _random = Random();
  final int itemsToDisplayPerType = 6;
  final int _gridCols = 3;
  final int _gridRows = 4;

  MatchingGameNotifier(this._args) : super(const MatchingGameState()) {
    final uniqueWords =
        _args.vocabularyItems.toSet().toList(); // Chống lặp từ nguồn
    state = MatchingGameState(
      allVocabulary: uniqueWords,
      unplayedWords: List.from(uniqueWords),
    );

    startNewRound();
  }

  void startNewRound() {
    _gameTimer?.cancel();
    _startTimer();

    var currentUnplayed = List<FlashcardItem>.from(state.unplayedWords);
    // Nếu không còn đủ từ chưa chơi, hãy reset lại danh sách
    if (currentUnplayed.length < itemsToDisplayPerType) {
      currentUnplayed = List.from(state.allVocabulary);
    }

    currentUnplayed.shuffle();
    List<FlashcardItem> roundFlashcards =
        currentUnplayed.take(itemsToDisplayPerType).toList();

    // Loại bỏ các từ đã được chọn khỏi danh sách chưa chơi
    final List<FlashcardItem> nextUnplayedWords =
        currentUnplayed
            .where((word) => !roundFlashcards.contains(word))
            .toList();

    List<DisplayItem> tempDisplayItems = [];
    for (var card in roundFlashcards) {
      tempDisplayItems.add(
        DisplayItem(id: card.id, text: card.term, isTerm: true),
      );
      tempDisplayItems.add(
        DisplayItem(id: card.id, text: card.definition, isTerm: false),
      );
    }
    tempDisplayItems.shuffle();

    final placements = _calculatePlacements(tempDisplayItems);

    state = state.copyWith(
      displayItems: tempDisplayItems,
      itemPlacements: placements,
      totalPairsInRound: roundFlashcards.length,
      unplayedWords: nextUnplayedWords, // Cập nhật danh sách từ chưa chơi
      matchedPairsCount: 0,
      elapsedSeconds: 0,
      isGameOver: false,
      clearSelectedTerm: true,
      clearSelectedDefinition: true,
    );
  }

  Map<String, ItemPlacement> _calculatePlacements(List<DisplayItem> items) {
    final Map<String, ItemPlacement> placements = {};
    final double appBarHeight = kToolbarHeight;
    final double topPadding = 50;
    final double bottomControlsHeight = 80;

    final double availableHeight =
        _args.screenSize.height -
        appBarHeight -
        topPadding -
        bottomControlsHeight;
    final double cellWidth = _args.screenSize.width / _gridCols;
    final double cellHeight = availableHeight / _gridRows;

    List<Point<double>> availablePositions = [];
    for (int row = 0; row < _gridRows; row++) {
      for (int col = 0; col < _gridCols; col++) {
        availablePositions.add(
          Point(
            (col * cellWidth) + (cellWidth / 2),
            (row * cellHeight) + (cellHeight / 2),
          ),
        );
      }
    }
    availablePositions.shuffle();

    // <<< THAY ĐỔI 3: Lặp qua danh sách thẻ được truyền vào, không phải `state.displayItems`
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      String itemKey = "${item.id}_${item.isTerm ? 'term' : 'def'}";

      double offsetX = (_random.nextDouble() - 0.5) * (cellWidth * 0.2);
      double offsetY = (_random.nextDouble() - 0.5) * (cellHeight * 0.2);
      double rotation = (_random.nextDouble() - 0.5) * 0.25;

      Point<double> finalPosition = Point(
        availablePositions[i].x + offsetX,
        availablePositions[i].y + offsetY,
      );
      placements[itemKey] = ItemPlacement(finalPosition, rotation);
    }
    return placements;
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void handleItemTap(DisplayItem tappedItem) {
    if (tappedItem.uiState != MatchItemState.normal) return;

    DisplayItem? newSelectedTerm = state.selectedTerm;
    DisplayItem? newSelectedDefinition = state.selectedDefinition;

    // Tạo một bản sao của danh sách để có thể thay đổi trạng thái
    final newDisplayItems = List<DisplayItem>.from(state.displayItems);
    final tappedItemInList = newDisplayItems.firstWhere(
      (item) => item.id == tappedItem.id && item.isTerm == tappedItem.isTerm,
    );
    tappedItemInList.uiState = MatchItemState.selected;

    if (tappedItem.isTerm) {
      if (newSelectedTerm != null) {
        newDisplayItems
            .firstWhere(
              (item) =>
                  item.id == newSelectedTerm!.id &&
                  item.isTerm == newSelectedTerm.isTerm,
            )
            .uiState = MatchItemState.normal;
      }
      newSelectedTerm = tappedItemInList;
    } else {
      if (newSelectedDefinition != null) {
        newDisplayItems
            .firstWhere(
              (item) =>
                  item.id == newSelectedDefinition!.id &&
                  item.isTerm == newSelectedDefinition.isTerm,
            )
            .uiState = MatchItemState.normal;
      }
      newSelectedDefinition = tappedItemInList;
    }

    state = state.copyWith(
      displayItems: newDisplayItems,
      selectedTerm: newSelectedTerm,
      selectedDefinition: newSelectedDefinition,
    );

    _checkMatch();
  }

  void _checkMatch() {
    final term = state.selectedTerm;
    final def = state.selectedDefinition;

    if (term != null && def != null) {
      bool isCorrect = term.id == def.id;
      final newDisplayItems = List<DisplayItem>.from(state.displayItems);
      final termInList = newDisplayItems.firstWhere(
        (item) => item.id == term.id && item.isTerm == true,
      );
      final defInList = newDisplayItems.firstWhere(
        (item) => item.id == def.id && item.isTerm == false,
      );

      if (isCorrect) {
        termInList.uiState = MatchItemState.matchedCorrectly;
        defInList.uiState = MatchItemState.matchedCorrectly;

        state = state.copyWith(
          displayItems: newDisplayItems,
          matchedPairsCount: state.matchedPairsCount + 1,
          clearSelectedTerm: true, // Xóa lựa chọn cũ
          clearSelectedDefinition: true, // Xóa lựa chọn cũ
        );

        if (state.matchedPairsCount == state.totalPairsInRound) {
          _endGame();
        }
      } else {
        termInList.uiState = MatchItemState.matchedIncorrectly;
        defInList.uiState = MatchItemState.matchedIncorrectly;
        state = state.copyWith(
          displayItems: newDisplayItems,
        ); // Cập nhật UI để hiển thị màu đỏ

        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            // Chỉ trả về trạng thái normal nếu nó vẫn còn là incorrect
            if (termInList.uiState == MatchItemState.matchedIncorrectly)
              termInList.uiState = MatchItemState.normal;
            if (defInList.uiState == MatchItemState.matchedIncorrectly)
              defInList.uiState = MatchItemState.normal;

            // Xóa lựa chọn cũ sau khi hiệu ứng kết thúc
            state = state.copyWith(
              displayItems: newDisplayItems,
              clearSelectedTerm: true,
              clearSelectedDefinition: true,
            );
          }
        });
      }
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    state = state.copyWith(isGameOver: true);

    // Gửi điểm lên Bảng xếp hạng
    FirebaseLeaderboardService.instance.submitScore(
      "matching_game",
      state.elapsedSeconds,
    );

    // <<< THÊM LOGIC LƯU LỊCH SỬ Ở ĐÂY
    final historyEntry = ActivityHistory(
      activityType: 'matching_game',
      activityName: 'Nối Từ Siêu Tốc', // Hoặc có thể truyền tên bộ từ vào
      score: state.matchedPairsCount,
      totalItems: state.totalPairsInRound,
      completedAt: DateTime.now(),
    );
    FirebaseHistoryService.instance.addActivityToHistory(historyEntry);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

// Provider
final matchingGameProvider = StateNotifierProvider.autoDispose
    .family<MatchingGameNotifier, MatchingGameState, MatchGameArgs>((
      ref,
      args,
    ) {
      return MatchingGameNotifier(args);
    });
