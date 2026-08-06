import 'package:flutter/material.dart';

/// Dusk-adventure identity for MythDusk.
///
/// Intentionally distinct from Dot Clash neon (no cyan/magenta glow theme).
abstract final class MythDuskColors {
  static const ink = Color(0xFF0B1C24);
  static const deepTeal = Color(0xFF123A44);
  static const mist = Color(0xFF1E4D57);
  static const parchment = Color(0xFFE8DFC8);
  static const amber = Color(0xFFD4A24C);
  static const softGold = Color(0xFFE6C87A);
  static const ember = Color(0xFFC45C3A);
  static const muted = Color(0xFF8FA6AD);

  static const tileRed = Color(0xFFC94B4B);
  static const tileBlue = Color(0xFF3D7CC9);
  static const tileGreen = Color(0xFF3FA86A);
  static const tileYellow = Color(0xFFD4B03C);
  static const tilePurple = Color(0xFF8B5CB8);
}

abstract final class AppTheme {
  static ThemeData get dusk {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: MythDuskColors.amber,
      onPrimary: MythDuskColors.ink,
      secondary: MythDuskColors.softGold,
      onSecondary: MythDuskColors.ink,
      error: MythDuskColors.ember,
      onError: MythDuskColors.parchment,
      surface: MythDuskColors.deepTeal,
      onSurface: MythDuskColors.parchment,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MythDuskColors.ink,
      appBarTheme: const AppBarTheme(
        backgroundColor: MythDuskColors.ink,
        foregroundColor: MythDuskColors.parchment,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: MythDuskColors.parchment,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: MythDuskColors.parchment,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: MythDuskColors.parchment,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: MythDuskColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: MythDuskColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MythDuskColors.amber,
          foregroundColor: MythDuskColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
