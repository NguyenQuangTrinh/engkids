import 'dart:developer' as developer;
import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';
// Giả sử chúng ta dùng một package có khả năng trích xuất text đơn giản
// Nếu dùng pdf_text thì import: import 'package:pdf_text/pdf_text.dart';
// Nếu dùng package khác, import tương ứng.
// *** Tạm thời chưa import package cụ thể để tập trung vào cấu trúc ***

class PdfParsingException implements Exception {
  final String message;
  PdfParsingException(this.message);
  @override
  String toString() => 'PdfParsingException: $message';
}

class PdfParserService {

  // Hàm chính để xử lý file PDF
  Future<List<Map<String, dynamic>>> parsePdf(String filePath) async {
    PdfDocument? document;
    try {
      developer.log("Bắt đầu đọc text từ PDF: $filePath");
      // --- Phần 1: Đọc toàn bộ text từ file PDF ---
      developer.log("Bắt đầu đọc PDF bằng Syncfusion: $filePath");

      // --- Phần 1: Đọc file và trích xuất text bằng Syncfusion ---
      // Đọc dữ liệu byte của file
      final List<int> bytes = await File(filePath).readAsBytes();
      // Tải tài liệu PDF từ dữ liệu byte
      document = PdfDocument(inputBytes: bytes);

      // Tạo đối tượng để trích xuất text
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      // Trích xuất toàn bộ text từ tài liệu
      final String fullPdfText = extractor.extractText();
      // Lưu ý: extractText() của Syncfusion là hàm đồng bộ sau khi document đã load

      developer.log("Đọc PDF bằng Syncfusion thành công. Độ dài text: ${fullPdfText.length}. Bắt đầu phân tích câu hỏi...");
      if (fullPdfText.trim().isEmpty) {
        throw PdfParsingException("Không tìm thấy nội dung text trong file PDF (Syncfusion).");
      }

      // --- Phần 2: Phân tích text để trích xuất câu hỏi ---
      List<Map<String, dynamic>> questions = _parseQuestionsFromText(fullPdfText);

      developer.log("Phân tích hoàn tất. Số câu hỏi tìm thấy: ${questions.length}");
      if (questions.isEmpty) {
        throw PdfParsingException("Không tìm thấy câu hỏi nào theo định dạng mong muốn trong file PDF.");
      }

      return questions;

    } catch (e) {
      developer.log("",error: "Lỗi trong quá trình xử lý PDF: $e");
      // Ném lại lỗi hoặc một lỗi tùy chỉnh để bên ngoài xử lý
      if (e is PdfParsingException) {
        rethrow;
      }
      throw PdfParsingException("Không thể xử lý file PDF bằng Syncfusion. Lỗi: ${e.toString()}");
    }finally {
      document?.dispose();
      developer.log("Đã dispose PdfDocument của Syncfusion.");
    }
  }

  // --- Hàm giả lập đọc PDF ---


  // --- Hàm phân tích text để lấy câu hỏi (PHẦN PHỨC TẠP NHẤT) ---
  List<Map<String, dynamic>> _parseQuestionsFromText(String text) {
    List<Map<String, dynamic>> questions = [];
    List<String> lines = text.split('\n');
    String? currentQuestionText;
    List<String> currentOptions = [];
    final questionStartRegex = RegExp(r"^(Câu\s*\d+\s*:|Exercise\s*\d+\s*:|\d+\.\s+)", caseSensitive: false);
    final optionStartRegex = RegExp(r"^\s*([A-D])[\.\)]\s+", caseSensitive: false);

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      var questionMatch = questionStartRegex.firstMatch(line);
      var optionMatch = optionStartRegex.firstMatch(line);

      if (questionMatch != null) {
        if (currentQuestionText != null && currentOptions.isNotEmpty && currentOptions.length >= 2) { // Thêm kiểm tra số lượng options >= 2
          questions.add({ 'text': currentQuestionText.trim(), 'options': List.from(currentOptions) });
        }
        currentQuestionText = line.replaceFirst(questionStartRegex, '').trim();
        currentOptions.clear();
      } else if (optionMatch != null && currentQuestionText != null) {
        String optionText = line.replaceFirst(optionStartRegex, '').trim();
        if (optionText.isNotEmpty) {
          currentOptions.add(optionText);
        }
      } else if (currentQuestionText != null && currentOptions.isEmpty) {
        currentQuestionText += " $line";
      } else if (currentQuestionText != null && currentOptions.isNotEmpty) {
        if (currentOptions.isNotEmpty) {
          currentOptions.last += " $line";
        }
      }
    }

    if (currentQuestionText != null && currentOptions.isNotEmpty && currentOptions.length >= 2) { // Thêm kiểm tra số lượng options >= 2
      questions.add({ 'text': currentQuestionText.trim(), 'options': currentOptions });
    }

    developer.log("--- Kết quả phân tích thô ---");
    // questions.forEach((q) => print("Q: ${q['text']} \nOptions: ${q['options']}"));
    developer.log("----------------------------");

    return questions;
  }
// -------------------------------------------------------------
}