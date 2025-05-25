import 'package:flutter/material.dart';

class HintDisplayWidget extends StatelessWidget {
  final bool hintVisible;
  final String? hintText;
  final VoidCallback onShowHint;

  const HintDisplayWidget({
    super.key,
    required this.hintVisible,
    this.hintText,
    required this.onShowHint,
  });

  @override
  Widget build(BuildContext context) {
    if (!hintVisible) {
      return ElevatedButton.icon(
        icon: Icon(Icons.lightbulb_outline_rounded, size: 18),
        label: Text("Xem Gợi Ý"),
        onPressed: onShowHint,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[300],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      );
    } else if (hintText != null && hintText!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(bottom: 10.0, top: 5.0),
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey[300]!)),
        child: Text(
          "Gợi ý: $hintText",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              color: Colors.black87),
        ),
      );
    }
    return SizedBox.shrink(); // Không hiển thị gì nếu hint đã visible nhưng text rỗng
  }
}