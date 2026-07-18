import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'is_dark_mode';

  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    AppColors.isDarkMode = isDark;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.light;
    AppColors.isDarkMode = isDark;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
