// lib/widgets/home/greeting_mascot_section.dart

import 'package:flutter/material.dart';

class GreetingAndMascotSection extends StatelessWidget {
  final String greetingText;
  final Animation<double> iconAnimation;
  final IconData mascotIcon;
  final Color mascotIconColor;

  const GreetingAndMascotSection({
    super.key,
    required this.greetingText,
    required this.iconAnimation,
    this.mascotIcon = Icons.auto_stories_rounded, // Icon mặc định
    this.mascotIconColor = Colors.orangeAccent,  // Màu mặc định
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Column(
        children: [
          Text(
            greetingText,
            style: TextStyle(fontSize: 24, color: Colors.indigo[700], fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),
          ScaleTransition(
            scale: iconAnimation,
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]),
              child: Icon(mascotIcon, size: 100.0, color: mascotIconColor),
            ),
          ),
        ],
      ),
    );
  }
}