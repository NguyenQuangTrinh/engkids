// lib/widgets/vocabulary/word_guess/keyboard_key_widget.dart

import 'package:flutter/material.dart';

class KeyboardKeyWidget extends StatelessWidget {
  final String letter;
  final bool isEnabled;
  final VoidCallback onTap;

  const KeyboardKeyWidget({
    super.key,
    required this.letter,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: ElevatedButton(
        onPressed: isEnabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.blueGrey[50] : Colors.grey[400],
          foregroundColor: isEnabled ? Colors.blueGrey[800] : Colors.white,
          padding: EdgeInsets.zero, // Bỏ padding để vừa vặn
          minimumSize: const Size(40, 40), // Kích thước tối thiểu cho mỗi phím
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}