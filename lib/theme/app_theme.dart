import 'package:flutter/material.dart';

class AppPalette {
  static const Color primary = Color(0xFF0F62FE);
  static const Color primaryDark = Color(0xFF0B4ED0);
  static const Color accent = Color(0xFF14B8A6);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppPalette.primary,
        secondary: AppPalette.accent,
        surface: AppPalette.surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppPalette.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5DFEA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5DFEA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
