// lib/widgets/vocabulary/flashcard_view_widget.dart

// import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math; // Cho giá trị PI
import '../../models/flashcard_item_model.dart';

class FlashcardViewWidget extends StatefulWidget {
  final FlashcardItem cardItem;

  const FlashcardViewWidget({super.key, required this.cardItem});

  @override
  FlashcardViewWidgetState createState() => FlashcardViewWidgetState();
}

class FlashcardViewWidgetState extends State<FlashcardViewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isFrontVisible =
      true; // Trạng thái logic: mặt trước đang hiển thị hay không

  late FlutterTts _flutterTts;
  bool _isNormalSpeed = true;

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
    _flutterTts = FlutterTts();
    _setupTts();
  }

  void _setupTts() async {
    await _flutterTts.setLanguage("en-US"); // Đặt ngôn ngữ là tiếng Anh-Mỹ
    await _flutterTts.setSpeechRate(0.5); // Đặt tốc độ đọc (0.0 - 1.0)
    await _flutterTts.setPitch(1.0); // Đặt cao độ
  }

  Future<void> _speak(String text) async {
    if (_isNormalSpeed) {
      await _flutterTts.setSpeechRate(0.5); // Tốc độ bình thường
    } else {
      await _flutterTts.setSpeechRate(0.3); // Tốc độ chậm hơn
    }

    await _flutterTts.speak(text);

    // Lật trạng thái cho lần nhấn tiếp theo và cập nhật lại UI (để đổi icon)
    setState(() {
      _isNormalSpeed = !_isNormalSpeed;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _handleTap() {
    if (_controller.isAnimating) return;
    if (_isFrontVisible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFrontVisible = !_isFrontVisible;
    });
  }

  Widget _buildFace(
    BuildContext context,
    String mainText,
    String? subText,
    String? partOfSpeech,
    bool isTermFace,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (partOfSpeech != null && partOfSpeech.isNotEmpty) ...[
            Text(
              partOfSpeech,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
          ],
          isTermFace
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      mainText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => _speak(mainText), // Gọi hàm đọc
                    tooltip: "Nghe phát âm",
                  ),
                ],
              )
              : Text(
                // Mặt sau (định nghĩa) không cần nút loa
                mainText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
          if (subText != null && subText.isNotEmpty) ...[
            const SizedBox(height: 15),
            isTermFace
                ? Text(
                  // Nếu là mặt trước, subText là phiên âm, chỉ hiển thị text
                  subText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                        Colors.black54,
                  ),
                )
                : Row(
                  // Nếu là mặt sau, subText là câu ví dụ, thêm nút loa
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      // Dùng Expanded để câu ví dụ dài có thể xuống dòng
                      child: Text(
                        "\"$subText\"", // Thêm dấu ngoặc kép cho đẹp
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                              Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: Colors.green[600],
                        size: 24,
                      ),
                      onPressed: () => _speak(subText), // Gọi hàm đọc câu ví dụ
                      tooltip: "Nghe câu ví dụ",
                    ),
                  ],
                ),
          ],
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
            Widget frontFace = _buildFace(
              context,
              widget.cardItem.term,
              widget.cardItem.phonetic,
              widget.cardItem.partOfSpeech,
              true,
            );
            Widget backFace = _buildFace(
              context,
              widget.cardItem.definition,
              widget.cardItem.exampleSentence,
              widget.cardItem.partOfSpeech,
              false,
            );

            bool showFrontFaceContent = _animation.value < 0.5;

            Widget content;
            if (showFrontFaceContent) {
              content = frontFace;
            } else {
              // Mặt sau cần được xoay ngược lại để chữ không bị ngược
              content = Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..rotateY(math.pi), // Xoay nội dung mặt sau 180 độ
                child: backFace,
              );
            }

            return Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Thêm hiệu ứng perspective
                    ..rotateY(angle), // Xoay cả thẻ
              child: Card(
                elevation: 6.0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Container(
                  // Container để đảm bảo Card có kích thước và padding
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
