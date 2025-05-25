// lib/screens/vocabulary/word_scramble_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:developer' as developer;
import '../../main.dart';
import '../../models/flashcard_item_model.dart';
// Import các widget con mới
import '../../service/high_scores_database_service.dart';
import '../../widgets/vocabulary/word_scramble/answer_construction_area_widget.dart';
import '../../widgets/vocabulary/word_scramble/scrambled_letters_display_widget.dart';
import '../../widgets/vocabulary/word_scramble/word_scramble_controls_widget.dart';
import '../../widgets/vocabulary/word_scramble/round_ended_view_widget.dart';

// ScrambledLetter class giữ nguyên từ phiên bản trước
class ScrambledLetter {
  final String letter;
  final int originalIndex;
  bool isUsed;
  ScrambledLetter({required this.letter, required this.originalIndex, this.isUsed = false});
}

class WordScrambleScreen extends StatefulWidget {
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const WordScrambleScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  WordScrambleScreenState createState() => WordScrambleScreenState();
}

class WordScrambleScreenState extends State<WordScrambleScreen> with RouteAware {
  static const String _logName = 'com.engkids.wordscramble';
  final int wordsPerRound = 5;
  final int hintsPerWord = 1; // <<< SỐ LƯỢT GỢI Ý CHO MỖI TỪ
  bool _isHintModeActive = false; // <<< STATE CHO CHẾ ĐỘ GỢI Ý
  int _hintsRemainingThisWord = 0; // <<< SỐ GỢI Ý CÒN LẠI CHO TỪ HIỆN TẠI

  List<FlashcardItem> _roundWords = [];
  int _currentWordIndexInRound = 0;

  FlashcardItem? _currentTargetWordItem;
  List<ScrambledLetter> _displayedScrambledLetters = [];
  List<ScrambledLetter?> _userInputLetters = [];

  int _score = 0;
  String _feedbackMessage = "";
  bool _gameEnded = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  // --- Thêm State cho Timer ---
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  // ---------------------------
  String? _playerName = "EngKid Player"; // Tạm thời

