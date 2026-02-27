import 'package:flutter/material.dart';
import '../constants/colors.dart';

class TAppTheme {
  TAppTheme._();

  // --- ☀️ LIGHT THEME ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: TColors.primary,
    scaffoldBackgroundColor: TColors.light,

    // ✅ Upgraded: Modern Surface-Level AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false, // Modern apps usually left-align titles
      backgroundColor: TColors.light, // Blends seamlessly with scaffold
      foregroundColor: TColors.textPrimary, // Dark text for readability
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: TColors.textPrimary),
    ),

    // ✅ Upgraded: Material 3 Navigation Bar (For your MainWrapper)
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 3,
      backgroundColor: Colors.white,
      indicatorColor: TColors.primary.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.primary);
        }
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TColors.textSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: TColors.primary, size: 26);
        }
        return const IconThemeData(color: TColors.textSecondary, size: 24);
      }),
    ),

// ✅ Fixed: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.03), width: 1.5),
      ),
    ),
    inputDecorationTheme: _inputTheme(isDark: false),
    elevatedButtonTheme: _elevatedButtonTheme(),
  );

  // --- 🌙 DARK THEME ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: TColors.primary,
    scaffoldBackgroundColor: TColors.dark,

    // ✅ Upgraded: Modern Surface-Level AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: TColors.dark,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // ✅ Upgraded: Material 3 Navigation Bar (For your MainWrapper)
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 3,
      backgroundColor: TColors.darkCard,
      indicatorColor: TColors.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.primary);
        }
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white54);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: TColors.primary, size: 26);
        }
        return const IconThemeData(color: Colors.white54, size: 24);
      }),
    ),

// ✅ Fixed: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: TColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
      ),
    ),
    inputDecorationTheme: _inputTheme(isDark: true),
    elevatedButtonTheme: _elevatedButtonTheme(),
  );

  // --- Common Button Theme ---
  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 55),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );

  // --- Common Input Theme ---
  static InputDecorationTheme _inputTheme({required bool isDark}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // ✅ Better touch targets
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TColors.error, width: 1.5),
        ),
      );
}