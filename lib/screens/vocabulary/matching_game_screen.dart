// lib/screens/vocabulary/matching_game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/flashcard_item_model.dart';
import '../../providers/matching_game_provider.dart';
import '../../widgets/vocabulary/matchable_item_widget.dart';

// <<< TÁCH PHẦN NỘI DUNG GAME RA MỘT WIDGET RIÊNG
// Widget này sẽ chịu trách nhiệm lắng nghe và hiển thị dialog
class _MatchingGameBoard extends ConsumerWidget {
  final MatchGameArgs args;

  const _MatchingGameBoard({required this.args});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showRoundCompleteDialog(BuildContext context, MatchingGameState gameState, MatchingGameNotifier gameNotifier) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 28),
              const SizedBox(width: 10),
              const Text("Tuyệt vời!"),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Bạn đã nối đúng tất cả ${gameState.matchedPairsCount} cặp từ!", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                const Text("Thời gian hoàn thành:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  _formatDuration(gameState.elapsedSeconds),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: Text("Quay lại Menu", style: TextStyle(color: Colors.grey[700])),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Chơi lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                gameNotifier.startNewRound();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `ref.listen` giờ nằm trong hàm build của một ConsumerWidget hợp lệ.
    ref.listen(matchingGameProvider(args), (previous, next) {
      // Chỉ hiển thị dialog khi trạng thái isGameOver chuyển từ false sang true
      final prevIsGameOver = previous?.isGameOver ?? false;
      if (prevIsGameOver == false && next.isGameOver == true) {
        _showRoundCompleteDialog(context, next, ref.read(matchingGameProvider(args).notifier));
      }
    });

    final gameState = ref.watch(matchingGameProvider(args));
    final gameNotifier = ref.read(matchingGameProvider(args).notifier);

    if (gameState.displayItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final double estimatedCardWidth = 150.0;
    final double estimatedCardHeight = 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Nối từ"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("Time: ${_formatDuration(gameState.elapsedSeconds)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: gameState.displayItems.map((item) {
          String itemKey = "${item.id}_${item.isTerm ? 'term' : 'def'}";
          ItemPlacement? placement = gameState.itemPlacements[itemKey];

          if (placement == null) return const SizedBox.shrink();

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            left: placement.position.x - (estimatedCardWidth / 2),
            top: placement.position.y - (estimatedCardHeight / 2),
            child: Transform.rotate(
              angle: placement.rotation,
              child: SizedBox(
                width: estimatedCardWidth,
                child: MatchableItemWidget(
                  text: item.text,
                  uiState: item.uiState,
                  onTap: () => gameNotifier.handleItemTap(item),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: gameNotifier.startNewRound,
        label: const Text("Vòng mới"),
        icon: const Icon(Icons.refresh_rounded),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}


// Màn hình chính giờ chỉ có nhiệm vụ lấy kích thước và truyền xuống
class MatchingGameScreen extends ConsumerWidget {
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const MatchingGameScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Chỉ cần một Scaffold trống để chứa LayoutBuilder
      // AppBar và FAB sẽ được quản lý bởi widget con `_MatchingGameBoard`
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Lấy kích thước và tạo đối tượng args
          final args = MatchGameArgs(vocabularyItems, constraints.biggest);
          // Trả về widget con chịu trách nhiệm cho toàn bộ game
          return _MatchingGameBoard(args: args);
        }
      ),
    );
  }
}