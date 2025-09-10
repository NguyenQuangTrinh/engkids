// lib/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/leaderboard_provider.dart'; 
// Widget con để hiển thị một bảng xếp hạng
class LeaderboardList extends ConsumerWidget {
  final String gameType;
  final String gameTitle;

  const LeaderboardList({super.key, required this.gameType, required this.gameTitle});
  
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe stream của bảng xếp hạng cho game này
    final leaderboardAsync = ref.watch(leaderboardProvider(gameType));

    return leaderboardAsync.when(
      data: (scores) {
        if (scores.isEmpty) {
          return Center(
            child: Text("Chưa có ai ghi danh trên bảng xếp hạng '$gameTitle'.", textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final scoreItem = scores[index];
            final rank = index + 1;
            final formattedTime = _formatDuration(scoreItem.score);
            final formattedDate = DateFormat('dd/MM/yyyy').format(scoreItem.dateAchieved);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank == 1 ? Colors.amber[600] : (rank == 2 ? Colors.grey[400] : (rank == 3 ? Colors.brown[300] : Colors.blueGrey[100])),
                  child: Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(scoreItem.playerName ?? "Người chơi ẩn danh", style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text("Ngày: $formattedDate"),
                trailing: Text(
                  formattedTime,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Lỗi tải bảng xếp hạng: $err")),
    );
  }
}


// Màn hình chính giờ chỉ còn nhiệm vụ quản lý Tab
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bảng Xếp Hạng"),
        backgroundColor: Colors.lightBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Nối Từ", icon: Icon(Icons.compare_arrows_rounded)),
            Tab(text: "Đố Chữ", icon: Icon(Icons.sort_by_alpha_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Mỗi tab là một widget LeaderboardList với gameType tương ứng
          LeaderboardList(gameType: "matching_game", gameTitle: "Nối Từ"),
          LeaderboardList(gameType: "word_scramble", gameTitle: "Đố Chữ"),
        ],
      ),
    );
  }
}