  @override
  void initState() {
    super.initState();
    if (widget.vocabularyItems.isEmpty) {
      _handleEmptyVocabulary();
      return;
    }
    _keyboardFocusNode.addListener(() {
      developer.log("FocusNode has focus: ${_keyboardFocusNode.hasFocus}", name: _logName);
    });
    _startNewRound();
    // Yêu cầu focus sau khi frame đầu tiên được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Dùng mounted trực tiếp thay vì _isMounted cho addPostFrameCallback
        FocusScope.of(context).requestFocus(_keyboardFocusNode);
        developer.log("Requested focus in addPostFrameCallback. Current focus: ${_keyboardFocusNode.hasFocus}", name: _logName);
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _keyboardFocusNode.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // void _startTimer() {
  //   _gameTimer?.cancel();
  //   _elapsedSeconds = 0;
  //   _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (mounted) {
  //       setState(() {
  //         _elapsedSeconds++;
  //       });
  //     } else {
  //       timer.cancel();
  //     }
  //   });
  // }

  void _handleEmptyVocabulary() {
    developer.log("Không có từ vựng để chơi Word Scramble.", name: _logName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bộ từ này trống!"), backgroundColor: Colors.orange));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      // Nếu là lần đầu tiên route được tạo và push, có thể request focus ở đây
      // Tuy nhiên, didPopNext sẽ xử lý khi quay lại màn hình này.
      // Để focus khi màn hình vừa được push, bạn có thể thêm một cờ firstTime.
    }
  }

  @override
  void didPush() {
    // Route được push vào navigator, có thể yêu cầu focus nếu đây là màn hình mới
    developer.log("WordScrambleScreen: didPush - Requesting focus", name: _logName);
    // Đảm bảo rằng việc request focus ở đây không xung đột nếu màn hình được resume từ background
    // Có thể cần kiểm tra xem có phải là lần đầu tiên push không
    // Hoặc chỉ đơn giản là để didPopNext xử lý khi nó trở thành top.
    // For initial push, it's often better to request focus after frame build if needed.
    // Let's rely on didPopNext for now, and initState for initial load.
    // We'll keep the initState one with addPostFrameCallback for the very first load.
  }

  @override
  void didPopNext() {
    // Route này được pop về (trở thành route hiện tại)
    developer.log("WordScrambleScreen: didPopNext - Requesting focus.", name: _logName);
    if (mounted) { // Kiểm tra mounted
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    }
  }

  @override
  void didPushNext() {
    // Một route khác được push lên trên route này (route này bị che đi)
    developer.log("WordScrambleScreen: didPushNext - Unfocusing.", name: _logName);
    _keyboardFocusNode.unfocus();
  }

  @override
  void didPop() {
    // Route này đang bị pop ra khỏi navigator
    developer.log("WordScrambleScreen: didPop - Unfocusing.", name: _logName);
    _keyboardFocusNode.unfocus(); // Quan trọng: unfocus trước khi bị hủy hoàn toàn
  }

  void _startNewRound(){
    List<FlashcardItem> allItems = List.from(widget.vocabularyItems)..shuffle();
    _roundWords = allItems.take(wordsPerRound).toList();
    _currentWordIndexInRound = 0;
    _score = 0;
    _feedbackMessage = "";
    _gameEnded = false;
    if(_roundWords.isNotEmpty){
      _setupNextWord();
    } else {
      developer.log("Không lấy được từ nào cho vòng chơi mới.", name: _logName);
      if(mounted) setState(() { _gameEnded = true; _feedbackMessage = "Không có từ để chơi!"; });
    }
  }

  void _setupNextWord() {
    if (_currentWordIndexInRound >= _roundWords.length) {
      _endRound();
      return;
    }
    _currentTargetWordItem = _roundWords[_currentWordIndexInRound];
    _userInputLetters = List.filled(_currentTargetWordItem!.term.length, null, growable: false);
    _feedbackMessage = "";
    _isHintModeActive = false; // <<< RESET CHẾ ĐỘ GỢI Ý
    _hintsRemainingThisWord = hintsPerWord; // <<< RESET SỐ LƯỢT GỢI Ý

    List<ScrambledLetter> tempScrambled = [];
    for (int i = 0; i < _currentTargetWordItem!.term.length; i++) {
      tempScrambled.add(ScrambledLetter(letter: _currentTargetWordItem!.term[i], originalIndex: i));
    }

    String originalWord = _currentTargetWordItem!.term;
    String scrambled;
    Random random = Random();
    if (originalWord.length > 1) { // Chỉ xáo trộn nếu từ có nhiều hơn 1 chữ cái
      do {
        tempScrambled.shuffle(random);
        scrambled = tempScrambled.map((e) => e.letter).join();
      } while (scrambled == originalWord);
    } else {
      scrambled = originalWord; // Giữ nguyên nếu chỉ có 1 chữ cái
    }


    if (mounted) {
      setState(() {
        _displayedScrambledLetters = tempScrambled;
      });
    }
    developer.log("Từ mới: $originalWord, đã xáo trộn: $scrambled", name: _logName);
  }

  // Hàm kích hoạt chế độ gợi ý
  void _activateHintMode() {
    if (_currentTargetWordItem == null || _gameEnded) return;

    if (_hintsRemainingThisWord > 0) {
      // Kiểm tra xem còn ô nào trống hoặc điền sai không
      bool canRevealMore = false;
      for(int i=0; i < _currentTargetWordItem!.term.length; i++){
        if(_userInputLetters[i] == null || _userInputLetters[i]!.letter != _currentTargetWordItem!.term[i]){
          canRevealMore = true;
          break;
        }
      }
      if (!canRevealMore) {
        if (mounted) setState(() { _feedbackMessage = "Các chữ cái đã đúng hoặc đã được điền hết!"; });
        return;
      }


      if (mounted) {
        setState(() {
          _isHintModeActive = true;
          _feedbackMessage = "Chạm vào một ô trống để nhận gợi ý chữ cái.";
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _feedbackMessage = "Bạn đã hết lượt gợi ý cho từ này!";
        });
      }
    }
  }

  // Hàm xử lý khi người dùng chạm vào một ô trong khu vực trả lời
  void _handleUserInputLetterTap(int indexInUserInput) {
    if (_isHintModeActive) {
      _revealLetterInSlot(indexInUserInput);
      _keyboardFocusNode.requestFocus();
      return;
    }

    if (_userInputLetters.length > indexInUserInput && _userInputLetters[indexInUserInput] != null && mounted) {
      setState(() {
        ScrambledLetter letterToReturn = _userInputLetters[indexInUserInput]!;
        letterToReturn.isUsed = false;
        _userInputLetters[indexInUserInput] = null;
        _feedbackMessage = "";
      });
      _keyboardFocusNode.requestFocus();
    }
  }

  // Hàm tiết lộ chữ cái đúng cho một ô cụ thể
  void _revealLetterInSlot(int slotIndex) {
    if (_currentTargetWordItem == null || slotIndex < 0 || slotIndex >= _currentTargetWordItem!.term.length) return;

    final String correctLetter = _currentTargetWordItem!.term[slotIndex];

    // Nếu ô đó đã có chữ đúng rồi thì không làm gì
    if (_userInputLetters[slotIndex] != null && _userInputLetters[slotIndex]!.letter == correctLetter) {
      if (mounted) setState(() { _isHintModeActive = false; _feedbackMessage = "Ô này đã có chữ đúng!"; });
      return;
    }

    // Nếu ô đó đang có chữ sai, trả chữ sai về pool
    if (_userInputLetters[slotIndex] != null) {
      _userInputLetters[slotIndex]!.isUsed = false;
    }

    // Tìm một ScrambledLetter tương ứng CHƯA ĐƯỢC SỬ DỤNG trong _displayedScrambledLetters
    ScrambledLetter? letterToPlaceFromPool;
    for (var sl in _displayedScrambledLetters) {
      if (sl.letter == correctLetter && !sl.isUsed) {
        letterToPlaceFromPool = sl;
        break;
      }
    }

    if (letterToPlaceFromPool != null) {
      if (mounted) {
        setState(() {
          _userInputLetters[slotIndex] = letterToPlaceFromPool; // Đặt chữ cái đúng vào ô
          letterToPlaceFromPool!.isUsed = true; // Đánh dấu đã dùng
          _hintsRemainingThisWord--;
          _isHintModeActive = false; // Tắt chế độ gợi ý sau khi dùng
          _feedbackMessage = "Gợi ý đã được áp dụng!";
        });
      }
    } else {
      // Trường hợp hiếm: không tìm thấy chữ cái đúng chưa dùng trong pool
      // (Có thể do người dùng đã tự điền đúng hết các chữ cái đó)
      // Hoặc nếu từ có nhiều chữ giống nhau và tất cả đã được dùng.
      // Trong trường hợp này, nếu ô hiện tại không đúng, ta vẫn có thể điền chữ đúng
      // nhưng không lấy từ pool (chỉ hiển thị). Nhưng để đơn giản, nếu không có trong pool thì báo.
      developer.log("Không tìm thấy chữ '$correctLetter' chưa dùng trong pool để gợi ý.", name: _logName);
      if (mounted) {
        setState(() {
          _isHintModeActive = false;
          _feedbackMessage = "Không thể gợi ý chữ này ngay bây giờ.";
        });
      }
    }
  }

  void _handleScrambledLetterTap(ScrambledLetter tappedLetter) {
    if (tappedLetter.isUsed || _isHintModeActive) return;

    int emptySlotIndex = _userInputLetters.indexWhere((slot) => slot == null);
    if (emptySlotIndex != -1 && mounted) {
      setState(() {
        _userInputLetters[emptySlotIndex] = tappedLetter;
        tappedLetter.isUsed = true;
        _feedbackMessage = "";
      });

      // Quan trọng: Yêu cầu lại focus sau khi setState
      _keyboardFocusNode.requestFocus(); // <<< THÊM DÒNG NÀY

      if (_userInputLetters.every((slot) => slot != null)) {
        _checkAnswer();
      }
    }
  }

  void _clearLastUserInputLetter() {
    if (_isHintModeActive) return;
    int lastFilledSlotIndex = _userInputLetters.lastIndexWhere((slot) => slot != null);
    if (lastFilledSlotIndex != -1) {
      // _handleUserInputLetterTap sẽ gọi setState và chúng ta cũng cần requestFocus ở đó
      _handleUserInputLetterTap(lastFilledSlotIndex);
    }
  }

  void _checkAnswer() {
    if (_currentTargetWordItem == null) return;
    // Không cần kiểm tra độ dài nữa vì hàm này chỉ được gọi khi đã điền đủ
    String userAnswer = _userInputLetters.where((sl) => sl != null).map((sl) => sl!.letter).join();

    if (userAnswer.toLowerCase() == _currentTargetWordItem!.term.toLowerCase()) {
      if (mounted) {
        setState(() {
          _score += 10;
          _feedbackMessage = "Chính xác! +10 điểm";
        });
      }
      developer.log("Trả lời đúng: $userAnswer", name: _logName);
      // Chờ một chút rồi chuyển từ
      Future.delayed(const Duration(milliseconds: 1500), () { // Thời gian hiển thị feedback "Chính xác!"
        if (mounted && userAnswer.toLowerCase() == _currentTargetWordItem?.term.toLowerCase()) { // Kiểm tra lại phòng trường hợp người dùng thay đổi nhanh
          setState(() {
            _currentWordIndexInRound++;
          });
          _setupNextWord();
        }
      });
    } else {
      if (mounted) setState(() { _feedbackMessage = "Chưa đúng, thử lại nhé!"; });
      developer.log("Trả lời sai: $userAnswer, đúng là: ${_currentTargetWordItem!.term}", name: _logName);
    }
  }

  void _skipWord() {
    if (_currentTargetWordItem == null || _gameEnded || _isHintModeActive) return;
    developer.log("Bỏ qua từ: ${_currentTargetWordItem!.term}", name: _logName);
    if (mounted) {
      setState(() {
        _feedbackMessage = "Bạn đã bỏ qua từ: ${_currentTargetWordItem!.term}";
        _currentWordIndexInRound++;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _setupNextWord();
      });
    }
  }



  void _endRound() {
    _gameTimer?.cancel(); // <<< DỪNG TIMER KHI KẾT THÚC VÒNG
    developer.log("Kết thúc vòng chơi WordScramble! Thời gian: $_elapsedSeconds giây, Điểm: $_score", name: _logName);
    if(mounted) setState(() { _gameEnded = true; });


    HighScoresDatabaseService.instance.addHighScore(
      "word_scramble", // Game type
      _elapsedSeconds,   // Thời gian hoàn thành
      playerName: _playerName,
    );
  }

  // *** HÀM XỬ LÝ SỰ KIỆN BÀN PHÍM MỚI HOẶC CẬP NHẬT ***
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // *** THÊM LOG Ở ĐẦU HÀM ĐỂ XEM SỰ KIỆN CÓ ĐƯỢC NHẬN KHÔNG ***
    developer.log(
        "KeyEvent received: Key: ${event.logicalKey.keyLabel}, Char: ${event.character}, Type: ${event.runtimeType}",
        name: _logName);
    // **********************************************************

    if (_gameEnded || _isHintModeActive) return KeyEventResult.ignored;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        developer.log("Backspace key pressed via keyboard", name: _logName);
        _clearLastUserInputLetter();
        return KeyEventResult.handled;
      }

