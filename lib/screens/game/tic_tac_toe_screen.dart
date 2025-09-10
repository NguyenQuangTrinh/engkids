// lib/screens/game/tic_tac_toe_screen.dart

import 'package:engkids/screens/game/flame/tic_tac_toe_game.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../service/realtime_game_service.dart'; // <<< Import service

class TicTacToeScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const TicTacToeScreen({super.key, required this.sessionId});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen> {
  late final TicTacToeGame _game;

  @override
  void initState() {
    super.initState();
    _game = TicTacToeGame(
      // <<< NÂNG CẤP LOGIC onCellTap
      onCellTap: (index) {
        // Dùng `ref.read` để lấy trạng thái hiện tại của game mà không cần "watch"
        final gameSession =
            ref.read(gameSessionProvider(widget.sessionId)).asData?.value;
        if (gameSession != null) {
          final data = gameSession.snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            // Gọi hàm makeMove từ service
            RealtimeGameService.instance.makeMove(
              widget.sessionId,
              index,
              data,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameSessionAsync = ref.watch(gameSessionProvider(widget.sessionId));
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ván đấu Cờ Caro"),
        backgroundColor: Colors.indigoAccent,
      ),
      body: gameSessionAsync.when(
        data: (event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) {
            return const Center(child: Text("Phòng chơi không tồn tại."));
          }

          final boardData = List<dynamic>.from(data['board'] ?? []);
          final playersData = Map<String, dynamic>.from(data['players'] ?? {});
          final currentTurn = data['currentTurn'] as String? ?? '';
          final status = data['status'] as String? ?? '';
          final winner = data['winner'] as String?;

          // Ra lệnh cho game Flame cập nhật lại bàn cờ
          _game.updateBoard(boardData, playersData);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // <<< HIỂN THỊ THÔNG BÁO TRẠNG THÁI
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: _buildStatusText(
                  status,
                  winner,
                  currentTurn,
                  currentUserId,
                  playersData,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GameWidget(game: _game),
                  ),
                ),
              ),
              if (status == 'finished')
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Về Menu"),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Lỗi kết nối: $err")),
      ),
    );
  }

  Widget _buildStatusText(
    String status,
    String? winner,
    String currentTurn,
    String? currentUserId,
    Map<String, dynamic> players,
  ) {
    if (status == 'finished') {
      if (winner == 'draw') {
        return const Text(
          "Hòa!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
      }
      if (winner == currentUserId) {
        return const Text(
          "🎉 Bạn đã thắng!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        );
      } else {
        final winnerName = players[winner]?['displayName'] ?? 'Đối thủ';
        return Text(
          "Bạn đã thua! $winnerName thắng.",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      }
    }

    final turnText =
        (currentTurn == currentUserId)
            ? "Đến lượt bạn!"
            : "Đang chờ đối thủ...";
    return Text(turnText, style: const TextStyle(fontSize: 22));
  }
}
