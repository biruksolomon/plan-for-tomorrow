import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette carried over from the printed trackers.
class AppColors {
  static const paper = Color(0xFFE7E1D1);
  static const paper2 = Color(0xFFDED7C4);
  static const ink = Color(0xFF1B1712);
  static const accent = Color(0xFF7A2E27);
  static const accentTint = Color(0xFFF0DCD8);
  static const gold = Color(0xFF9C7A32);
  static const muted = Color(0xFF6B6455);
}

class AppTheme {
  /// Condensed display face, used only for numbers and short headlines.
  static TextStyle display(double size, {Color color = AppColors.ink}) {
    return GoogleFonts.anton(
      fontSize: size,
      color: color,
      height: 0.92,
      letterSpacing: 0.5,
    );
  }

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      decoration: decoration,
      decorationColor: color,
    );
  }

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.gold,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      dividerColor: AppColors.muted,
      splashColor: AppColors.accent.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
    );
  }
}
