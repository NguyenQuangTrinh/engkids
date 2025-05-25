import 'package:engkids/screens/vocabulary/vocabulary_set_management_screen.dart';
import 'package:engkids/screens/vocabulary/word_scramble_screen.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer; // Cho logging
import '../../models/flashcard_item_model.dart';
import '../../service/vocabulary_database_service.dart';
import '../../widgets/vocabulary/vocabulary_game_card.dart';
import 'flashcard_screen.dart';
import 'matching_game_screen.dart'; // Import widget thẻ game

// Định nghĩa kiểu dữ liệu cho mỗi mục game để dễ quản lý
class GameMenuItem {
  final String title;
  final String description;
  final IconData iconData;
  final Color cardColor;
  final String
  featureKey; // Key để nhận diện game, dùng cho navigation hoặc coming soon

  GameMenuItem({
    required this.title,
    required this.description,
    required this.iconData,
    required this.cardColor,
    required this.featureKey,
  });
}

class FunVocabularyMenuScreen extends StatefulWidget {
  const FunVocabularyMenuScreen({super.key});

  @override
  FunVocabularyMenuScreenState createState() => FunVocabularyMenuScreenState();
}

class FunVocabularyMenuScreenState extends State<FunVocabularyMenuScreen> {
  static const String _logName = 'com.engkids.funvocabularymenu';
  bool _isLoadingRandomFlashcards = false;
  final VocabularyDatabaseService _vocabDbService =
      VocabularyDatabaseService.instance;

  // Danh sách các trò chơi (sẽ được mở rộng)
  late final List<GameMenuItem> _gameItems;

  @override
  void initState() {
    super.initState();
    _gameItems = _buildGameMenuItems();
  }

