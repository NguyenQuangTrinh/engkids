import 'package:flutter/material.dart';

class VocabularyGameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final Color cardColor;
  final Color iconColor;
  final VoidCallback onTap;

  const VocabularyGameCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.cardColor,
    this.iconColor = Colors.white, // Màu icon mặc định là trắng
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        child: Card(
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: cardColor, // Màu nền cho thẻ
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(iconData, size: 40.0, color: iconColor),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: iconColor, // Dùng iconColor cho cả text để đồng bộ
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: iconColor.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: iconColor.withValues(alpha: 0.7), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}