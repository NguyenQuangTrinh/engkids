// lib/screens/vocabulary/word_guess_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/flashcard_item_model.dart';
import '../../providers/word_guess_provider.dart'; // <<< Import provider
import '../../widgets/vocabulary/word_guess/hidden_letter_widget.dart';
import '../../widgets/vocabulary/word_guess/keyboard_key_widget.dart';

class WordGuessScreen extends ConsumerWidget { // <<< Chuyển sang ConsumerWidget
  final List<FlashcardItem> vocabularyItems;
  final String setName;

  const WordGuessScreen({
    super.key,
    required this.vocabularyItems,
    required this.setName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Truyền vocabularyItems vào provider và lắng nghe state
    final gameState = ref.watch(wordGuessProvider(vocabularyItems));
    final gameNotifier = ref.read(wordGuessProvider(vocabularyItems).notifier);

    // Hiển thị dialog khi game kết thúc
    // Dùng `ref.listen` để thực hiện các hành động (như showDialog) mà không gây build lại không cần thiết
    ref.listen(wordGuessProvider(vocabularyItems), (previous, next) {
      if (next.status != GameStatus.playing) {
        _showEndGameDialog(context, next, gameNotifier);
      }
    });

    final List<String> keyboardLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');

    return Scaffold(
      appBar: AppBar(
        title: Text(setName),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text("GỢI Ý", style: TextStyle(color: Colors.grey)),
                Text(
                  gameState.hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                Text("Số lần đoán sai còn lại: ${gameState.remainingLives}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: gameState.secretWord.split('').map((letter) {
                return HiddenLetterWidget(
                  letter: letter,
                  isVisible: gameState.guessedLetters.contains(letter) || gameState.status != GameStatus.playing,
                );
              }).toList(),
            ),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2.0,
              children: keyboardLetters.map((letter) {
                return KeyboardKeyWidget(
                  letter: letter,
                  onTap: () => gameNotifier.handleKeyPress(letter),
                  isEnabled: !gameState.guessedLetters.contains(letter),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  void _showEndGameDialog(BuildContext context, WordGuessState gameState, WordGuessNotifier gameNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(gameState.status == GameStatus.win ? "🎉 Chúc mừng!" : "😢 Rất tiếc!"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(gameState.status == GameStatus.win ? "Bạn đã đoán đúng từ:" : "Bạn đã hết lượt đoán. Từ đúng là:"),
                const SizedBox(height: 10),
                Text(
                  gameState.secretWord,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Quay lại Menu'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Chơi lại'),
              onPressed: () {
                Navigator.of(context).pop();
                gameNotifier.startNewGame();
              },
            ),
          ],
        );
      },
    );
  }
}