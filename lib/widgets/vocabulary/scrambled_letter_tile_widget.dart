import 'package:flutter/material.dart';

class ScrambledLetterTileWidget extends StatelessWidget {
  final String letter;
  final bool isUsed; // Đánh dấu chữ cái này đã được chọn vào ô trả lời chưa
  final VoidCallback onTap;

  const ScrambledLetterTileWidget({
    super.key,
    required this.letter,
    required this.isUsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUsed ? 0.3 : 1.0, // Làm mờ nếu đã được sử dụng
      child: InkWell(
        onTap: isUsed ? null : onTap, // Không cho nhấn nếu đã dùng
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 40, // Kích thước ô chữ
          height: 40,
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              color: isUsed ? Colors.grey[300] : Colors.blue[100],
              border: Border.all(color: Colors.blue[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isUsed ? [] : [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                )
              ]
          ),
          alignment: Alignment.center,
          child: Text(
            letter.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isUsed ? Colors.grey[600] : Colors.blue[800],
            ),
          ),
        ),
      ),
    );
  }
}