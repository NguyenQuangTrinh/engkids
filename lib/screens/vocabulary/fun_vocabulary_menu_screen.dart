// lib/screens/vocabulary/fun_vocabulary_menu_screen.dart

import 'package:engkids/models/flashcard_item_model.dart';
import 'package:engkids/providers/game_selection_provider.dart';
import 'package:engkids/providers/vocabulary_providers.dart';
import 'package:engkids/screens/game/listen_type_game_screen.dart';
import 'package:engkids/screens/vocabulary/flashcard_screen.dart';
import 'package:engkids/screens/vocabulary/game_set_selection_screen.dart';
import 'package:engkids/screens/vocabulary/matching_game_screen.dart';
import 'package:engkids/screens/vocabulary/vocabulary_set_management_screen.dart';
import 'package:engkids/screens/vocabulary/word_guess_screen.dart';
import 'package:engkids/screens/vocabulary/word_scramble_screen.dart';
import 'package:engkids/service/firebase_vocabulary_service.dart';
import 'package:engkids/widgets/vocabulary/vocabulary_game_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Class helper để định nghĩa các mục trong menu
class GameMenuItem {
  final String title;
  final String description;
  final IconData iconData;
  final Color cardColor;
  final String featureKey;

  GameMenuItem({
    required this.title,
    required this.description,
    required this.iconData,
    required this.cardColor,
    required this.featureKey,
  });
}

class FunVocabularyMenuScreen extends ConsumerWidget {
  const FunVocabularyMenuScreen({super.key});

  // Hàm build danh sách các game, tách ra cho gọn
  List<GameMenuItem> _buildGameMenuItems() {
    return [
      GameMenuItem(
        title: "Quản lý Bộ Từ Vựng",
        description: "Tạo, nhập, và quản lý các bộ từ của bạn và bạn bè.",
        iconData: Icons.library_add_check_rounded,
        cardColor: Colors.blueGrey[500]!,
        featureKey: "manage_sets",
      ),
      GameMenuItem(
        title: "Thẻ Ghi Nhớ",
        description: "Ôn tập từ vựng với các thẻ lật thông minh.",
        iconData: Icons.style_rounded,
        cardColor: Colors.teal[400]!,
        featureKey: "flashcards",
      ),
      GameMenuItem(
        title: "Nối Từ Siêu Tốc",
        description: "Nối từ tiếng Anh với nghĩa tương ứng.",
        iconData: Icons.compare_arrows_rounded,
        cardColor: Colors.deepOrange[400]!,
        featureKey: "matching_game",
      ),
      GameMenuItem(
        title: "Giải Đố Chữ",
        description: "Sắp xếp các chữ cái thành từ đúng.",
        iconData: Icons.shuffle_rounded,
        cardColor: Colors.lightBlue[400]!,
        featureKey: "word_scramble",
      ),
      GameMenuItem(
        title: "Đoán Từ Bí Ẩn",
        description: "Thử thách trí tuệ với trò chơi đoán từ.",
        iconData: Icons.visibility_off_rounded,
        cardColor: Colors.purple[400]!,
        featureKey: "word_guess",
      ),
      GameMenuItem(
        title: "Nghe và Gõ",
        description: "Luyện kỹ năng nghe và viết chính tả.",
        iconData: Icons.hearing_rounded,
        cardColor: Colors.cyan[600]!,
        featureKey: "listen_and_type",
      ),
    ];
  }

  // Hàm xử lý khi nhấn vào một mục game
  Future<void> _handleMenuItemTap(
    BuildContext context,
    WidgetRef ref,
    String featureKey,
  ) async {
    // Xử lý riêng cho mục "Quản lý"
    if (featureKey == 'manage_sets') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VocabularySetManagementScreen(),
        ),
      );
      return;
    }

    // Hiển thị loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<FlashcardItem> gameItems;
      String gameTitle;

      // Lấy danh sách bộ từ đã chọn từ provider
      final selectedSets = ref.read(gameSelectionProvider).asData?.value ?? {};

      if (selectedSets.isNotEmpty) {
        // Nếu có chọn, lấy từ vựng từ các bộ đó
        gameItems = await ref.read(
          combinedVocabularyProvider(selectedSets).future,
        );
        gameTitle = "Từ vựng Tùy chọn";
      } else {
        // Nếu không chọn bộ nào, lấy từ ngẫu nhiên
        gameItems = await FirebaseVocabularyService.instance
            .getRandomVocabularyItems(limit: 15);
        gameTitle = "Ôn tập Ngẫu nhiên";
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Ẩn loading overlay

      // Kiểm tra xem có từ vựng để chơi không
      if (gameItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Không có từ vựng nào để chơi. Hãy chọn bộ từ hoặc thêm từ mới!",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Điều hướng đến game tương ứng
      Widget? gameScreen;
      switch (featureKey) {
        case 'flashcards':
          gameScreen = FlashcardScreen(
            flashcards: gameItems,
            setName: gameTitle,
          );
          break;
        case 'matching_game':
          if (gameItems.length < 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cần ít nhất 6 từ để chơi Nối Từ.")),
            );
            return;
          }
          gameScreen = MatchingGameScreen(
            vocabularyItems: gameItems,
            setName: gameTitle,
          );
          break;
        case 'word_scramble':
          gameScreen = WordScrambleScreen(
            vocabularyItems: gameItems,
            setName: gameTitle,
          );
          break;
        case 'word_guess':
          gameScreen = WordGuessScreen(
            vocabularyItems: gameItems,
            setName: gameTitle,
          );
        case 'listen_and_type':
          gameScreen = ListenTypeGameScreen(
            vocabularyItems: gameItems,
            setName: gameTitle,
          );
          break;
      }

      if (gameScreen != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => gameScreen!),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Ẩn loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi chuẩn bị game: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe lựa chọn đã lưu để hiển thị
    final gameSelection = ref.watch(gameSelectionProvider);
    final gameItems = _buildGameMenuItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Từ Vựng Vui"),
        backgroundColor: Colors.indigoAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[50]!, Colors.lightBlue[50]!],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Card chọn bộ từ vựng
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20.0),
              child: ListTile(
                leading: Icon(
                  Icons.collections_bookmark_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text(
                  "Chọn Bộ Từ Vựng Chơi Game",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: gameSelection.when(
                  data: (sets) {
                    if (sets.isEmpty)
                      return const Text("Chế độ: Ngẫu nhiên tất cả từ vựng");
                    return Text(
                      "Đã chọn: ${sets.map((s) => s.name).join(', ')}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    );
                  },
                  loading: () => const Text("Đang tải lựa chọn..."),
                  error:
                      (e, s) => const Text(
                        "Lỗi tải lựa chọn",
                        style: TextStyle(color: Colors.red),
                      ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameSetSelectionScreen(),
                    ),
                  );
                },
              ),
            ),

            // Danh sách các trò chơi
            ...gameItems.map((item) {
              return VocabularyGameCard(
                title: item.title,
                description: item.description,
                iconData: item.iconData,
                cardColor: item.cardColor,
                onTap: () => _handleMenuItemTap(context, ref, item.featureKey),
              );
            }),
          ],
        ),
      ),
    );
  }
}
