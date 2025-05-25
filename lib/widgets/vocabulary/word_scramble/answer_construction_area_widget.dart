import 'package:flutter/material.dart';
import '../answer_letter_box_widget.dart';
import '../../../screens/vocabulary/word_scramble_screen.dart'; // Để dùng ScrambledLetter

class AnswerConstructionAreaWidget extends StatelessWidget {
  final List<ScrambledLetter?> userInputLetters;
  final int targetWordLength;
  final Function(int) onUserInputLetterTap;
  final VoidCallback onClearLastLetter;

  const AnswerConstructionAreaWidget({
    super.key,
    required this.userInputLetters,
    required this.targetWordLength,
    required this.onUserInputLetterTap,
    required this.onClearLastLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text("Sắp xếp thành từ:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2.0,
            runSpacing: 2.0,
            children: List.generate(targetWordLength, (index) {
              return InkWell(
                onTap: () => onUserInputLetterTap(index),
                child: AnswerLetterBoxWidget(
                  letter: userInputLetters.length > index ? userInputLetters[index]?.letter : null,
                ),
              );
            }),
          ),
          SizedBox(height: 10),
          TextButton.icon(
            icon: Icon(Icons.backspace_outlined, size: 18, color: Colors.redAccent),
            label: Text("Xóa", style: TextStyle(color: Colors.redAccent)),
            onPressed: onClearLastLetter,
          ),
        ],
      ),
    );
  }
}