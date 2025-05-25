import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../models/flashcard_item_model.dart';
import '../../../widgets/vocabulary/vocabulary_detail_list_item.dart';
import '../../service/vocabulary_database_service.dart';
// import 'add_edit_vocabulary_item_screen.dart'; // Màn hình thêm/sửa từ (tạo sau)

class VocabularySetDetailScreen extends StatefulWidget {
  final int setId;
  final String setName; // Nhận tên bộ từ để hiển thị trên AppBar

  const VocabularySetDetailScreen({
    super.key,
    required this.setId,
    required this.setName,
  });

  @override
  VocabularySetDetailScreenState createState() => VocabularySetDetailScreenState();
}

class VocabularySetDetailScreenState extends State<VocabularySetDetailScreen> {
  List<FlashcardItem> _words = [];
  bool _isLoading = true;
  String? _error;
  final VocabularyDatabaseService _vocabDbService = VocabularyDatabaseService.instance;
  static const String _logName = 'com.engkids.vocabsetdetail';

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _vocabDbService.getVocabularyItemsBySetId(widget.setId);
      if (mounted) {
        setState(() {
          _words = items;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      developer.log("Lỗi tải từ vựng cho bộ ID ${widget.setId}", name: _logName, error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = "Không thể tải danh sách từ vựng. Vui lòng thử lại.";
          _isLoading = false;
        });
      }
    }
  }

  // Hàm điều hướng đến màn hình thêm từ mới (sẽ làm sau)
  void _navigateToAddWord() {
    developer.log("Chuyển đến màn hình thêm từ mới cho bộ: ${widget.setName}", name: _logName);
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditVocabularyItemScreen(setId: widget.setId)))
    //   .then((value) { if (value == true) _loadWords(); }); // Tải lại nếu có từ mới được thêm
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chức năng 'Thêm từ mới' sắp ra mắt!"), duration: Duration(seconds: 1))
    );
  }


  Widget _buildWordList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _loadWords, icon: Icon(Icons.refresh), label: Text("Thử lại"))
            ],
          ),
        ),
      );
    }
    if (_words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speaker_notes_off_rounded, size: 60, color: Colors.grey[400]),
              SizedBox(height: 15),
              Text(
                "Bộ từ này chưa có từ nào.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: Text("Thêm từ mới ngay!"),
                onPressed: _navigateToAddWord,
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _words.length,
      itemBuilder: (context, index) {
        final word = _words[index];
        return VocabularyDetailListItem(word: word);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setName), // Hiển thị tên bộ từ
        backgroundColor: Colors.blueAccent, // Màu riêng
        // actions: [
        //   IconButton( // Nút thêm từ mới trên AppBar (tùy chọn)
        //     icon: Icon(Icons.add_circle_outline_rounded),
        //     onPressed: _navigateToAddWord,
        //     tooltip: "Thêm từ mới",
        //   )
        // ],
      ),
      body: _buildWordList(),
      floatingActionButton: FloatingActionButton.extended( // Hoặc chỉ FAB tròn
        onPressed: _navigateToAddWord,
        icon: Icon(Icons.add_rounded),
        label: Text("Thêm Từ"),
        tooltip: "Thêm từ mới vào bộ này",
      ),
    );
  }
}