// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  // Helper để lấy icon và màu sắc cho từng loại hoạt động
  Map<String, dynamic> _getActivityStyle(String activityType) {
    switch (activityType) {
      case 'quiz':
        return {'icon': Icons.description_rounded, 'color': Colors.blue};
      case 'matching_game':
        return {'icon': Icons.compare_arrows_rounded, 'color': Colors.orange};
      case 'word_scramble':
        return {'icon': Icons.shuffle_rounded, 'color': Colors.cyan};
      case 'word_guess':
        return {'icon': Icons.visibility_off_rounded, 'color': Colors.purple};
      default:
        return {'icon': Icons.history_rounded, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử học tập"),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(historyProvider),
        child: historyAsync.when(
          data: (historyList) {
            if (historyList.isEmpty) {
              return const Center(child: Text("Bạn chưa hoàn thành hoạt động nào."));
            }
            return ListView.builder(
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final activity = historyList[index];
                final style = _getActivityStyle(activity.activityType);
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(activity.completedAt);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(style['icon'], color: style['color'], size: 36),
                    title: Text(activity.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Hoàn thành: $formattedDate"),
                    trailing: Text(
                      "${activity.score}/${activity.totalItems}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Lỗi tải lịch sử: $err")),
        ),
      ),
    );
  }
}