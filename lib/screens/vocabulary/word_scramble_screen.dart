// lib/screens/vocabulary/word_scramble_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/flashcard_item_model.dart';
import '../../providers/word_scramble_provider.dart';
import '../../widgets/vocabulary/word_scramble/answer_construction_area_widget.dart';
import '../../widgets/vocabulary/word_scramble/scrambled_letters_display_widget.dart';
import '../../widgets/vocabulary/word_scramble/round_ended_view_widget.dart';

// <<< CHUYỂN SANG ConsumerStatefulWidget
class WordScrambleScreen extends ConsumerStatefulWidget {
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const WordScrambleScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  ConsumerState<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

// <<< TẠO LỚP ConsumerState
class _WordScrambleScreenState extends ConsumerState<WordScrambleScreen> {
  // <<< THÊM LẠI CÁC BIẾN STATE CỤC BỘ CHO ANIMATION
  Key _animationAreaKey = UniqueKey();
  bool _lastAnswerWasCorrect = false;
  late FlutterTts _flutterTts;
  bool _isHintModeActive = false;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _setupTts();
  }

  void _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Vẫn dùng `ref.watch` để lấy state từ Notifier
    final gameState = ref.watch(wordScrambleProvider(widget.vocabularyItems));
    final gameNotifier = ref.read(
      wordScrambleProvider(widget.vocabularyItems).notifier,
    );

    // <<< DÙNG ref.listen ĐỂ KÍCH HOẠT ANIMATION
    // `listen` sẽ chạy mỗi khi state thay đổi, nhưng không build lại toàn bộ widget
    ref.listen(wordScrambleProvider(widget.vocabularyItems), (
      previousState,
      newState,
    ) {
      // Chỉ kích hoạt animation khi có feedback mới (tức là người dùng vừa trả lời)
      if (previousState?.feedbackMessage != newState.feedbackMessage &&
          newState.feedbackMessage.isNotEmpty && previousState?.wordToSpeak != newState.wordToSpeak && newState.wordToSpeak != null) {
        setState(() {
          _lastAnswerWasCorrect = newState.feedbackMessage.contains(
            "Chính xác",
          );
          _animationAreaKey = UniqueKey(); // Tạo Key mới để rebuild widget con
        });
        _speak(newState.wordToSpeak!);
        gameNotifier.clearWordToSpeak();
      }
    });

    bool canUseHint = false;
    // Quy tắc 1: Luôn có 1 gợi ý miễn phí lúc bắt đầu một từ mới.
    if (gameState.hintedIndices.isEmpty) {
      canUseHint = true;
    }
    // Quy tắc 2: Gợi ý tiếp theo chỉ có khi đã sai 2 lần.
    // (Giả sử ta chỉ cho phép tối đa 2 gợi ý)
    else if (gameState.hintedIndices.length == 1) {
      canUseHint = gameState.incorrectGuessesThisWord >= 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.setName} - Đố Chữ"),
        backgroundColor: Colors.cyan[700],
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Điểm: ${gameState.score}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Time: ${_formatDuration(gameState.elapsedSeconds)}",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child:
            gameState.gameStatus == GameStatus.ended
                ? RoundEndedViewWidget(
                  score: gameState.score,
                  totalPossibleScore: gameState.roundWords.length * 10,
                  onPlayAgain: gameNotifier.startNewRound,
                  onBackToMenu: () => Navigator.of(context).pop(),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          canUseHint
                              ? () {
                                setState(() {
                                  _isHintModeActive = true;
                                });
                              }
                              : null, // Vô hiệu hóa nếu chưa sai đủ 2 lần
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text("Gợi ý"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isHintModeActive ? Colors.amber[700] : Colors.teal,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                    ),
                    if (_isHintModeActive)
                      const Text(
                        "Hãy chọn một ô trống để nhận gợi ý",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    // <<< TRUYỀN KEY VÀ CÁC BIẾN ANIMATION VÀO WIDGET CON
                    AnswerConstructionAreaWidget(
                      key: _animationAreaKey,
                      userInputLetters: gameState.userInputLetters,
                      targetWordLength:
                          gameState.currentTargetWord?.term.length ?? 0,
                      isHintModeActive: _isHintModeActive,
                      hintedIndices: gameState.hintedIndices,
                      onUserInputLetterTap: (index) {
                        if (_isHintModeActive) {
                          gameNotifier.revealHintForIndex(index);
                          setState(() {
                            _isHintModeActive = false;
                          });
                        } else {
                          gameNotifier.handleUserInputLetterTap(index);
                        }
                      },
                      onClearLastLetter: () {
                        final lastFilledIndex = gameState.userInputLetters
                            .lastIndexWhere((l) => l != null);
                        if (lastFilledIndex != -1) {
                          gameNotifier.handleUserInputLetterTap(
                            lastFilledIndex,
                          );
                        }
                      },
                      answerWasCorrect: _lastAnswerWasCorrect,
                    ),

                    Text(
                      gameState.feedbackMessage,
                      style: TextStyle(
                        color:
                            gameState.feedbackMessage.contains("Chính xác")
                                ? Colors.green
                                : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ScrambledLettersDisplayWidget(
                      displayedScrambledLetters:
                          gameState.displayedScrambledLetters,
                      onScrambledLetterTap:
                          gameNotifier.handleScrambledLetterTap,
                    ),
                  ],
                ),
      ),
    );
  }
}
