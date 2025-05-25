import 'package:flutter/material.dart';

class QuizProgressHeader extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final int timeRemainingInSeconds;

  const QuizProgressHeader({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.timeRemainingInSeconds,
  });

  // Hàm định dạng thời gian từ giây thành MM:SS
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final String progressText = 'Câu ${currentQuestionIndex + 1} / $totalQuestions';
    final String timeText = _formatDuration(timeRemainingInSeconds);
    final bool timeRunningLow = timeRemainingInSeconds <= 60; // Ví dụ: dưới 1 phút

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đặt 2 text ở 2 đầu
      children: [
        Text(
          progressText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16, // Điều chỉnh kích thước nếu cần
          ),
        ),
        Text(
          timeText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: timeRunningLow ? Colors.yellowAccent : Colors.white, // Đổi màu khi gần hết giờ
            fontSize: 16,
            shadows: timeRunningLow ? [ // Thêm hiệu ứng nhấp nháy nhẹ khi gần hết giờ
              Shadow(color: Colors.red.withValues(alpha: 0.7), blurRadius: 5)
            ] : null,
          ),
        ),
      ],
    );
  }
}