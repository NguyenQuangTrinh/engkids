import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/saved_quiz_model.dart';
import '../service/quiz_database_service.dart';
import '../widgets/library/library_list_item.dart'; // Import widget item
import 'loading_screen.dart';
import 'question_screen.dart'; // Import màn hình câu hỏi

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<SavedQuizModel> _savedQuizzes = [];
  bool _isLoading = true;
  String? _error;
  final QuizDatabaseService _quizDbService = QuizDatabaseService.instance;
  static const String _logName = 'com.engkids.libraryscreen';

  @override
  void initState() {
    super.initState();
    _loadSavedQuizzes();
  }

  Future<void> _loadSavedQuizzes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quizzes = await _quizDbService.getAllQuizzes();
      if (mounted) {
        setState(() {
          _savedQuizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      developer.log("Lỗi khi tải danh sách bài tập đã lưu", name: _logName, error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = "Không thể tải danh sách bài tập. Vui lòng thử lại.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _practiceQuiz(SavedQuizModel quiz) async {
    developer.log("Chuẩn bị làm bài: ${quiz.name}", name: _logName);
    if (mounted) {
      // Chuyển List<Map<String, dynamic>> từ model sang QuestionScreen
      // Model đã lưu questions dưới dạng List<Map<String, dynamic>> nên có thể dùng trực tiếp
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(questions: quiz.questions),
        ),
      ).then((_) {
        // Tùy chọn: Tải lại danh sách sau khi làm bài xong để cập nhật thông tin (ví dụ: điểm số, ngày làm gần nhất - nếu có)
        // _loadSavedQuizzes();
      });
    }
  }

  Future<void> _deleteQuiz(int quizId, String quizName) async {
    // Hiển thị dialog xác nhận trước khi xóa
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa bài tập '$quizName' không?"),
          actions: <Widget>[
            TextButton(
              child: Text("Hủy"),
              onPressed: () {
                Navigator.of(context).pop(false); // Trả về false
              },
            ),
            TextButton(
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Trả về true
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) { // Chỉ xóa nếu người dùng xác nhận
      try {
        await _quizDbService.deleteQuiz(quizId);
        developer.log("Đã xóa bài tập ID: $quizId", name: _logName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xóa bài tập '$quizName'"), backgroundColor: Colors.green),
        );
        _loadSavedQuizzes(); // Tải lại danh sách sau khi xóa
      } catch (e, s) {
        developer.log("Lỗi khi xóa bài tập ID: $quizId", name: _logName, error: e, stackTrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi xóa bài tập. Vui lòng thử lại."), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndProcessNewPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final String filePath = result.files.first.path!;
        developer.log("Đã chọn file PDF mới từ LibraryScreen: $filePath", name: _logName);

        if (!mounted) return;
        // Điều hướng sang LoadingScreen và chờ kết quả
        final List<Map<String, dynamic>>? questionsFromLoading =
        await Navigator.push<List<Map<String, dynamic>>?>(
          context,
          MaterialPageRoute<List<Map<String, dynamic>>?>( // <-- Chỉ định kiểu kết quả cho Route
            builder: (context) => LoadingScreen(filePath: filePath),
          ),
        );

        if (mounted) { // Kiểm tra mounted sau await
          if (questionsFromLoading != null) { // Có nghĩa là LoadingScreen đã chạy xong luồng chính (parse và save)
            developer.log("LibraryScreen: File đã được xử lý bởi LoadingScreen. Tải lại danh sách thư viện.", name: _logName);
            await _loadSavedQuizzes(); // Tải lại danh sách để hiển thị mục mới (nếu có)
            // KHÔNG điều hướng sang QuestionScreen từ đây nữa.
          } else {
            // questionsFromLoading là null, có thể do lỗi trong LoadingScreen hoặc không parse được gì cả.
            // LoadingScreen nên đã hiển thị SnackBar lỗi.
            // Vẫn có thể cân nhắc tải lại danh sách để đảm bảo UI nhất quán.
            developer.log("LibraryScreen: LoadingScreen trả về null (có thể do lỗi hoặc không có câu hỏi). Tải lại thư viện.", name: _logName);
            await _loadSavedQuizzes();
          }
        }
      } else {
        developer.log("Người dùng hủy chọn file từ LibraryScreen.", name: _logName);
      }
    } catch (e, s) {
      developer.log("Lỗi khi chọn file từ LibraryScreen: $e", name: _logName, error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn file: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBody() {
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
              ElevatedButton.icon(
                onPressed: _loadSavedQuizzes,
                icon: Icon(Icons.refresh),
                label: Text("Thử lại"),
              )
            ],
          ),
        ),
      );
    }
    if (_savedQuizzes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[400]),
              SizedBox(height: 20),
              Text(
                "Thư viện của bạn còn trống!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Hãy mở một file PDF bài tập để EngKids tự động lưu vào đây nhé.",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị danh sách bài tập
    return RefreshIndicator( // Thêm RefreshIndicator để kéo làm mới
      onRefresh: _loadSavedQuizzes,
      child: ListView.builder(
        itemCount: _savedQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = _savedQuizzes[index];
          return LibraryListItem(
            quiz: quiz,
            onPractice: () => _practiceQuiz(quiz),
            onDelete: () {
              if (quiz.id != null) {
                _deleteQuiz(quiz.id!, quiz.name);
              } else {
                developer.log("Không thể xóa: quiz.id là null", name: _logName, error: "Quiz ID is null");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Không thể xóa bài tập này do thiếu ID."), backgroundColor: Colors.orange),
                );
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thư Viện Bài Tập"),
        backgroundColor: Colors.green[700], // Màu sắc riêng cho LibraryScreen
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadSavedQuizzes,
            tooltip: "Tải lại danh sách",
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndProcessNewPdfFile,
        tooltip: 'Thêm bài tập mới từ PDF',
        icon: Icon(Icons.add_rounded),
        label: Text("Thêm PDF"),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}