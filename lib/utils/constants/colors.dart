import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // App Basic Colors
  static const Color primary = Color(0xFF4b68ff);
  static const Color secondary = Color(0xFFFFE24B);
  static const Color accent = Color(0xFFb0c7ff);
  static const Color marketing = Color(0xFFE91E63); // Specific Pink

  // Section Colors (Industrial Mapping)
  static const Color cutting = Color(0xFFF57C00); // Deep Orange
  static const Color printing = Color(0xFF9C27B0); // Purple
  static const Color stitching = Color(0xFF2E7D32); // Forest Green
  static const Color packing = Color(0xFF1976D2); // Strong Blue

  // Status Colors (Semantic)
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
  static const Color warning = Color(0xFFF57C00);

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Background Colors
  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF121212); // Standard M3 Dark
  static const Color darkCard = Color(0xFF1E1E1E); // Elevated Dark Surface

  // Helper for Theme Logic
  static Color getAdaptiveTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : textPrimary;
  }
}
