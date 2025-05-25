import 'package:flutter/material.dart';
import 'activity_card.dart'; // Import ActivityCard

// Định nghĩa một kiểu dữ liệu cho thông tin của Activity Card để dễ quản lý
class ActivityItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  ActivityItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class ActivityGridSection extends StatelessWidget {
  final List<ActivityItemData> activityItems;

  const ActivityGridSection({
    super.key,
    required this.activityItems,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid.count(
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        children: activityItems.map((item) {
          return ActivityCard(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            color: item.color,
            onTap: item.onTap,
          );
        }).toList(),
      ),
    );
  }
}