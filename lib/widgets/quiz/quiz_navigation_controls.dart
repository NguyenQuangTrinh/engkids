// lib/widgets/quiz/quiz_navigation_controls.dart

import 'package:flutter/material.dart';

class QuizNavigationControls extends StatelessWidget {
  final bool isFirstQuestion;
  final bool isLastQuestion;
  final bool isAnswerSelected; // Kiểm tra xem đáp án hiện tại đã được chọn chưa
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextOrFinishPressed;

  const QuizNavigationControls({
    super.key,
    required this.isFirstQuestion,
    required this.isLastQuestion,
    required this.isAnswerSelected,
    required this.onPreviousPressed,
    required this.onNextOrFinishPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 5.0), // Thêm padding bottom
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút "Câu trước"
          ElevatedButton.icon(
            onPressed: isFirstQuestion ? null : onPreviousPressed,
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18), // Giảm kích thước icon
            label: Text("Trước"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Điều chỉnh padding
            ),
          ),

          // Nút "Tiếp theo" hoặc "Hoàn thành"
          ElevatedButton.icon(
            onPressed: isAnswerSelected ? onNextOrFinishPressed : null, // Vô hiệu hóa nếu chưa chọn đáp án
            icon: isLastQuestion
                ? Icon(Icons.check_circle_outline_rounded, size: 18)
                : Icon(Icons.arrow_forward_ios_rounded, size: 18),
            label: Text(isLastQuestion ? "Hoàn thành" : "Tiếp theo"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastQuestion ? Colors.green : Colors.pinkAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              disabledForegroundColor: Colors.grey[700],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Điều chỉnh padding
            ),
          ),
        ],
      ),
    );
  }
}