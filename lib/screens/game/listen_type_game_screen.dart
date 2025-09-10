// lib/screens/game/listen_type_game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/flashcard_item_model.dart';
import '../../providers/listen_type_provider.dart';

class ListenTypeGameScreen extends ConsumerStatefulWidget {
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const ListenTypeGameScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  ConsumerState<ListenTypeGameScreen> createState() => _ListenTypeGameScreenState();
}

class _ListenTypeGameScreenState extends ConsumerState<ListenTypeGameScreen> {
  late FlutterTts _flutterTts;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _setupTts();
    
    // Tự động đọc từ đầu tiên khi vào game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstWord = ref.read(listenTypeProvider(widget.vocabularyItems)).currentWord?.term;
      if (firstWord != null) {
        _speak(firstWord);
      }
      _focusNode.requestFocus();
    });
  }

  void _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _submitAnswer() {
    final gameNotifier = ref.read(listenTypeProvider(widget.vocabularyItems).notifier);
    gameNotifier.checkAnswer(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(listenTypeProvider(widget.vocabularyItems));
    final gameNotifier = ref.read(listenTypeProvider(widget.vocabularyItems).notifier);
    final currentWord = gameState.currentWord;

    // Tự động đọc từ mới khi chuyển câu
    ref.listen(listenTypeProvider(widget.vocabularyItems), (previous, next) {
      if (previous?.currentWord?.id != next.currentWord?.id && next.currentWord != null) {
        _speak(next.currentWord!.term);
        _textController.clear();
        _focusNode.requestFocus();
      }
    });

    if (currentWord == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Không có từ nào để chơi.")));
    }
    
    if (gameState.status == ListenTypeStatus.ended) {
        return Scaffold(
            appBar: AppBar(title: Text(widget.setName)),
            body: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Text("Hoàn thành!", style: TextStyle(fontSize: 32)),
                    ElevatedButton(onPressed: gameNotifier.startNewGame, child: const Text("Chơi lại")),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Về Menu")),
                ],
            )),
        );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.setName)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Gợi ý
            Text("GỢI Ý: ${currentWord.definition}", style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            
            // Nút nghe lại
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 50, color: Colors.blueAccent),
              onPressed: () => _speak(currentWord.term),
            ),
            const SizedBox(height: 20),
            
            // Ô nhập liệu
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: "Gõ những gì bạn nghe được"),
              onSubmitted: (_) => _submitAnswer(),
            ),
            const SizedBox(height: 20),
            
            // Phản hồi sau khi trả lời
            if(gameState.status == ListenTypeStatus.showingResult)
              gameState.wasCorrect == true
                ? const Text("Chính xác!", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold))
                : Text("Sai rồi! Đáp án đúng là: ${currentWord.term}", style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            
            const Spacer(),
            
            // Nút kiểm tra / Tiếp theo
            ElevatedButton(
              onPressed: gameState.status == ListenTypeStatus.playing ? _submitAnswer : gameNotifier.nextWord,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: gameState.status == ListenTypeStatus.showingResult ? Colors.orangeAccent : Colors.green,
              ),
              child: Text(gameState.status == ListenTypeStatus.playing ? "Kiểm tra" : "Tiếp theo"),
            ),
          ],
        ),
      ),
    );
  }
}