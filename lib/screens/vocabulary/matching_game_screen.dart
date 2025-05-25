// lib/screens/vocabulary/matching_game_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Cho việc xáo trộn và random vị trí
import 'dart:async';
import 'dart:developer' as developer;
import '../../models/flashcard_item_model.dart';
import '../../service/high_scores_database_service.dart';
import '../../widgets/vocabulary/matchable_item_widget.dart';

// DisplayItem class đã được sửa đổi để chứa vị trí
class DisplayItem {
  final String id; // Dùng ID của FlashcardItem gốc để dễ dàng nhận diện cặp
  final String text;
  final FlashcardItem originalItem;
  final bool isTerm;
  MatchItemState uiState;
  double top; // Vị trí top
  double left; // Vị trí left
  final GlobalKey itemKey = GlobalKey(); // Key để lấy kích thước nếu cần

  DisplayItem({
    required this.id,
    required this.text,
    required this.originalItem,
    required this.isTerm,
    this.uiState = MatchItemState.normal,
    this.top = 0.0,
    this.left = 0.0,
  });
}

class MatchingGameScreen extends StatefulWidget {
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const MatchingGameScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  MatchingGameScreenState createState() => MatchingGameScreenState();
}

class MatchingGameScreenState extends State<MatchingGameScreen> {
  static const String _logName = 'com.engkids.matchinggame.random';
  final int itemsToDisplayPerType = 8; // Số lượng TỪ (sẽ có số lượng NGHĨA tương ứng)
  // Tổng số thẻ sẽ là itemsToDisplayPerType * 2

  // time and name player
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  final String _playerName = "Eng Player";

  List<DisplayItem> _displayItems = []; // Danh sách TẤT CẢ các thẻ (cả term và definition)
  DisplayItem? _selectedTermDisplayItem;
  DisplayItem? _selectedDefinitionDisplayItem;

  int _score = 0;
  int _matchedPairsCount = 0;
  int _totalPairsInRound = 0;

  Size _screenSize = Size.zero; // Kích thước màn hình để giới hạn vị trí random
  bool _isLayoutBuilt = false; // Cờ để biết layout đã build xong chưa

  // Kích thước ước tính của thẻ để tránh chồng chéo (cần điều chỉnh)
  final double _cardRenderWidth = 120.0; // Chiều rộng thẻ sẽ cố gắng không vượt quá
  final double _cardRenderHeight = 50.0; // Chiều cao thẻ ước tính
  final double _positioningPadding = 8.0; // Khoảng cách tối thiểu giữa các thẻ và với biên

