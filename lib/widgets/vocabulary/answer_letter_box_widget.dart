import 'package:flutter/material.dart';

class AnswerLetterBoxWidget extends StatelessWidget {
  final String? letter; // Chữ cái (hoặc null nếu ô trống)
  final bool isHighlighted; // Đánh dấu ô đang được focus để xóa (tùy chọn)

  const AnswerLetterBoxWidget({
    super.key,
    this.letter,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      decoration: BoxDecoration(
        color: letter != null ? Colors.green[100] : Colors.grey[200],
        border: Border.all(
          color: isHighlighted ? Colors.redAccent : (letter != null ? Colors.green[400]! : Colors.grey[400]!),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: Text(
        (letter ?? "").toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: letter != null ? Colors.green[800] : Colors.grey[500],
        ),
      ),
    );
  }
}