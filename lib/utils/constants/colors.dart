import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // --- 🌟 NEXT-GEN EXECUTIVE THEME COLORS ---

  // App Basic Colors
  static const Color primary = Color(0xFF6A1B9A); // Deep Premium Purple
  static const Color secondary = Color(0xFF3949AB); // Deep Indigo
  static const Color accent = Color(0xFF9C27B0); // Vibrant Purple Accent

  // Premium Gradients (Used in Cards & Buttons)
  static const Color gradientStart = Color(0xFF5E35B1); // Deep Purple
  static const Color gradientEnd = Color(0xFF3949AB); // Indigo

  // Background Colors
  static const Color light = Color(0xFFF4F6F9); // Sleek Premium Light Gray/Blue
  static const Color lightCard = Colors.white;
  static const Color dark = Color(0xFF121212); // Deep OLED Dark
  static const Color darkCard = Color(0xFF1E1E1E); // Elevated Dark Surface

  // --- 🏭 DEPARTMENT / PIPELINE COLORS ---
  static const Color marketing = Color(0xFFE91E63); // Specific Pink
  static const Color cutting = Color(0xFFF57C00); // Deep Orange
  static const Color stitching = Color(0xFF2E7D32); // Forest Green
  static const Color printing = Color(0xFF00ACC1); // Deep Sky Blue (Modernized)
  static const Color packing = Color(0xFF8E24AA); // Purple
  static const Color shipping = Color(0xFF1E88E5); // Strong Blue
  static const Color delivered = Color(0xFF00897B); // Teal

  // --- 🚥 SEMANTIC / STATUS COLORS ---
  static const Color success = Color(0xFF43A047); // Modern Green
  static const Color error = Colors.redAccent;
  static const Color info = Color(0xFF1E88E5);
  static const Color warning = Colors.orange;

  // --- 📝 TEXT COLORS ---
  static const Color textPrimary = Color(0xFF2C2C2E); // Softer than pure black
  static const Color textSecondary = Color(0xFF8E8E93); // Premium Gray
  static const Color textWhite = Colors.white;

  // --- 🛠️ HELPER FUNCTIONS ---

  // Helper for adaptive text
  static Color getAdaptiveTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : textPrimary;
  }

  // Helper for adaptive borders/dividers
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);
  }
}