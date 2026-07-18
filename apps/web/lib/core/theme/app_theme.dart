import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const Color _primary = Color(0xFF0B6E64);
  static const Color _secondary = Color(0xFF168F83);
  static const Color _accent = Color(0xFFFF6B4A);
  static const Color _error = Color(0xFFE24C4B);

  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light
        ? const Color(0xFF1C2B36)
        : const Color(0xFFE1E7EA);
    final subtleColor = brightness == Brightness.light
        ? const Color(0xFF6C7B8A)
        : const Color(0xFF8A9A9D);

    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: textColor),
      displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: subtleColor),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primary,
        primaryContainer: const Color(0xFFCCEAE7),
        secondary: _secondary,
        tertiary: _accent,
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF5F5F5),
        surfaceContainerLow: const Color(0xFFFBF9F6),
        onSurface: const Color(0xFF1C2B36),
        onSurfaceVariant: const Color(0xFF6C7B8A),
        outlineVariant: const Color(0xFFE2E8F0),
        error: _error,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      cardColor: Colors.white,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        headingTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF6C7B8A), letterSpacing: 0.5),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFFE8F5F3);
          return null;
        }),
        dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1C2B36)),
        columnSpacing: 24,
        horizontalMargin: 24,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF14A098),
        primaryContainer: const Color(0xFF093F3A),
        secondary: _secondary,
        tertiary: _accent,
        surface: const Color(0xFF1C2732),
        surfaceContainerHighest: const Color(0xFF252E38),
        surfaceContainerLow: const Color(0xFF151D25),
        onSurface: const Color(0xFFE1E7EA),
        onSurfaceVariant: const Color(0xFF8A9A9D),
        outlineVariant: const Color(0xFF2D3A44),
        error: _error,
      ),
      scaffoldBackgroundColor: const Color(0xFF111820),
      cardColor: const Color(0xFF1C2732),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C2732),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D3A44)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14A098),
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF14A098),
          side: const BorderSide(color: Color(0xFF14A098)),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252E38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3A44)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3A44)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF14A098), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8A9A9D)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF252E38)),
        headingTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF8A9A9D), letterSpacing: 0.5),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFF1E3530);
          return null;
        }),
        dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFFE1E7EA)),
        columnSpacing: 24,
        horizontalMargin: 24,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2D3A44), thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

// Reusable styled card decoration
class WebCard {
  static BoxDecoration decoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
