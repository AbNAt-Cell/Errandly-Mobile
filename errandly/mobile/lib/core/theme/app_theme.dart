import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF8C3A);
  static const Color primaryDark = Color(0xFFCC5500);
  static const Color primaryFaded = Color(0xFFFFF0E6);

  static const Color navy = Color(0xFF0A1628);
  static const Color navyLight = Color(0xFF1A2E4A);
  static const Color navyMid = Color(0xFF223550);

  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDDEEFF);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8ECEF);
  static const Color divider = Color(0xFFF1F3F5);

  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Runner app specific
  static const Color runnerBackground = Color(0xFF0A1628);
  static const Color runnerSurface = Color(0xFF1A2E4A);
  static const Color runnerBorder = Color(0xFF223550);
  static const Color runnerText = Color(0xFFFFFFFF);
  static const Color runnerTextMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get customerTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.navy,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
  );

  static ThemeData get runnerTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      surface: AppColors.runnerSurface,
      background: AppColors.runnerBackground,
    ),
    scaffoldBackgroundColor: AppColors.runnerBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.runnerBackground,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: AppColors.textWhite),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.runnerBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.runnerTextMuted,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardTheme(
      color: AppColors.runnerSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.runnerBorder),
      ),
    ),
  );
}
