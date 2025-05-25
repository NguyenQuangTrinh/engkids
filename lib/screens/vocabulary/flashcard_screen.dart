// lib/screens/vocabulary/flashcard_screen.dart
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../models/flashcard_item_model.dart';
import '../../../widgets/vocabulary/flashcard_view_widget.dart';
import '../../../widgets/vocabulary/flashcard_controls_widget.dart';

class FlashcardScreen extends StatefulWidget {
  final List<FlashcardItem> flashcards;
  final String setName; // Tên bộ từ (ví dụ: "Chủ đề Động vật")

  const FlashcardScreen({
    super.key,
    required this.flashcards,
    this.setName = "Flashcards", // Tên mặc định
  });

  @override
  FlashcardScreenState createState() => FlashcardScreenState();
}

class FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  static const String _logName = 'com.engkids.flashcardscreen';

  @override
  void initState() {
    super.initState();
    if (widget.flashcards.isEmpty) {
      developer.log("Danh sách flashcards rỗng!", name: _logName, error: "Empty flashcards list passed");
      // Có thể pop về hoặc hiển thị thông báo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không có thẻ nào để học trong bộ này."), backgroundColor: Colors.orange),
          );
        }
      });
    }
  }


  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        // Không cần reset _isFlipped nữa
      });
    } else {
      // Đã đến thẻ cuối cùng, có thể hiển thị thông báo hoặc nút hoàn thành
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn đã xem hết thẻ!"), duration: Duration(seconds: 1)),
      );
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        // Không cần reset _isFlipped nữa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      // Hiển thị khi danh sách rỗng (đã có xử lý ở initState, nhưng để chắc chắn)
      return Scaffold(
        appBar: AppBar(title: Text(widget.setName)),
        body: const Center(child: Text("Không có thẻ nào để hiển thị.")),
      );
    }

    final FlashcardItem currentCard = widget.flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setName),
        backgroundColor: Colors.deepPurpleAccent, // Màu riêng
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa thẻ và controls
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded( // Để FlashcardView chiếm không gian lớn nhất có thể
            child: Center( // Căn giữa FlashcardView
              child: FlashcardViewWidget(
                cardItem: currentCard,
              ),
            ),
          ),
          FlashcardControlsWidget(
            currentIndex: _currentIndex,
            totalCards: widget.flashcards.length,
            onPrevious: _previousCard,
            onNext: _nextCard,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10), // Đệm dưới cùng
        ],
      ),
    );
  }
}