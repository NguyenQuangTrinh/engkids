// lib/widgets/vocabulary/flashcard_view_widget.dart
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'dart:math' as math; // Cho giá trị PI
import '../../models/flashcard_item_model.dart';

class FlashcardViewWidget extends StatefulWidget {
  final FlashcardItem cardItem;

  const FlashcardViewWidget({
    super.key,
    required this.cardItem,
  });

  @override
  FlashcardViewWidgetState createState() => FlashcardViewWidgetState();
}

class FlashcardViewWidgetState extends State<FlashcardViewWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isFrontVisible = true; // Trạng thái logic: mặt trước đang hiển thị hay không

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Thời gian lật thẻ
      vsync: this,
    );

    // Animation từ 0.0 (mặt trước) đến 1.0 (mặt sau hoàn toàn)
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        // setState(() {}); // Không cần thiết nếu dùng AnimatedBuilder
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_controller.isAnimating) return; // Không làm gì nếu đang lật

    if (_isFrontVisible) {
      developer.log("sss");
      _controller.forward(); // Lật từ trước ra sau
    } else {
      developer.log("aaa");
      _controller.reverse(); // Lật từ sau về trước
    }
    // Cập nhật trạng thái logic sau khi animation bắt đầu hoặc kết thúc
    // Để đảm bảo nội dung đúng được hiển thị trong quá trình lật
    setState(() { // Cập nhật ở đây sẽ hơi sớm, nên cập nhật khi animation qua nửa chừng
      _isFrontVisible = !_isFrontVisible;
    });
    // Thay vào đó, logic hiển thị mặt nào sẽ dựa trên giá trị animation
  }

  Widget _buildFace(BuildContext context, String mainText, String? subText, bool isTermFace) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            mainText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTermFace ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
            ),
          ),
          if (subText != null && subText.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: isTermFace ? FontStyle.italic : FontStyle.normal,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.black54,
              ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (BuildContext context, Widget? child) {
            // Góc lật, từ 0 đến PI (180 độ)
            final angle = _animation.value * math.pi;

            // Xác định widget mặt trước và mặt sau
            Widget frontFace = _buildFace(context, widget.cardItem.term, widget.cardItem.phonetic, true);
            Widget backFace = _buildFace(context, widget.cardItem.definition, widget.cardItem.exampleSentence, false);


            bool showFrontFaceContent = _animation.value < 0.5;

            Widget content;
            if (showFrontFaceContent) {
              content = frontFace;
            } else {
              // Mặt sau cần được xoay ngược lại để chữ không bị ngược
              content = Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi), // Xoay nội dung mặt sau 180 độ
                child: backFace,
              );
            }

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Thêm hiệu ứng perspective
                ..rotateY(angle),       // Xoay cả thẻ
              child: Card(
                elevation: 6.0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: Container( // Container để đảm bảo Card có kích thước và padding
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}