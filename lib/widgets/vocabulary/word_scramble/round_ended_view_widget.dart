import 'package:flutter/material.dart';

class RoundEndedViewWidget extends StatelessWidget {
  final int score;
  final int totalPossibleScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const RoundEndedViewWidget({
    super.key,
    required this.score,
    required this.totalPossibleScore,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_rounded, color: Colors.amber, size: 70),
            SizedBox(height: 20),
            Text("Vòng chơi kết thúc!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Tổng điểm của bạn: $score / $totalPossibleScore",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh_rounded),
              label: Text("Chơi vòng mới"),
              onPressed: onPlayAgain,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: onBackToMenu,
              child: Text("Về Menu Từ Vựng"),
            )
          ],
        ),
      ),
    );
  }
}