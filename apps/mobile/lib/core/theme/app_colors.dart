import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = false;

  static Color get primary => isDarkMode ? const Color(0xFF2DD4BF) : const Color(0xFF0B6E64);
  static Color get primaryDark => isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF084F47);
  static Color get accent => isDarkMode ? const Color(0xFFFF8A65) : const Color(0xFFFF6B4A);
  
  // Status Colors
  static Color get success => isDarkMode ? const Color(0xFF34D399) : const Color(0xFF2E9E6B);
  static Color get warning => isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFF5A623);
  static Color get error => isDarkMode ? const Color(0xFFF87171) : const Color(0xFFE24C4B);
  
  static Color get secondary => isDarkMode ? const Color(0xFF2DD4BF) : const Color(0xFF168F83);

  // Backgrounds
  static Color get background => isDarkMode ? const Color(0xFF12181C) : const Color(0xFFFBF9F6);
  static Color get surface => isDarkMode ? const Color(0xFF1B2228) : const Color(0xFFFFFFFF);
  static Color get surfaceDark => isDarkMode ? const Color(0xFF1B2228) : const Color(0xFF1B2228);
  
  // Text
  static Color get textPrimary => isDarkMode ? const Color(0xFFF3F4F6) : const Color(0xFF1C2B36);
  static Color get textSecondary => isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6C7B8A);
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.isDarkMode
          ? Colors.black.withValues(alpha: 0.25)
          : AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.isDarkMode
          ? Colors.black.withValues(alpha: 0.45)
          : AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}
