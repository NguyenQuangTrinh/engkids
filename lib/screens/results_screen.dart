// lib/screens/results_screen.dart

import 'dart:developer' as deverlop;
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// TODO: Import màn hình HomeScreen nếu cần nút quay về trang chủ
// import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  // Nhận câu trả lời của người dùng và danh sách câu hỏi gốc
  final Map<int, String> userAnswers; // Map<QuestionIndex, SelectedOptionText>
  final List<Map<String, dynamic>> questions; // List<{'text': ..., 'options': [...]}>

  const ResultsScreen({
    super.key,
    required this.userAnswers,
    required this.questions,
  });

  @override
  ResultsScreenState createState() => ResultsScreenState();
}

class ResultsScreenState extends State<ResultsScreen> {
  bool _isLoadingAnswerKey = false; // Trạng thái đang tải file đáp án
  String? _answerKeyError; // Lưu lỗi nếu có khi đọc file đáp án
  int? _correctCount; // Số câu đúng (null nếu chưa kiểm tra)
  double? _percentage; // Tỷ lệ đúng (null nếu chưa kiểm tra)
  Map<int, String> _correctAnswers = {}; // Lưu đáp án đúng từ file txt <QuestionIndex, CorrectLetter>

  // --- Hàm xử lý chọn và phân tích file đáp án ---
  Future<void> _pickAndParseAnswerKey() async {
    setState(() {
      _isLoadingAnswerKey = true;
      _answerKeyError = null;
      _correctCount = null;
      _percentage = null;
      _correctAnswers.clear();
    });

    try {
      // 1. Chọn file .txt
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final String filePath = result.files.first.path!;
        developer.log("Đã chọn file đáp án: $filePath");

        // 2. Đọc và phân tích file .txt
        _correctAnswers = await _parseAnswerKeyFile(filePath);
        developer.log("Đáp án đúng đọc được: $_correctAnswers");

        // 3. So sánh kết quả
        _compareAnswers();

      } else {
        developer.log("Người dùng hủy chọn file đáp án.");
        // Không làm gì thêm nếu người dùng hủy
      }
    } catch (e) {
      developer.log("Lỗi khi xử lý file đáp án: $e");
      setState(() {
        _answerKeyError = "Lỗi: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoadingAnswerKey = false; // Kết thúc trạng thái loading
      });
    }
  }

  // --- Hàm đọc và phân tích nội dung file đáp án ---
  Future<Map<int, String>> _parseAnswerKeyFile(String filePath) async {
    Map<int, String> answers = {};
    final content = await File(filePath).readAsString();
    final lines = content.split('\n');

    // Regex để tìm "Câu X: Y" (X là số, Y là chữ cái), không phân biệt hoa thường ở chữ "Câu"
    final regex = RegExp(r"^\s*Câu\s*(\d+)\s*:\s*([a-zA-Z])\s*$", caseSensitive: false);

    for (String line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        try {
          // Lấy số câu (group 1) và chữ cái đáp án (group 2)
          int questionNumber = int.parse(match.group(1)!);
          String answerLetter = match.group(2)!.toLowerCase(); // Luôn chuyển về chữ thường

          // Key của map là index (số câu - 1)
          answers[questionNumber - 1] = answerLetter;
        } catch (e) {
          developer.log("Bỏ qua dòng không đúng định dạng: '$line' - Lỗi: $e");
        }
      }
    }
    if (answers.isEmpty) {
      throw Exception("Không tìm thấy đáp án nào đúng định dạng 'Câu X: Y' trong file.");
    }
    return answers;
  }

  // --- Hàm so sánh đáp án của người dùng và đáp án đúng ---
  void _compareAnswers() {
    if (_correctAnswers.isEmpty) return; // Không có đáp án đúng để so sánh

    int correct = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      final userSelectedText = widget.userAnswers[i]; // Lấy text người dùng chọn
      final correctLetter = _correctAnswers[i]; // Lấy chữ cái đúng từ file txt

      // Chỉ kiểm tra nếu có cả câu trả lời của người dùng và đáp án đúng cho câu này
      if (userSelectedText != null && correctLetter != null) {
        try {
          // Chuyển chữ cái đúng (a, b, c, d) thành index (0, 1, 2, 3)
          int correctIndex = correctLetter.codeUnitAt(0) - 'a'.codeUnitAt(0);

          // Lấy danh sách các options của câu hỏi này
          final options = List<String>.from(widget.questions[i]['options'] ?? []);

          // Lấy text của đáp án đúng từ danh sách options
          if (correctIndex >= 0 && correctIndex < options.length) {
            final correctOptionText = options[correctIndex];

            // So sánh text người dùng chọn và text đáp án đúng
            if (userSelectedText == correctOptionText) {
              correct++;
            }
          } else {
            deverlop.log("Lỗi: Index đáp án '$correctLetter' không hợp lệ cho câu ${i+1}");
          }
        } catch (e) {
          deverlop.log("Lỗi khi so sánh câu ${i+1}: $e");
        }
      } else {
        deverlop.log("Bỏ qua câu ${i+1}: Thiếu câu trả lời (${userSelectedText==null}) hoặc đáp án (${correctLetter==null})");
      }
    }

    setState(() {
      _correctCount = correct;
      // Tính phần trăm dựa trên số câu hỏi gốc hoặc số câu đã kiểm tra?
      // Tạm tính trên tổng số câu hỏi gốc
      _percentage = (widget.questions.isEmpty) ? 0.0 : (correct / widget.questions.length) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kết quả EngKids"),
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Bài làm của bạn:",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              // Hiển thị tóm tắt lựa chọn của người dùng (Tùy chọn)
              Container(
                height: 150, // Giới hạn chiều cao
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    final questionNumber = index + 1;
                    final userAnswer = widget.userAnswers[index] ?? "Chưa trả lời";
                    // Tìm chữ cái tương ứng với câu trả lời của người dùng
                    final options = List<String>.from(widget.questions[index]['options'] ?? []);
                    int userChoiceIndex = options.indexOf(userAnswer);
                    String userChoiceLetter = (userChoiceIndex != -1)
                        ? String.fromCharCode(65 + userChoiceIndex) // A, B, C, D
                        : "-";

                    return Text("Câu $questionNumber: Bạn chọn $userChoiceLetter ($userAnswer)");
                  },
                ),
              ),
              SizedBox(height: 30),

              // Nút tải file đáp án
              ElevatedButton.icon(
                onPressed: _isLoadingAnswerKey ? null : _pickAndParseAnswerKey,
                icon: _isLoadingAnswerKey
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.upload_file_rounded),
                label: Text(_isLoadingAnswerKey ? "Đang xử lý..." : "Tải & Kiểm tra đáp án (.txt)"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              SizedBox(height: 10),

              // Hiển thị lỗi nếu có
              if (_answerKeyError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _answerKeyError!,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Hiển thị kết quả sau khi kiểm tra
              if (_correctCount != null && _percentage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Text(
                            "Kết quả kiểm tra:",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Số câu đúng: $_correctCount / ${widget.questions.length}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Tỷ lệ chính xác: ${_percentage!.toStringAsFixed(1)}%",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Spacer(), // Đẩy nút quay về xuống dưới

              // Nút quay về trang chủ (Tùy chọn)
              /*
              Padding(
                 padding: const EdgeInsets.only(top: 20.0),
                 child: OutlinedButton(
                   onPressed: () {
                     Navigator.of(context).pushAndRemoveUntil(
                       MaterialPageRoute(builder: (context) => HomeScreen()),
                       (Route<dynamic> route) => false, // Xóa hết các màn hình trước đó
                     );
                   },
                   child: Text("Về Trang Chủ"),
                 ),
               )
               */
            ],
          ),
        ),
      ),
    );
  }
}