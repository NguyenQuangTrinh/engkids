import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart'; // Cho DateFormat
import '../models/high_score_model.dart';
import '../service/high_scores_database_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  AchievementsScreenState createState() => AchievementsScreenState();
}

class AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  static const String _logName = 'com.engkids.achievementscreen';
  late TabController _tabController;

  List<HighScoreModel> _matchingGameScores = [];
  List<HighScoreModel> _wordScrambleScores = [];
  bool _isLoadingMatching = true;
  bool _isLoadingScramble = true;

  final HighScoresDatabaseService _hsService = HighScoresDatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllHighScores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHighScores() async {
    await _loadMatchingGameScores();
    await _loadWordScrambleScores();
  }

  Future<void> _loadMatchingGameScores() async {
    if (!mounted) return;
    setState(() { _isLoadingMatching = true; });
    try {
      final scores = await _hsService.getTopScores("matching_game");
      if (mounted) {
        setState(() { _matchingGameScores = scores; _isLoadingMatching = false; });
      }
    } catch (e, s) {
      developer.log("Lỗi tải thành tích Nối Từ", name: _logName, error: e, stackTrace: s);
      if (mounted) { setState(() { _isLoadingMatching = false; });}
      // Hiển thị lỗi nếu cần
    }
  }

  Future<void> _loadWordScrambleScores() async {
    if (!mounted) return;
    setState(() { _isLoadingScramble = true; });
    try {
      final scores = await _hsService.getTopScores("word_scramble");
      if (mounted) {
        setState(() { _wordScrambleScores = scores; _isLoadingScramble = false; });
      }
    } catch (e, s) {
      developer.log("Lỗi tải thành tích Đố Chữ", name: _logName, error: e, stackTrace: s);
      if (mounted) { setState(() { _isLoadingScramble = false; });}
    }
  }

  Widget _buildScoreList(List<HighScoreModel> scores, bool isLoading, String gameTitle) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (scores.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey[400]),
                SizedBox(height: 15),
                Text("Chưa có thành tích nào cho trò chơi '$gameTitle'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 10),
                Text("Hãy chơi để ghi danh nhé!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          )
      );
    }

    return ListView.builder(
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final scoreItem = scores[index];
        final rank = index + 1;
        final formattedTime = _formatDuration(scoreItem.score); // score là thời gian (giây)
        final formattedDate = DateFormat('dd/MM/yyyy').format(scoreItem.dateAchieved);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rank == 1 ? Colors.amber[600] : (rank == 2 ? Colors.grey[400] : (rank == 3 ? Colors.brown[300] : Colors.blueGrey[100])),
              foregroundColor: rank == 1 ? Colors.white : Colors.black87,
              child: Text("$rank", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(scoreItem.playerName ?? "Người chơi ẩn danh", style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text("Thời gian: $formattedTime - Ngày: $formattedDate"),
            trailing: Text(
              // Nếu bạn muốn hiển thị "điểm" là thời gian, hoặc có thể là một giá trị khác
              formattedTime, // Score ở đây là thời gian
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
        );
      },
    );
  }

  // Copy hàm format duration vào đây hoặc tạo một utility class
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bảng Thành Tích"),
        backgroundColor: Colors.lightBlue, // Màu riêng
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Nối Từ", icon: Icon(Icons.compare_arrows_rounded)),
            Tab(text: "Đố Chữ", icon: Icon(Icons.sort_by_alpha_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator( // Cho phép kéo để làm mới
            onRefresh: _loadMatchingGameScores,
            child: _buildScoreList(_matchingGameScores, _isLoadingMatching, "Nối Từ"),
          ),
          RefreshIndicator(
            onRefresh: _loadWordScrambleScores,
            child: _buildScoreList(_wordScrambleScores, _isLoadingScramble, "Đố Chữ"),
          ),
        ],
      ),
    );
  }
}