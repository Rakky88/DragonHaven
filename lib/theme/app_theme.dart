import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF24213B);
  static const twilight = Color(0xFF5B4B8A);
  static const twilightDark = Color(0xFF3D2C73);
  static const mint = Color(0xFF55C6A9);
  static const mintLight = Color(0xFFDFF5EC);
  static const gold = Color(0xFFF4C95D);
  static const goldLight = Color(0xFFFFF0BE);
  static const coral = Color(0xFFF08A7E);
  static const mist = Color(0xFFE8E3F3);
  static const cream = Color(0xFFFFF9F0);
  static const muted = Color(0xFF706B7D);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.twilight,
    brightness: Brightness.light,
    primary: AppColors.twilight,
    secondary: AppColors.mint,
    tertiary: AppColors.gold,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.ink),
      headlineMedium: TextStyle(
          fontSize: 25,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.ink),
      titleLarge: TextStyle(
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.ink),
      titleMedium: TextStyle(
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.1),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mist,
      elevation: 8,
      shadowColor: AppColors.ink.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.twilightDark
                : AppColors.muted,
          )),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.mist)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.twilight, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: AppColors.mist,
  );
}
