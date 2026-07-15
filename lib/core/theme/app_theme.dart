import 'package:flutter/material.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0B6E64),
        secondary: const Color(0xFF168F83),
        surface: const Color(0xFFFFFFFF), // FBF9F6 for bg
        error: const Color(0xFFE24C4B),
      ),
      scaffoldBackgroundColor: const Color(0xFFFBF9F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1C2B36),
        
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B6E64),
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF0B6E64),
        secondary: const Color(0xFF168F83),
        surface: const Color(0xFF1B2228),
        error: const Color(0xFFE24C4B),
      ),
      scaffoldBackgroundColor: const Color(0xFF12181C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B2228),
        foregroundColor: Color(0xFFE1E7EA),
        
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1.copyWith(color: const Color(0xFFE1E7EA)),
        displayMedium: AppTextStyles.h2.copyWith(color: const Color(0xFFE1E7EA)),
        displaySmall: AppTextStyles.h3.copyWith(color: const Color(0xFFE1E7EA)),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFE1E7EA)),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFE1E7EA)),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF8A9A9D)),
        labelLarge: AppTextStyles.label.copyWith(color: const Color(0xFF0B6E64)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B6E64),
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
