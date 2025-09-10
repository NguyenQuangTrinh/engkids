// lib/widgets/vocabulary/word_guess/hidden_letter_widget.dart

import 'package:flutter/material.dart';

class HiddenLetterWidget extends StatelessWidget {
  final String letter;
  final bool isVisible;

  const HiddenLetterWidget({
    super.key,
    required this.letter,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isVisible ? Colors.transparent : Colors.black87,
            width: 3.0,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        isVisible ? letter.toUpperCase() : '',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}