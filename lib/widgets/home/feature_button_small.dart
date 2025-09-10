// lib/widgets/home/feature_button_small.dart

import 'package:flutter/material.dart';

class FeatureButtonSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FeatureButtonSmall({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(12),
            backgroundColor: Colors.lightBlueAccent[400]?.withValues(alpha: 0.8),
            elevation: 2,
          ),
          child: Icon(icon, size: 26, color: Colors.white),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey[800]))
      ],
    );
  }
}