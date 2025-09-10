// lib/screens/question_screen.dart

import 'dart:async'; // Import để dùng Timer
import 'dart:developer' as developer; // <<< THÊM IMPORT CHO DEVELOPER LOG
import 'package:engkids/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cho LogicalKeyboardKey
// Import các widget con
import '../widgets/question_display.dart'; // Giả sử file này tồn tại
import '../widgets/answer_option.dart'; // Giả sử file này tồn tại
import '../widgets/quiz/quiz_progress_header.dart'; // Widget mới
import '../widgets/quiz/quiz_navigation_controls.dart'; // Widget mới
// Import màn hình kết quả
import 'results_screen.dart';

// Hằng số tổng thời gian làm bài (ví dụ: 30 phút)
const int TOTAL_QUIZ_DURATION_SECONDS = 1800;

class QuestionScreen extends StatefulWidget {
  final List<Map<String, dynamic>>
  questions; // Danh sách câu hỏi từ LoadingScreen

  const QuestionScreen({super.key, required this.questions});

  @override
  QuestionScreenState createState() => QuestionScreenState();
}

class QuestionScreenState extends State<QuestionScreen>
    with WidgetsBindingObserver, RouteAware {
  int _currentQuestionIndex = 0;
  final Map<int, String> _userAnswers = {}; // Lưu trữ lựa chọn của người dùng
  final FocusNode _keyboardFocusNode = FocusNode(); // Cho keyboard input

  Timer? _quizTimer; // Đối tượng Timer
  int _timeRemainingInSeconds =
      TOTAL_QUIZ_DURATION_SECONDS; // Thời gian còn lại

  // Tên dùng cho developer.log
  static const String _logName = 'com.engkids.questionscreen';

  @override
  void initState() {
    super.initState();
    _startQuizTimer(); // Bắt đầu đếm ngược thời gian
    WidgetsBinding.instance.addObserver(this);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).requestFocus(_keyboardFocusNode); // Tự động focus
    // });
  }

  void _startQuizTimer() {
    _quizTimer
        ?.cancel(); // Hủy timer cũ nếu có (phòng trường hợp initState gọi lại)
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingInSeconds > 0) {
        if (mounted) {
          // Luôn kiểm tra mounted trước khi gọi setState trong callback của Timer
          setState(() {
            _timeRemainingInSeconds--;
          });
        }
      } else {
        timer.cancel(); // Dừng timer
        _handleTimeUp(); // Xử lý khi hết giờ
      }
    });
  }

  void _handleTimeUp() {
    if (!mounted) return;
    developer.log("Hết giờ làm bài!", name: _logName); // <<< THAY THẾ PRINT
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã hết giờ làm bài! Kết quả sẽ được tổng kết.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
    _finishQuiz(isTimeUp: true); // Tự động kết thúc bài quiz
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đăng ký với RouteObserver để lắng nghe sự kiện chuyển route
    // Đảm bảo routeObserver đã được khởi tạo trong main.dart
    var route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Chỉ đăng ký cho PageRoute
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this); // Hủy đăng ký RouteObserver
    _keyboardFocusNode.dispose();
    _quizTimer?.cancel();
    super.dispose();
  }

  // --- Các hàm của RouteAware ---
  @override
  void didPush() {
    // Route được push vào navigator
    developer.log("QuestionScreen: didPush - Route is pushed", name: _logName);
  }

  @override
  void didPopNext() {
    // Route này được pop về (trở thành route hiện tại)
    developer.log(
      "QuestionScreen: didPopNext - Route is revealed, requesting focus.",
      name: _logName,
    );
    // Yêu cầu focus lại khi màn hình này quay lại hiển thị
    FocusScope.of(context).requestFocus(_keyboardFocusNode);
    // Có thể khởi động lại timer nếu bạn muốn timer tạm dừng khi màn hình không active
    // if (_quizTimer == null || !_quizTimer!.isActive) {
    //   _startQuizTimer();
    // }
    // No need to call super.didPopNext() as it is not defined in the superclass
  }

  @override
  void didPushNext() {
    // Một route khác được push lên trên route này (route này bị che đi)
    developer.log(
      "QuestionScreen: didPushNext - Route is covered, unfocusing.",
      name: _logName,
    );
    _keyboardFocusNode.unfocus(); // Bỏ focus khi màn hình bị che
    // Có thể tạm dừng timer ở đây
    // _quizTimer?.cancel();
    super.didPushNext();
  }

  @override
  void didPop() {
    // Route này đang bị pop ra khỏi navigator
    developer.log(
      "QuestionScreen: didPop - Route is being popped",
      name: _logName,
    );
    _keyboardFocusNode.unfocus(); // Bỏ focus trước khi pop
    super.didPop();
  }
  // -----------------------------

  // --- Theo dõi AppLifecycleState (tùy chọn, để xử lý khi app vào background) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        developer.log("QuestionScreen: App resumed", name: _logName);
        // Có thể resume timer ở đây nếu nó đã bị pause
        break;
      case AppLifecycleState.inactive:
        developer.log("QuestionScreen: App inactive", name: _logName);
        // App không active, chuẩn bị pause
        break;
      case AppLifecycleState.paused:
        developer.log("QuestionScreen: App paused", name: _logName);
        // Có thể pause timer ở đây
        // _quizTimer?.cancel();
        break;
      case AppLifecycleState.detached:
        developer.log("QuestionScreen: App detached", name: _logName);
        break;
      case AppLifecycleState.hidden: // Flutter 3.13+
        developer.log("QuestionScreen: App hidden", name: _logName);
        break;
    }
  }

  void _handleOptionSelected(String option) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = option;
    });
    developer.log(
      "Câu ${_currentQuestionIndex + 1} đã chọn: $option",
      name: _logName,
    );
  }

  void _goToNextQuestion({bool allowSkip = false}) {
    if (!allowSkip && _userAnswers[_currentQuestionIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bạn cần chọn một đáp án trước khi đi tiếp!'),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      FocusScope.of(
        context,
      ).requestFocus(_keyboardFocusNode); // Giữ focus cho keyboard
    } else {
      // Đây là câu cuối cùng, nút "Tiếp theo" giờ là "Hoàn thành"
      _finishQuiz();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      FocusScope.of(context).requestFocus(_keyboardFocusNode); // Giữ focus
    }
  }

  void _finishQuiz({bool isTimeUp = false}) {
    _quizTimer?.cancel(); // Dừng timer khi bài quiz kết thúc

    // Kiểm tra nếu kết thúc do người dùng nhấn "Hoàn thành" mà chưa chọn đáp án câu cuối
    if (!isTimeUp && _userAnswers[_currentQuestionIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bạn cần chọn đáp án cho câu cuối cùng!'),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    developer.log(
      "Bài kiểm tra hoàn thành! Hết giờ: $isTimeUp",
      name: _logName,
    ); // <<< THAY THẾ PRINT
    developer.log(
      "Các câu trả lời của người dùng: $_userAnswers",
      name: _logName,
    ); // <<< THAY THẾ PRINT

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ResultsScreen(
                userAnswers: _userAnswers,
                questions: widget.questions,
                // TODO: Có thể truyền thêm isTimeUp, thời gian làm bài còn lại (hoặc đã dùng) sang ResultsScreen
              ),
        ),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final options = List<String>.from(
        widget.questions[_currentQuestionIndex]['options'] ?? [],
      );
      int? targetOptionIndex;

      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        targetOptionIndex = 0;
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        targetOptionIndex = 1;
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        targetOptionIndex = 2;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        targetOptionIndex = 3;
      }
      // Có thể thêm key E, F nếu số lượng lựa chọn nhiều hơn

      if (targetOptionIndex != null && targetOptionIndex < options.length) {
        _handleOptionSelected(options[targetOptionIndex]);
        return KeyEventResult.handled; // Đã xử lý sự kiện
      }
    }
    return KeyEventResult.ignored; // Bỏ qua các phím và sự kiện khác
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      // Xử lý trường hợp không có câu hỏi nào (ví dụ: lỗi parse PDF)
      return Scaffold(
        appBar: AppBar(title: const Text("Lỗi")),
        body: const Center(
          child: Text("Không có câu hỏi nào để hiển thị. Vui lòng thử lại."),
        ),
      );
    }

    // Đảm bảo _currentQuestionIndex không vượt quá giới hạn
    // (mặc dù logic _goToNextQuestion đã kiểm tra, nhưng đây là một lớp bảo vệ thêm)
    if (_currentQuestionIndex >= widget.questions.length) {
      _currentQuestionIndex = widget.questions.length - 1;
    }

    final currentQuestionData = widget.questions[_currentQuestionIndex];
    final questionText =
        currentQuestionData['text'] as String? ?? "Câu hỏi không có nội dung";
    final dynamic optionsData = currentQuestionData['options'];
    final List<String> options =
        (optionsData is List)
            ? List<String>.from(optionsData.map((item) => item.toString()))
            : [];
    final selectedOption = _userAnswers[_currentQuestionIndex];
    final bool isAnswerSelectedForCurrent = selectedOption != null;

    return Focus(
      focusNode: _keyboardFocusNode,
      // autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: QuizProgressHeader(
            currentQuestionIndex: _currentQuestionIndex,
            totalQuestions: widget.questions.length,
            timeRemainingInSeconds: _timeRemainingInSeconds,
          ),
          backgroundColor: Colors.lightBlueAccent,
          automaticallyImplyLeading: true, // Hiển thị nút back nếu có thể
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestionDisplay(questionText: questionText),
              const SizedBox(height: 15.0),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return AnswerOption(
                      optionText: option,
                      optionLetter: String.fromCharCode(
                        65 + index,
                      ), // A, B, C, D
                      isSelected: selectedOption == option,
                      onTap: () => _handleOptionSelected(option),
                    );
                  },
                ),
              ),
              QuizNavigationControls(
                isFirstQuestion: _currentQuestionIndex == 0,
                isLastQuestion:
                    _currentQuestionIndex == widget.questions.length - 1,
                isAnswerSelected:
                    isAnswerSelectedForCurrent, // Truyền trạng thái đã chọn đáp án
                onPreviousPressed: _goToPreviousQuestion,
                onNextOrFinishPressed: _goToNextQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