  @override
  void dispose() {
    _gameTimer?.cancel(); // Quan trọng: hủy timer
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _elapsedSeconds = 0;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() { _elapsedSeconds++; });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.vocabularyItems.isEmpty) { // Chỉ cần ít nhất 1 cặp để chơi
      developer.log("Không đủ từ vựng để bắt đầu game Matching.", name: _logName);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Không đủ từ vựng để chơi."), backgroundColor: Colors.orange));
        }
      });
      return;
    }
    // Việc gọi _setupNewRound cần kích thước màn hình, sẽ gọi sau khi layout build lần đầu
    // Hoặc trong LayoutBuilder
  }

  void _initializePositionsAndSetupRound() {
    if (!_isLayoutBuilt || _screenSize == Size.zero) {
      developer.log("Layout chưa sẵn sàng hoặc screen size là zero.", name: _logName);
      return;
    }
    developer.log("Bắt đầu setup vòng mới. Screen size: $_screenSize", name: _logName);

    List<FlashcardItem> availableFlashcards = List.from(widget.vocabularyItems)..shuffle();
    List<FlashcardItem> roundFlashcards = availableFlashcards.take(itemsToDisplayPerType).toList();

    if (roundFlashcards.isEmpty) {
      developer.log("Không chọn được từ nào cho vòng chơi.", name: _logName);
      if (mounted) setState(() { _displayItems = []; });
      return;
    }
    _totalPairsInRound = roundFlashcards.length;

    List<DisplayItem> tempDisplayItems = [];
    for (var flashcard in roundFlashcards) {
      tempDisplayItems.add(DisplayItem(id: flashcard.id, text: flashcard.term, originalItem: flashcard, isTerm: true));
      tempDisplayItems.add(DisplayItem(id: flashcard.id, text: flashcard.definition, originalItem: flashcard, isTerm: false));
    }
    tempDisplayItems.shuffle();

    final Random random = Random();
    List<Rect> occupiedRects = [];

    // Tính toán vùng khả dụng để đặt thẻ
    // kToolbarHeight là chiều cao AppBar mặc định, MediaQuery.of(context).padding.top là status bar
    // Giả sử có một vùng điều khiển ở dưới (ví dụ FAB) cao khoảng 70-80px
    final double appBarHeight = AppBar().preferredSize.height; // Lấy chiều cao AppBar thực tế
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomControlsHeight = 80.0; // Ước tính chiều cao cho FAB và khoảng trống dưới

    final double availableWidth = _screenSize.width - _cardRenderWidth - (2 * _positioningPadding);
    final double availableHeight = _screenSize.height - appBarHeight - topPadding - _cardRenderHeight - (2 * _positioningPadding) - bottomControlsHeight;

    developer.log("Vùng đặt thẻ khả dụng: Width=$availableWidth, Height=$availableHeight", name: _logName);

    for (var item in tempDisplayItems) {
      bool positionFound = false;
      for (int tries = 0; tries < 100; tries++) { // Tăng số lần thử
        double left = _positioningPadding + (availableWidth > 0 ? random.nextDouble() * availableWidth : 0);
        double top = _positioningPadding + (availableHeight > 0 ? random.nextDouble() * availableHeight : 0);

        Rect newItemRect = Rect.fromLTWH(left, top, _cardRenderWidth, _cardRenderHeight);
        // Kiểm tra chồng chéo, cho phép một chút nếu cần
        bool overlaps = occupiedRects.any((rect) => rect.overlaps(newItemRect.inflate(_positioningPadding * 0.5)));

        if (!overlaps || tries > 80) { // Nếu thử nhiều lần không được thì chấp nhận chồng chéo nhẹ
          item.left = left.clamp(_positioningPadding, _screenSize.width - _cardRenderWidth - _positioningPadding);
          item.top = top.clamp(_positioningPadding, _screenSize.height - appBarHeight - topPadding - _cardRenderHeight - _positioningPadding - bottomControlsHeight);
          occupiedRects.add(newItemRect);
          positionFound = true;
          break;
        }
      }
      if (!positionFound) {
        // Nếu vẫn không tìm được, đặt ở vị trí ngẫu nhiên trong vùng cho phép
        item.left = (_positioningPadding + (availableWidth > 0 ? random.nextDouble() * availableWidth : 0)).clamp(_positioningPadding, _screenSize.width - _cardRenderWidth - _positioningPadding);
        item.top = (_positioningPadding + (availableHeight > 0 ? random.nextDouble() * availableHeight : 0)).clamp(_positioningPadding, _screenSize.height - appBarHeight - topPadding - _cardRenderHeight - _positioningPadding - bottomControlsHeight);
        developer.log("Không tìm được vị trí tối ưu cho '${item.text}', có thể bị chồng chéo.", name: _logName);
      }
    }

    if (mounted) {
      setState(() {
        _displayItems = tempDisplayItems;
        _matchedPairsCount = 0;
        _score = 0;
        _selectedTermDisplayItem = null;
        _selectedDefinitionDisplayItem = null;
      });
      _startTimer();
    }
    developer.log("Đã setup vòng mới với ${_displayItems.length} thẻ, $_totalPairsInRound cặp.", name: _logName);
  }


  void _handleItemTap(DisplayItem tappedItem) {
    if (tappedItem.uiState == MatchItemState.matchedCorrectly || _selectedTermDisplayItem == tappedItem || _selectedDefinitionDisplayItem == tappedItem) {
      return; // Bỏ qua nếu đã nối đúng hoặc chọn lại chính nó
    }

    setState(() {
      if (tappedItem.isTerm) {
        if (_selectedTermDisplayItem != null) _selectedTermDisplayItem!.uiState = MatchItemState.normal; // Bỏ chọn term cũ
        _selectedTermDisplayItem = tappedItem;
        _selectedTermDisplayItem!.uiState = MatchItemState.selected;
      } else { // is Definition
        if (_selectedDefinitionDisplayItem != null) _selectedDefinitionDisplayItem!.uiState = MatchItemState.normal; // Bỏ chọn definition cũ
        _selectedDefinitionDisplayItem = tappedItem;
        _selectedDefinitionDisplayItem!.uiState = MatchItemState.selected;
      }
    });

    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedTermDisplayItem != null && _selectedDefinitionDisplayItem != null) {
      // ID của originalItem phải giống nhau để xác định là một cặp
      bool isCorrectMatch = _selectedTermDisplayItem!.originalItem.id == _selectedDefinitionDisplayItem!.originalItem.id;

      if (isCorrectMatch) {
        developer.log("Nối đúng: ${_selectedTermDisplayItem!.text} -> ${_selectedDefinitionDisplayItem!.text}", name: _logName);
        setState(() {
          _selectedTermDisplayItem!.uiState = MatchItemState.matchedCorrectly;
          _selectedDefinitionDisplayItem!.uiState = MatchItemState.matchedCorrectly;
          _score += 10;
          _matchedPairsCount++;
          _clearSelectionsAfterAttempt(correctMatch: true);
        });
        if (_matchedPairsCount == _totalPairsInRound) {
          _gameTimer?.cancel(); // <<< DỪNG TIMER KHI HOÀN THÀNH
          _saveHighScore("matching_game", _elapsedSeconds);
          _showRoundCompleteDialog();
        }
      } else {
        developer.log("Nối sai!", name: _logName);
        final tempTerm = _selectedTermDisplayItem;
        final tempDef = _selectedDefinitionDisplayItem;
        setState(() {
          tempTerm?.uiState = MatchItemState.matchedIncorrectly;
          tempDef?.uiState = MatchItemState.matchedIncorrectly;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              if (tempTerm?.uiState == MatchItemState.matchedIncorrectly) tempTerm?.uiState = MatchItemState.normal;
              if (tempDef?.uiState == MatchItemState.matchedIncorrectly) tempDef?.uiState = MatchItemState.normal;
              _clearSelectionsAfterAttempt(correctMatch: false);
            });
          }
        });
      }
    }
  }

  void _clearSelectionsAfterAttempt({required bool correctMatch}) {
    if(!correctMatch){
      if (_selectedTermDisplayItem?.uiState != MatchItemState.matchedCorrectly) _selectedTermDisplayItem?.uiState = MatchItemState.normal;
      if (_selectedDefinitionDisplayItem?.uiState != MatchItemState.matchedCorrectly) _selectedDefinitionDisplayItem?.uiState = MatchItemState.normal;
    }
    _selectedTermDisplayItem = null;
    _selectedDefinitionDisplayItem = null;
  }

  // save high score
  Future<void> _saveHighScore(String gameType, int timeInSeconds) async {
    try {
      await HighScoresDatabaseService.instance.addHighScore(
        gameType,
        timeInSeconds,
        playerName: _playerName, // Sử dụng tên người chơi (nếu có)
      );
      developer.log("Đã lưu thành tích: $gameType, time: $timeInSeconds giây", name: _logName);
    } catch (e,s) {
      developer.log("Lỗi khi lưu thành tích cho $gameType", name: _logName, error: e, stackTrace: s);
    }
  }

  void _showRoundCompleteDialog() {
    developer.log("Hiển thị dialog hoàn thành vòng chơi. Điểm: $_score", name: _logName);
    showDialog<void>( // Thêm <void> để rõ ràng hơn
      context: context,
      barrierDismissible: false, // Người dùng phải chọn một hành động
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Bo góc dialog
          title: Row( // Thêm icon vào title
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 28),
              SizedBox(width: 10),
              Text("Tuyệt vời!"),
            ],
          ),
          content: SingleChildScrollView( // Đảm bảo nội dung không tràn nếu text dài
            child: ListBody(
              children: <Widget>[
                Text(
                  "Bạn đã nối đúng tất cả $_matchedPairsCount cặp từ!",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text("Thời gian hoàn thành:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  _formatDuration(_elapsedSeconds), // Hiển thị thời gian
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                ),
                Text(
                  "Điểm số của bạn:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  "$_score", // Hiển thị điểm số
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark, // Hoặc một màu nổi bật khác
                  ),
                ),
                // TODO: Có thể thêm thông tin thời gian hoàn thành nếu bạn đã đo
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly, // Căn đều các nút actions
          actions: <Widget>[
            TextButton(
              child: Text("Quay lại Menu", style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
                if (mounted) { // Kiểm tra mounted trước khi pop màn hình game
                  Navigator.of(context).pop(); // Quay lại FunVocabularyMenuScreen
                }
              },
            ),
            ElevatedButton.icon( // Làm nút "Chơi lại" nổi bật hơn
              icon: Icon(Icons.refresh_rounded),
              label: Text("Chơi lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent, // Màu nút chơi lại
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
                // Gọi lại hàm setup vòng mới (đã bao gồm reset score và matchedPairsCount)
                // Đảm bảo _isLayoutBuilt vẫn là true để không gọi lại LayoutBuilder không cần thiết
                if (mounted && _isLayoutBuilt) {
                  _initializePositionsAndSetupRound();
                } else if (mounted) {
                  // Nếu _isLayoutBuilt là false (trường hợp hiếm), có thể cần build lại layout
                  // Hoặc đơn giản là gọi _setupNewRound nếu nó không phụ thuộc vào kích thước màn hình
                  // đã được tính lại từ LayoutBuilder.
                  // Với logic hiện tại, _initializePositionsAndSetupRound cần _screenSize từ LayoutBuilder
                  // nên nếu _isLayoutBuilt=false thì việc gọi lại có thể không đúng.
                  // Tốt nhất là đảm bảo _isLayoutBuilt = true trước khi cho chơi.
                  // Hoặc có thể thêm logic để rebuild LayoutBuilder nếu cần.
                  // Trong trường hợp này, vì dialog chỉ hiện khi _isLayoutBuilt đã true,
                  // nên có thể chỉ cần gọi _initializePositionsAndSetupRound().
                  _initializePositionsAndSetupRound();
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (widget.vocabularyItems.isEmpty && _displayItems.isEmpty && !_isLayoutBuilt) {
      // Trường hợp không đủ từ đã được xử lý ở initState, đây là fallback.
      // Hoặc trường hợp LayoutBuilder chưa chạy để set _isLayoutBuilt
      return Scaffold(
        appBar: AppBar(title: Text(widget.setName)),
        body: Center(child: Text("Đang tải hoặc không đủ từ...")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.setName} - Nối từ"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          Center(child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    Text("Điểm: $_score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Time: ${_formatDuration(_elapsedSeconds)}", style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),

              ),
            ],
          ))
        ],
      ),
      body: LayoutBuilder( // Sử dụng LayoutBuilder để lấy kích thước màn hình
        builder: (context, constraints) {
          if (!_isLayoutBuilt) { // Chỉ gọi một lần sau khi có constraints
            _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            _isLayoutBuilt = true;
            // Gọi _setupNewRound sau khi đã có _screenSize
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(widget.vocabularyItems.isNotEmpty) _initializePositionsAndSetupRound();
            });
            return const Center(child: CircularProgressIndicator()); // Hiển thị loading trong khi setup
          }

          if (_displayItems.isEmpty && widget.vocabularyItems.isNotEmpty) {
            // Trường hợp _initializePositionsAndSetupRound chưa kịp cập nhật _displayItems
            return const Center(child: CircularProgressIndicator());
          }
          if (_displayItems.isEmpty && widget.vocabularyItems.isEmpty) {
            return const Center(child: Text("Không có từ vựng để hiển thị."));
          }


          return Stack( // Sử dụng Stack để đặt các thẻ tự do
            children: _displayItems.map((item) {
              return Positioned(
                key: item.itemKey, // Gán key cho mỗi item nếu cần lấy size sau này
                left: item.left,
                top: item.top,
                child: MatchableItemWidget(
                  text: item.text,
                  uiState: item.uiState,
                  onTap: () => _handleItemTap(item),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _gameTimer?.cancel();
          if (_isLayoutBuilt) _initializePositionsAndSetupRound(); // Chỉ cho phép chơi lại khi layout đã sẵn sàng
        },
        label: Text("Vòng mới"),
        icon: Icon(Icons.refresh_rounded),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}