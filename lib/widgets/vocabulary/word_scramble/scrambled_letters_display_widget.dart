import 'package:flutter/material.dart';
import '../scrambled_letter_tile_widget.dart';
import '../../../screens/vocabulary/word_scramble_screen.dart'; // Để dùng ScrambledLetter


class ScrambledLettersDisplayWidget extends StatelessWidget {
  final List<ScrambledLetter> displayedScrambledLetters;
  final Function(ScrambledLetter) onScrambledLetterTap;

  const ScrambledLettersDisplayWidget({
    super.key,
    required this.displayedScrambledLetters,
    required this.onScrambledLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Chọn các chữ cái:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4.0,
          runSpacing: 4.0,
          children: displayedScrambledLetters.map((sLetter) {
            return ScrambledLetterTileWidget(
              letter: sLetter.letter,
              isUsed: sLetter.isUsed,
              onTap: () => onScrambledLetterTap(sLetter),
            );
          }).toList(),
        ),
      ],
    );
  }
}