  Future<void> _handleMenuItemTap(String featureKey) async {
    developer.log("Menu item tapped: $featureKey", name: _logName);

    if (featureKey == 'manage_sets') {
      // <<< XỬ LÝ CHO MỤC MỚI
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VocabularySetManagementScreen(),
        ),
      );
    } else if (featureKey == 'flashcards') {
      if (_isLoadingRandomFlashcards) return; // Tránh nhấn nhiều lần

      setState(() {
        _isLoadingRandomFlashcards = true;
      });

      List<FlashcardItem> randomItems = await _vocabDbService
          .getRandomVocabularyItems(limit: 15);

      if (!mounted) return; // Kiểm tra sau await
      setState(() {
        _isLoadingRandomFlashcards = false;
      });

      if (randomItems.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FlashcardScreen(
                  flashcards: randomItems,
                  setName: "Ôn tập Ngẫu nhiên", // Tên cho bộ từ ngẫu nhiên
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Chưa có từ vựng nào trong thư viện để ôn tập ngẫu nhiên. Hãy thêm bộ từ trước!",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (featureKey == 'matching_game') {
      if (_isLoadingRandomFlashcards)
        return; // Đổi tên biến loading cho phù hợp nếu dùng chung
      setState(() {
        _isLoadingRandomFlashcards = true;
      });

      List<FlashcardItem> gameItems = await _vocabDbService
          .getRandomVocabularyItems(limit: 10);

      if (!mounted) return;
      setState(() {
        _isLoadingRandomFlashcards = false;
      });

      if (gameItems.length >= 2) {
        // Cần ít nhất 2 item để chơi matching
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MatchingGameScreen(
                  vocabularyItems: gameItems,
                  setName: "Nối Từ Ngẫu Nhiên",
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Không đủ từ vựng để chơi trò nối từ (cần ít nhất 2 từ).",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if(featureKey == 'word_scramble'){
      if (_isLoadingRandomFlashcards) return;
      setState(() { _isLoadingRandomFlashcards = true; });

      // Lấy từ ngẫu nhiên, ví dụ 5 từ cho word scramble
      List<FlashcardItem> gameItems = await _vocabDbService.getRandomVocabularyItems(limit: 5);

      if (!mounted) return;
      setState(() { _isLoadingRandomFlashcards = false; });

      if (gameItems.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordScrambleScreen(
              vocabularyItems: gameItems,
              setName: "Đố Chữ Ngẫu Nhiên",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không đủ từ vựng để chơi Đố Chữ."), backgroundColor: Colors.orange),
        );
      }
    } else {
      _showComingSoon(context, "Chức năng '$featureKey'");
    }
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName sắp ra mắt!'),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Hàm tạo danh sách các mục game
  List<GameMenuItem> _buildGameMenuItems() {
    return [
      GameMenuItem(
        // <<< MỤC MỚI HOẶC THAY THẾ MỤC "CHỌN BỘ TỪ" CŨ
        title: "Quản lý Bộ Từ Vựng",
        description: "Tạo, nhập từ file JSON, và quản lý các bộ từ của bạn.",
        iconData: Icons.library_add_check_rounded,
        cardColor: Colors.blueGrey[500]!,
        featureKey: "manage_sets", // Một key mới
      ),
      GameMenuItem(
        title: "Thẻ Ghi Nhớ Thông Minh",
        description: "Ôn tập từ vựng với thẻ lật và lặp lại ngắt quãng.",
        iconData: Icons.style_rounded, // Icon cho flashcards
        cardColor: Colors.teal[400]!,
        featureKey: "flashcards",
      ),
      GameMenuItem(
        title: "Nối Từ Siêu Tốc",
        description: "Nối từ tiếng Anh với nghĩa hoặc hình ảnh tương ứng.",
        iconData: Icons.compare_arrows_rounded, // Icon cho matching
        cardColor: Colors.deepOrange[400]!,
        featureKey: "matching_game",
      ),
      GameMenuItem(
        title: "Giải Đố Chữ",
        description: "Sắp xếp các chữ cái lộn xộn thành từ đúng.",
        iconData: Icons.shuffle_rounded, // Icon cho word scramble
        cardColor: Colors.lightBlue[400]!,
        featureKey: "word_scramble",
      ),
      GameMenuItem(
        title: "Đoán Từ Bí Ẩn",
        description: "Thử thách trí tuệ với trò chơi đoán từ cổ điển.",
        iconData: Icons.visibility_off_rounded, // Icon cho word guess
        cardColor: Colors.purple[400]!,
        featureKey: "word_guess",
      ),
      GameMenuItem(
        title: "Trắc Nghiệm Từ Vựng",
        description:
            "Kiểm tra kiến thức từ vựng qua các câu hỏi nhiều lựa chọn.",
        iconData: Icons.quiz_rounded, // Icon cho MCQ
        cardColor: Colors.green[500]!,
        featureKey: "vocabulary_quiz",
      ),
      // Thêm các game khác ở đây
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Từ Vựng Vui"),
        backgroundColor: Colors.indigoAccent, // Màu riêng cho khu vực này
      ),
      body: Container(
        decoration: BoxDecoration(
          // Thêm nền gradient nhẹ
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[50]!, Colors.lightBlue[50]!],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // TODO: Placeholder cho phần chọn bộ từ vựng (sẽ làm sau)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20.0),
              child: ListTile(
                leading: Icon(
                  Icons.collections_bookmark_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  "Chọn Bộ Từ Vựng",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text("Mặc định: Tất cả từ / Từ bài học gần nhất"),
                trailing: Icon(Icons.arrow_drop_down_rounded),
                onTap: () => _showComingSoon(context, "Chọn bộ từ vựng"),
              ),
            ),

            // Danh sách các trò chơi
            ..._gameItems.map((item) {
              return VocabularyGameCard(
                title: item.title,
                description: item.description,
                iconData: item.iconData,
                cardColor: item.cardColor,
                onTap: () => _handleMenuItemTap(item.featureKey),
              );
            }),
          ],
        ),
      ),
    );
  }
}
