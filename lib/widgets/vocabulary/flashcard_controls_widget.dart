// lib/widgets/vocabulary/flashcard_controls_widget.dart

import 'package:flutter/material.dart';

class FlashcardControlsWidget extends StatelessWidget {
  final int currentIndex;
  final int totalCards;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  // final VoidCallback onFlip; // <<< BỎ ĐI

  const FlashcardControlsWidget({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    required this.onPrevious,
    required this.onNext,
    // required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        children: [
          Text(
            "Thẻ ${currentIndex + 1} / $totalCards",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey[700]),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Chỉ còn 2 nút
            children: [
              ElevatedButton.icon(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                label: Text("Trước"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
              ElevatedButton.icon(
                onPressed: currentIndex < totalCards - 1 ? onNext : null,
                label: Text("Sau"),
                icon: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}