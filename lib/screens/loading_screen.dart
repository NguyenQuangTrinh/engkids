import 'dart:io'; // Cần thiết để lấy tên file
import 'dart:async';
import 'dart:developer' as developer; // Cho logging
import 'package:flutter/material.dart';
import '../service/quiz_database_service.dart';
import '../utils/pdf_parser.dart';
import '../models/saved_quiz_model.dart'; // *** THÊM IMPORT SAVEDQUIZMODEL ***

class LoadingScreen extends StatefulWidget {
  final String filePath;

  const LoadingScreen({super.key, required this.filePath});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = "EngKids đang chuẩn bị bài tập...";
  String _fileName = "";
  final PdfParserService _parser = PdfParserService();
  // *** KHỞI TẠO INSTANCE CỦA DATABASESERVICE ***
  final QuizDatabaseService _quizDbService = QuizDatabaseService.instance;
  static const String _logName = 'com.engkids.loadingscreen';

  @override
  void initState() {
    super.initState();
    try {
      _fileName = widget.filePath.split(Platform.pathSeparator).last;
      _statusMessage = "Đang chuẩn bị bài tập từ: $_fileName";
    } catch (e) {
      developer.log("Không thể lấy tên file từ đường dẫn: $e", name: _logName, error: e);
      _fileName = "file được chọn";
      _statusMessage = "Đang chuẩn bị bài tập từ $_fileName...";
    }
    _startPdfProcessing();
  }

  Future<void> _startPdfProcessing() async {
    developer.log("Bắt đầu xử lý file: ${widget.filePath}", name: _logName);
    if (mounted) {
      setState(() {
        _statusMessage = "Đang đọc và phân tích file: $_fileName...";
      });
    }
    List<Map<String, dynamic>>? resultQuestions; // Biến để trả về


    try {
      // 1. Phân tích PDF để lấy câu hỏi
      List<Map<String, dynamic>> parsedQuestions = await _parser.parsePdf(widget.filePath);

      developer.log("Đã phân tích PDF, số câu hỏi: ${parsedQuestions.length}", name: _logName);
      if (mounted) {
        setState(() {
          _statusMessage = "Phân tích thành công! Đang lưu bài tập...";
        });
      }

      // *** 2. TẠO VÀ LƯU BÀI TẬP VÀO DATABASE ***
      if (parsedQuestions.isNotEmpty) { // Chỉ lưu nếu có câu hỏi
        final String quizName = _fileName.replaceAll('.pdf', '').replaceAll('_', ' '); // Tạo tên quiz từ tên file
        final SavedQuizModel newQuizToSave = SavedQuizModel(
          name: quizName,
          originalFilePath: widget.filePath, // Lưu đường dẫn file gốc
          questions: parsedQuestions,        // Danh sách câu hỏi đã parse
          dateAdded: DateTime.now(),         // Ngày giờ hiện tại
        );

        // Gọi hàm insertQuiz từ DatabaseService
        final int savedQuizId = await _quizDbService.insertQuiz(newQuizToSave);
        developer.log("Đã lưu bài tập '${newQuizToSave.name}' vào thư viện với ID: $savedQuizId", name: _logName);
        resultQuestions = parsedQuestions;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Đã lưu '${newQuizToSave.name}' vào thư viện!"),
                backgroundColor: Colors.green),
          );
        }

      } else {
        developer.log("Không có câu hỏi nào được phân tích từ PDF, không lưu vào thư viện.", name: _logName);
      }
      // ********************************************

      // Đợi một chút để người dùng thấy thông báo "Đang lưu..." (tùy chọn)
      // await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return; // Kiểm tra widget còn tồn tại không
      Navigator.pop(context, resultQuestions);

    } on PdfParsingException catch (e, s) {
      developer.log("Lỗi xử lý PDF (từ Service): ${e.message}", name: _logName, error: e, stackTrace: s);
      if (!mounted) return;
      setState(() { _statusMessage = "Lỗi: ${e.message}"; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      developer.log("Lỗi không xác định khi xử lý PDF: $e", name: _logName, error: e, stackTrace: s);
      if (!mounted) return;
      setState(() { _statusMessage = "Đã xảy ra lỗi không mong muốn."; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi không mong muốn khi xử lý file.'), backgroundColor: Colors.red),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.blueGrey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}