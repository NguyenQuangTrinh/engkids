// lib/screens/game/waiting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/challenges_provider.dart';
import 'tic_tac_toe_screen.dart';

class WaitingScreen extends ConsumerWidget {
  final String challengeId;
  const WaitingScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe sự thay đổi của lời mời
    final challengeAsync = ref.watch(singleChallengeProvider(challengeId));

    return Scaffold(
      appBar: AppBar(title: const Text("Đang chờ...")),
      body: Center(
        child: challengeAsync.when(
          data: (doc) {
            if (!doc.exists) {
              return const Text("Lời mời đã bị hủy.");
            }
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];

            if (status == 'accepted') {
              final sessionId = data['gameSessionId'];
              // Tự động điều hướng khi đối thủ chấp nhận
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TicTacToeScreen(sessionId: sessionId)));
                }
              });
              return const Text("Đối thủ đã chấp nhận! Đang vào trận...");
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Đã gửi lời mời, đang chờ đối thủ chấp nhận...", style: TextStyle(fontSize: 16)),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text("Lỗi: $e"),
        ),
      ),
    );
  }
}