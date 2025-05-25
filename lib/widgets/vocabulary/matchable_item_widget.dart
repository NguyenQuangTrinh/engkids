// lib/widgets/vocabulary/matchable_item_widget.dart
import 'package:flutter/material.dart';

// MatchItemState enum giữ nguyên
enum MatchItemState { normal, selected, matchedCorrectly, matchedIncorrectly }

class MatchableItemWidget extends StatelessWidget {
  final String text;
  final MatchItemState uiState; // Đổi tên từ state để tránh trùng với State của StatefulWidget
  final VoidCallback onTap;
  // final bool isTermColumn; // Không cần nữa vì không còn cột

  const MatchableItemWidget({
    super.key,
    required this.text,
    required this.uiState,
    required this.onTap,
    // this.isTermColumn = true, // Bỏ đi
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    double elevation = 3.0; // Tăng elevation một chút cho nổi bật
    BorderSide borderSide = BorderSide.none;

    switch (uiState) {
      case MatchItemState.selected:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        elevation = 6.0;
        borderSide = BorderSide(color: Colors.blue[700]!, width: 2.5);
        break;
      case MatchItemState.matchedCorrectly:
        backgroundColor = Colors.green[50]!.withValues(alpha: 0.7); // Nền mờ hơn
        textColor = Colors.green[700]!;
        elevation = 1.0;
        // Không gạch ngang chữ nữa để vẫn đọc được
        break;
      case MatchItemState.matchedIncorrectly:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        elevation = 6.0;
        borderSide = BorderSide(color: Colors.red[700]!, width: 2.5);
        break;
      case MatchItemState.normal:
      backgroundColor = Colors.white;
        textColor = Colors.black87;
        borderSide = BorderSide(color: Colors.grey.shade300, width: 1.0); // Thêm viền nhẹ
        break;
    }

    final VoidCallback? effectiveOnTap = (uiState == MatchItemState.matchedCorrectly) ? null : onTap;

    return Opacity(
      opacity: uiState == MatchItemState.matchedCorrectly ? 0.6 : 1.0, // Mờ đi chút khi đã match
      child: Card(
        elevation: elevation,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Bo tròn nhiều hơn
          side: borderSide,
        ),
        // Card sẽ tự co kích thước theo con của nó (InkWell -> Container -> Padding -> Text)
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding( // Padding để chữ không sát viền Card
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, // Cỡ chữ đồng nhất hơn
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}