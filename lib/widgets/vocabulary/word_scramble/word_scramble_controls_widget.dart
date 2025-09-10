// lib/widgets/vocabulary/word_scramble/word_scramble_controls_widget.dart

import 'package:flutter/material.dart';

class WordScrambleControlsWidget extends StatelessWidget {
  final String feedbackMessage;
  final VoidCallback onSkipWord;
  final bool canUseHint; // Kiểm tra xem có thể dùng gợi ý không
  final bool isHintModeActive; // Đang ở chế độ chọn ô để gợi ý
  final VoidCallback onUseHint; // Callback khi nhấn nút "Dùng Gợi ý"

  const WordScrambleControlsWidget({
    super.key,
    required this.feedbackMessage,
    required this.onSkipWord,
    required this.canUseHint,
    required this.isHintModeActive,
    required this.onUseHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // if (feedbackMessage.isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 10.0),
        //     child: Text(
        //       feedbackMessage,
        //       style: TextStyle(
        //         color: isHintModeActive
        //             ? Colors.blue[700] // Màu cho thông báo chế độ gợi ý
        //             : (feedbackMessage.toLowerCase().contains("chính xác")
        //             ? Colors.green[700]
        //             : Colors.red[700]),
        //         fontWeight: FontWeight.w500,
        //         fontSize: 16,
        //       ),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),
        SizedBox(height: 10),
        Row( // Đặt các nút điều khiển chính trên một hàng
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Nút Gợi ý
            TextButton.icon(
              icon: Icon(Icons.lightbulb_outline_rounded, color: canUseHint ? Colors.orangeAccent[700] : Colors.grey),
              label: Text("Gợi ý", style: TextStyle(color: canUseHint ? Colors.orangeAccent[700] : Colors.grey)),
              onPressed: canUseHint ? onUseHint : null,
            ),
            // Nút Bỏ qua (có thể làm nó nổi bật hơn nếu nút Check bị bỏ)
            ElevatedButton.icon( // Chuyển thành ElevatedButton cho nổi bật hơn
              icon: Icon(Icons.skip_next_rounded),
              label: Text("Bỏ qua"),
              onPressed: isHintModeActive ? null : onSkipWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[300],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

      ],
    );
  }
}