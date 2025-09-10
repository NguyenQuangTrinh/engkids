// lib/providers/game_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../service/realtime_game_service.dart';

// Provider này nhận vào một `sessionId` và trả về một Stream
// chứa dữ liệu (dưới dạng DatabaseEvent) của phòng chơi đó.
final gameSessionProvider = StreamProvider.family<DatabaseEvent, String>((ref, sessionId) {
  // Nếu không có sessionId, trả về stream rỗng
  if (sessionId.isEmpty) {
    return const Stream.empty();
  }
  
  // Gọi service để lấy stream
  return RealtimeGameService.instance.getGameSessionStream(sessionId);
});