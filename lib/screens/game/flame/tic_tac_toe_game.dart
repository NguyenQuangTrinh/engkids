// lib/games/flame/tic_tac_toe_game.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

typedef OnCellTap = void Function(int index);

// Lớp game chính của chúng ta
class TicTacToeGame extends FlameGame with TapCallbacks {
  late final OnCellTap onCellTap;
  // Lưu trữ UID của 2 người chơi để biết vẽ X hay O
  String player1Id = '';
  String player2Id = '';

  TicTacToeGame({required this.onCellTap});

  // Kích thước và màu sắc của bàn cờ
  static final Paint _gridPaint =
      Paint()
        ..color = Colors.blueGrey
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Thêm các ô cờ vào game
    _addGridCells();
  }

  // Hàm vẽ bàn cờ 3x3
  void _addGridCells() {
    final double gameSize = size.x; // Giả sử game là hình vuông
    final double cellSize = gameSize / 3;

    for (int i = 0; i < 9; i++) {
      final int row = i ~/ 3;
      final int col = i % 3;

      add(
        GridCell(
          index: i,
          position: Vector2(col * cellSize, row * cellSize),
          size: Vector2.all(cellSize),
          onTap: onCellTap,
        ),
      );
    }
  }

  void updateBoard(List<dynamic> boardData, Map<String, dynamic> players) {
    // Lấy ID của 2 người chơi
    final playerIds = players.keys.toList();
    player1Id = playerIds.isNotEmpty ? playerIds[0] : '';
    player2Id = playerIds.length > 1 ? playerIds[1] : '';

    // Lặp qua từng ô cờ trong Flame
    children.whereType<GridCell>().forEach((cell) {
      if (cell.index < boardData.length) {
        // Cập nhật trạng thái của ô cờ dựa trên dữ liệu từ DB
        cell.occupiedBy = boardData[cell.index] as String?;
      }
    });
  }

  // Ghi đè hàm render để vẽ các đường kẻ
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double gameSize = size.x;
    final double cellSize = gameSize / 3;

    // Vẽ 2 đường kẻ dọc
    canvas.drawLine(
      Offset(cellSize, 0),
      Offset(cellSize, gameSize),
      _gridPaint,
    );
    canvas.drawLine(
      Offset(cellSize * 2, 0),
      Offset(cellSize * 2, gameSize),
      _gridPaint,
    );
    // Vẽ 2 đường kẻ ngang
    canvas.drawLine(
      Offset(0, cellSize),
      Offset(gameSize, cellSize),
      _gridPaint,
    );
    canvas.drawLine(
      Offset(0, cellSize * 2),
      Offset(gameSize, cellSize * 2),
      _gridPaint,
    );
  }
}

// Component đại diện cho mỗi ô trong bàn cờ
class GridCell extends PositionComponent with TapCallbacks {
  final int index;
  final OnCellTap onTap;
  String? occupiedBy;

  GridCell({
    required this.index,
    required this.onTap,
    required super.position,
    required super.size,
  });

  // Ghi đè hàm onTapUp để xử lý khi người dùng chạm vào ô
  @override
  void onTapUp(TapUpEvent event) {
    // Khi được chạm, gọi callback để báo cho widget Flutter biết
    onTap(index);
  }

  // Ghi đè hàm render để vẽ dấu X hoặc O
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Vẽ dấu X
    if (occupiedBy == 'X') {
      final paint =
          Paint()
            ..color = Colors.red
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round;
      // Vẽ 2 đường chéo
      canvas.drawLine(
        const Offset(20, 20),
        Offset(size.x - 20, size.y - 20),
        paint,
      );
      canvas.drawLine(Offset(size.x - 20, 20), Offset(20, size.y - 20), paint);
    }
    // Vẽ dấu O
    else if (occupiedBy == 'O') {
      final paint =
          Paint()
            ..color = Colors.blue
            ..strokeWidth = 6
            ..style = PaintingStyle.stroke;
      // Vẽ hình tròn
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 - 20, paint);
    }
  }
}
