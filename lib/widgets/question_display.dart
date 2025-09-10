// lib/widgets/question_display.dart

import 'package:flutter/material.dart';

class QuestionDisplay extends StatelessWidget {
  final String questionText;

  // Constructor nhận text câu hỏi
  const QuestionDisplay({super.key, required this.questionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Text(
        questionText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.brown[800],
          fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily, // Lấy font từ theme
        ),
      ),
    );
  }
}