      final String? char = event.character;
      if (char != null && char.isNotEmpty) {
        final RegExp alphaRegex = RegExp(r'^[a-zA-Z]$');
        if (alphaRegex.hasMatch(char)) {
          final String typedChar = char.toUpperCase();
          developer.log("Alphabetic key pressed: $typedChar", name: _logName);

          ScrambledLetter? letterToSelect;
          for (var sl in _displayedScrambledLetters) {
            if (sl.letter.toUpperCase() == typedChar && !sl.isUsed) {
              letterToSelect = sl;
              break;
            }
          }

          if (letterToSelect != null) {
            _handleScrambledLetterTap(letterToSelect);
            return KeyEventResult.handled;
          } else {
            developer.log("No available unused letter '$typedChar' found in scrambled pool.", name: _logName);
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }


  @override
  Widget build(BuildContext context) {
    if (_gameEnded && _roundWords.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.setName)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_feedbackMessage.isNotEmpty ? _feedbackMessage : "Không có từ vựng để chơi!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text("Quay lại"))
                ],
              ),
            ),
          ));
    }

    Widget gamePlayContent() {
      if (_currentTargetWordItem == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy controls xuống dưới
        children: [
          Column(
            children: [
              SizedBox(height: 20),
              AnswerConstructionAreaWidget(
                userInputLetters: _userInputLetters,
                targetWordLength: _currentTargetWordItem?.term.length ?? 0,
                onUserInputLetterTap: _handleUserInputLetterTap,
                onClearLastLetter: _clearLastUserInputLetter,
              ),
              SizedBox(height: 30),
              ScrambledLettersDisplayWidget(
                displayedScrambledLetters: _displayedScrambledLetters,
                onScrambledLetterTap: _handleScrambledLetterTap,
              ),
            ],
          ),
          Padding( // Phần dưới: Phản hồi và nút kiểm tra/bỏ qua
            padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
            child: WordScrambleControlsWidget( // Sẽ truyền thêm callback và state cho nút Gợi ý
              feedbackMessage: _feedbackMessage,
              onSkipWord: _skipWord,
              canUseHint: _hintsRemainingThisWord > 0 && !_isHintModeActive, // Điều kiện để hiện nút Gợi ý
              isHintModeActive: _isHintModeActive, // Trạng thái chế độ gợi ý
              onUseHint: _activateHintMode, // Hàm kích hoạt chế độ gợi ý
            ),
          ),
        ],
      );
    }

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.setName} - Đố Chữ"),
          backgroundColor: Colors.cyan[700],
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    Text("Điểm: $_score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Time: ${_formatDuration(_elapsedSeconds)}", style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            )
          ],
        ),
        body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - kToolbarHeight - MediaQuery.of(context).padding.top - 20),
                  child: _gameEnded
                      ? RoundEndedViewWidget(
                    score: _score,
                    totalPossibleScore: _roundWords.length * 10,
                    onPlayAgain: _startNewRound,
                    onBackToMenu: () => Navigator.of(context).pop(),
                  )
                      : gamePlayContent(),
                ),
              );
            }
        ),
        // floatingActionButton: _gameEnded || _roundWords.isEmpty // Không cần FAB nếu đã có nút trong RoundEndedView
        //     ? null
        //     : FloatingActionButton.extended(
        //         onPressed: _startNewRound,
        //         label: Text("Vòng mới"),
        //         icon: Icon(Icons.refresh_rounded),
        //       ),
      ),
    );
  }
}