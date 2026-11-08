import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFE5E5E5);
  static const Color primary = Color(0xFF1E3A6F);
  static const Color accent = Color(0xFFF78210);

  static ThemeData get lightTheme => _theme(dark: false);

  static ThemeData get darkTheme => _theme(dark: true);

  static ThemeData _theme({required bool dark}) {
    const darkPrimary = Color(0xFFB8C9F2);
    const darkSurface = Color(0xFF1E1E1E);
    const darkBackground = Color(0xFF121212);
    final primaryColor = dark ? darkPrimary : primary;
    final colorScheme = ColorScheme.fromSeed(
      brightness: dark ? Brightness.dark : Brightness.light,
      seedColor: dark ? darkPrimary : primary,
      primary: primaryColor,
      secondary: accent,
      surface: dark ? darkSurface : Colors.white,
    );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: dark ? darkBackground : background,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? darkSurface : primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(accent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(accent),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      useMaterial3: true,
    );
  }
}
