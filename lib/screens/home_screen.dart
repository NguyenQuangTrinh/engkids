// lib/screens/home_screen.dart

import 'package:engkids/providers/auth_provider.dart';
import 'package:engkids/screens/friend_requests_screen.dart';
import 'package:engkids/screens/history_screen.dart';
import 'package:engkids/screens/question_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/section_title.dart';
import 'achievements_screen.dart';
import 'vocabulary/fun_vocabulary_menu_screen.dart';
import 'library_screen.dart';
import 'loading_screen.dart';
import '../widgets/home_screen_header.dart';
import '../widgets/home/greeting_mascot_section.dart';
import '../widgets/home/continue_learning_card.dart';
import '../widgets/home/activity_grid_section.dart';
import '../widgets/home/tools_support_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// <<< THAY ĐỔI 2: Kế thừa ConsumerState
class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Logic của AnimationController được giữ nguyên
  late AnimationController _animationController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Không cần _loadUserName() nữa, Riverpod sẽ lo việc này
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final String filePath = result.files.first.path!;

        if (!mounted) return;
        // Điều hướng sang LoadingScreen và chờ kết quả là danh sách câu hỏi
        final List<Map<String, dynamic>>? questionsFromLoading =
            await Navigator.push<List<Map<String, dynamic>>?>(
              context,
              MaterialPageRoute<List<Map<String, dynamic>>?>(
                builder: (context) => LoadingScreen(filePath: filePath),
              ),
            );

        // Nếu có câu hỏi trả về, điều hướng sang QuestionScreen
        if (questionsFromLoading != null &&
            questionsFromLoading.isNotEmpty &&
            mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => QuestionScreen(questions: questionsFromLoading),
            ),
          );
        } else if (questionsFromLoading == null && mounted) {
          // LoadingScreen có thể đã pop với null do lỗi hoặc không có câu hỏi
          // SnackBar lỗi có thể đã được hiển thị bởi LoadingScreen
        }
      } else {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName sắp ra mắt!'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color engColor = Colors.redAccent[700] ?? Colors.red;
    final Color kidsColor = Colors.green[700] ?? Colors.green;

    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;

    final String greeting =
        user?.displayName == null || user!.displayName!.isEmpty
            ? "Luyện tập tiếng Anh hiệu quả!"
            : "Xin chào, ${user.displayName}!";

    // Tạo danh sách dữ liệu cho ActivityGridSection
    final List<ActivityItemData> activityItems = [
      ActivityItemData(
        icon: Icons.file_upload_rounded,
        title: "Bài Tập PDF",
        subtitle: "Tải bài mới từ file",
        color: Colors.amber[700]!,
        onTap: () => _pickFile(context),
      ),
      ActivityItemData(
        icon: Icons.collections_bookmark_rounded,
        title: "Thư Viện",
        subtitle: "Bài tập đã lưu",
        color: Colors.green[600]!,
        onTap:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LibraryScreen()),
              ).then((_) {
                // Tùy chọn: Có thể làm gì đó sau khi từ LibraryScreen quay lại,
                // ví dụ: _loadUserName() nếu LibraryScreen có thể thay đổi profile.
                // Hiện tại không cần.
              }),
            },
      ),
      ActivityItemData(
        icon: Icons.extension_rounded,
        title: "Từ Vựng Vui",
        subtitle: "Trò chơi & Flashcard",
        color: Colors.purple[400]!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FunVocabularyMenuScreen(),
            ),
          );
        },
      ),
      ActivityItemData(
        icon: Icons.star_rounded,
        title: "Thử Thách",
        subtitle: "Nhiệm vụ mỗi ngày",
        color: Colors.pinkAccent[200]!,
        onTap: () => _showComingSoon(context, "Thử Thách"),
      ),
    ];

    // Tạo danh sách dữ liệu cho ToolsSupportSection
    final List<FeatureButtonData> featureButtons = [
      FeatureButtonData(
        icon: Icons.group_rounded,
        label: "Friend",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FriendsScreen()),
          );
        },
      ),
      // FeatureButtonData(
      //   icon: Icons.group_add_rounded,
      //   label: "Tìm bạn",
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const FindFriendsScreen()),
      //     );
      //   },
      // ),
      FeatureButtonData(
        icon: Icons.history_rounded,
        label: "Lịch sử",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
      ),
      FeatureButtonData(
        icon: Icons.military_tech_rounded,
        label: "Thành tích",
        onPressed:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              ),
            },
      ),
      FeatureButtonData(
        icon: Icons.book_rounded,
        label: "Sổ tay từ",
        onPressed: () => _showComingSoon(context, "Sổ tay từ vựng"),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan[50]!,
              Colors.lightBlue[100]!,
              Colors.lightBlue[200]!,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 5.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: HomeScreenHeader(
                    engColor: engColor,
                    kidsColor: kidsColor,
                    logoFontFamily: 'Comic Sans MS',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: GreetingAndMascotSection(
                  greetingText: greeting,
                  iconAnimation: _iconAnimation,
                  // Bạn có thể tùy chỉnh mascotIcon và color nếu muốn
                ),
              ),
              SliverToBoxAdapter(
                child: SectionTitle(title: "Tiếp tục học nhé?"),
              ),
              SliverToBoxAdapter(
                child: ContinueLearningCard(
                  onTap: () => _showComingSoon(context, "Tiếp tục bài học"),
                ),
              ),
              SliverToBoxAdapter(child: SectionTitle(title: "Chức Năng Chính")),
              ActivityGridSection(activityItems: activityItems),
              SliverToBoxAdapter(
                child: SectionTitle(title: "Công Cụ & Hỗ Trợ"),
              ),
              ToolsSupportSection(featureButtons: featureButtons),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
