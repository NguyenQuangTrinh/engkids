// lib/widgets/vocabulary/word_scramble/answer_construction_area_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../answer_letter_box_widget.dart';
import '../../../providers/word_scramble_provider.dart';

class AnswerConstructionAreaWidget extends StatelessWidget {
  // Thêm lại answerWasCorrect
  final bool answerWasCorrect;

  final List<ScrambledLetter?> userInputLetters;
  final int targetWordLength;
  final Function(int) onUserInputLetterTap;
  final VoidCallback onClearLastLetter;
  final bool isHintModeActive;
  final Set<int> hintedIndices;

  const AnswerConstructionAreaWidget({
    super.key, // Key sẽ được truyền vào đây từ widget cha
    required this.answerWasCorrect,
    required this.userInputLetters,
    required this.targetWordLength,
    required this.onUserInputLetterTap,
    required this.onClearLastLetter,
    required this.isHintModeActive,
    required this.hintedIndices,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
            "Sắp xếp thành từ:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          MouseRegion(
            cursor: isHintModeActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2.0,
              runSpacing: 2.0,
              children: List.generate(targetWordLength, (index) {
                    return InkWell(
                      onTap: () => onUserInputLetterTap(index),
                      child: AnswerLetterBoxWidget(
                        letter:
                            userInputLetters.length > index
                                ? userInputLetters[index]?.letter
                                : null,
                        isHint: hintedIndices.contains(index),
                      ),
                    );
                  })
                  .animate(
                    // autoPlay mặc định là true, nó sẽ chạy mỗi khi widget này được build lại với Key mới
                    interval: 100.ms,
                  )
                  .shake(
                    hz: answerWasCorrect ? 4 : 8,
                    duration: answerWasCorrect ? 400.ms : 500.ms,
                    offset:
                        answerWasCorrect
                            ? const Offset(1.5, 0)
                            : const Offset(4.0, 0),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(
              Icons.backspace_outlined,
              size: 18,
              color: Colors.redAccent,
            ),
            label: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
            onPressed: onClearLastLetter,
          ),
        ],
      ),
    );
  }
}
