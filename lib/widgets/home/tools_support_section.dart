import 'package:flutter/material.dart';
import 'feature_button_small.dart'; // Import FeatureButtonSmall

// Định nghĩa kiểu dữ liệu cho thông tin của Feature Button Small
class FeatureButtonData {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  FeatureButtonData({required this.icon, required this.label, required this.onPressed});
}

class ToolsSupportSection extends StatelessWidget {
  final List<FeatureButtonData> featureButtons;

  const ToolsSupportSection({
    super.key,
    required this.featureButtons,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: featureButtons.map((buttonData) {
            return FeatureButtonSmall(
              icon: buttonData.icon,
              label: buttonData.label,
              onPressed: buttonData.onPressed,
            );
          }).toList(),
        ),
      ),
    );
  }
}