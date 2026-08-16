import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> subtle(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> medium(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
