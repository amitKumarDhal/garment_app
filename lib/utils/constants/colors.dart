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

  // --- ✨ BRIGHT & MODERN ACCENTS (New) ---
  // Use these for floating action buttons, active toggles, or highlighting key metrics
  static const Color electricBlue = Color(0xFF2979FF); // Vibrant tech blue
  static const Color neonPink = Color(0xFFFF4081); // Punchy pink for alerts/badges
  static const Color vividCoral = Color(0xFFFF6B6B); // Modern warm red/orange
  static const Color brightMint = Color(0xFF00E676); // High-energy success green
  static const Color cyberYellow = Color(0xFFFFEA00); // Eye-catching warning/highlight

  // --- ☁️ SOFT TINTS (New) ---
  // Perfect for the background of status badges, chips, or subtle alert boxes
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color softPurple = Color(0xFFF3E5F5);
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color softOrange = Color(0xFFFFF3E0);
  static const Color softRed = Color(0xFFFFEBEE);

  // --- 🌈 MODERN GRADIENTS (New) ---
  // Use these inside Container decorations for premium stat cards or headers
  static const List<Color> sunriseGradient = [Color(0xFFFF7E5F), Color(0xFFFEB47B)]; // Warm, energetic
  static const List<Color> oceanGradient = [Color(0xFF2193B0), Color(0xFF6DD5ED)]; // Cool, calm
  static const List<Color> auroraGradient = [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)]; // Very premium Instagram-style

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
        ? Colors.white.withValues(alpha:0.05)
        : Colors.black.withValues(alpha:0.05);
  }
}