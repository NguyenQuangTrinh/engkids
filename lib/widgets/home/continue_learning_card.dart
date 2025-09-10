// lib/widgets/home/continue_learning_card.dart

import 'package:flutter/material.dart';

class ContinueLearningCard extends StatelessWidget {
  final VoidCallback onTap;

  const ContinueLearningCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implement logic to show actual last practiced item or a default
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(Icons.play_circle_fill_rounded, color: Colors.orange, size: 40),
        title: Text("Bài học dở dang...", style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Nhấn để tiếp tục"),
        trailing: Icon(Icons.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }
}