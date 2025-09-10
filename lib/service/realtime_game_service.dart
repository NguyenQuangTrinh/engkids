// lib/service/realtime_game_service.dart

import 'package:engkids/models/user_profile_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeGameService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RealtimeGameService._privateConstructor();
  static final RealtimeGameService instance =
      RealtimeGameService._privateConstructor();

  String? get _userId => _auth.currentUser?.uid;

  // Hàm tạo một phòng chơi mới
  Future<String?> createGameSession(UserProfile opponentProfile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final newSessionRef = _rtdb.ref().child('game_sessions').push();

    final initialData = {
      'status': 'race_active',
      'createdAt': ServerValue.timestamp,
      'winner': null,
      'currentTurn': currentUser.uid, // Người chấp nhận đi trước (ví dụ)
      'players': {
        // Thông tin người chơi hiện tại (người chấp nhận)
        currentUser.uid: {
          'displayName': currentUser.displayName ?? 'Player 1',
          'photoURL': currentUser.photoURL ?? '',
          'score': 0,
        },
        // Thông tin đối thủ (người thách đấu)
        opponentProfile.uid: {
          'displayName': opponentProfile.displayName,
          'photoURL': opponentProfile.photoURL,
          'score': 0,
        },
      },
      'board': List.filled(9, null),
      'activeMiniGame': {'type': 'word_scramble', 'completedBy': null},
    };

    await newSessionRef.set(initialData);
    return newSessionRef.key;
  }

  // Lấy một Stream để lắng nghe thay đổi của một phòng chơi cụ thể
  Stream<DatabaseEvent> getGameSessionStream(String sessionId) {
    return _rtdb.ref('game_sessions/$sessionId').onValue;
  }

  // Hàm cập nhật bàn cờ
  Future<void> updateBoard(String sessionId, List<String?> board) async {
    await _rtdb.ref('game_sessions/$sessionId/board').set(board);
  }

  Future<void> makeMove(
    String sessionId,
    int index,
    Map<dynamic, dynamic> sessionData,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    // Lấy thông tin hiện tại từ sessionData
    final currentBoard = List<dynamic>.from(
      sessionData['board'] ?? List.filled(9, null),
    );
    final currentTurnPlayerId = sessionData['currentTurn'] as String? ?? '';
    final players = Map<String, dynamic>.from(sessionData['players'] ?? {});
    final playerIds = players.keys.toList();

    // Kiểm tra các điều kiện hợp lệ
    if (userId == currentTurnPlayerId && currentBoard[index] == null) {
      // 1. Cập nhật bàn cờ
      currentBoard[index] = userId;

      // 2. Kiểm tra xem có người thắng chưa
      final winnerId = _checkWinner(currentBoard);

      // 3. Kiểm tra xem có hòa không
      final isDraw = winnerId == null && !currentBoard.contains(null);

      // 4. Xác định lượt đi tiếp theo
      final nextPlayerId = playerIds.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      // 5. Chuẩn bị dữ liệu để cập nhật lên Realtime Database
      Map<String, dynamic> updates = {
        'board': currentBoard,
        'currentTurn': nextPlayerId, // Chuyển lượt
      };

      if (winnerId != null) {
        updates['status'] = 'finished';
        updates['winner'] = winnerId;
      } else if (isDraw) {
        updates['status'] = 'finished';
        updates['winner'] = 'draw'; // Dùng 'draw' để đánh dấu hòa
      }

      // Gửi toàn bộ cập nhật lên server
      await _rtdb.ref('game_sessions/$sessionId').update(updates);
    }
  }

  // Hàm helper để kiểm tra người thắng
  String? _checkWinner(List<dynamic> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Hàng ngang
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Hàng dọc
      [0, 4, 8], [2, 4, 6], // Hàng chéo
    ];
    for (var line in lines) {
      final a = board[line[0]];
      final b = board[line[1]];
      final c = board[line[2]];
      if (a != null && a == b && a == c) {
        return a as String; // Trả về UID của người thắng
      }
    }
    return null; // Chưa có ai thắng
  }
}
