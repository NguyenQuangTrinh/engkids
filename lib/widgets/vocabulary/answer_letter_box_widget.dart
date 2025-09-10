// lib/widgets/vocabulary/answer_letter_box_widget.dart

import 'package:flutter/material.dart';

class AnswerLetterBoxWidget extends StatelessWidget {
  final String? letter; // Chữ cái (hoặc null nếu ô trống)
  final bool isHighlighted; // Đánh dấu ô đang được focus để xóa (tùy chọn)
  final bool isHint;

  const AnswerLetterBoxWidget({
    super.key,
    this.letter,
    this.isHighlighted = false,
    this.isHint = false,
  });

  @override
  Widget build(BuildContext context) {
    Color boxColor;
    Color borderColor;

    // <<< LOGIC MỚI ĐỂ XÁC ĐỊNH MÀU
    if (isHint) {
      boxColor = Colors.amber[100]!;
      borderColor = Colors.amber[600]!;
    } else if (letter != null) {
      boxColor = Colors.green[100]!;
      borderColor = Colors.green[400]!;
    } else {
      boxColor = Colors.grey[200]!;
      borderColor = Colors.grey[400]!;
    }

    if (isHighlighted) {
      borderColor = Colors.redAccent;
    }
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      decoration: BoxDecoration(
        color: boxColor,
        border: Border.all(color: borderColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: Text(
        (letter ?? "").toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: letter != null ? Colors.black87 : Colors.grey[500],
        ),
      ),
    );
  }
}
