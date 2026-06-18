import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandGreen = Color(0xFF16B548);
  static const Color skyBlue = Color(0xFF1E9ADF);
  static const Color softBlue = Color(0xFFDDF0FF);
  static const Color softGreen = Color(0xFFE3F6E8);
  static const Color softOrange = Color(0xFFFFF2DE);
  static const Color ink = Color(0xFF132238);
  static const Color muted = Color(0xFF74819A);
  static const Color canvas = Color(0xFFF7F8F4);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: brandGreen,
        secondary: skyBlue,
        surface: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: const TextStyle(color: ink),
        bodyMedium: const TextStyle(color: ink),
      ),
    );
  }
}
