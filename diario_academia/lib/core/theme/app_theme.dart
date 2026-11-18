import 'package:flutter/material.dart';

class AppTheme {
  // Paleta central do app (pode ser usada nas telas: AppTheme.primary etc.)
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF5B3FE0);
  static const Color success = Color(0xFF22D3A5);
  static const Color background = Color(0xFF0E0F13);
  static const Color surface = Color(0xFF171920);
  static const Color surfaceHigh = Color(0xFF20232C);
  static const Color outline = Color(0xFF2A2E39);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF2A2160),
      onPrimaryContainer: const Color(0xFFE6E0FF),
      secondary: success,
      surface: surface,
      surfaceContainerHigh: surfaceHigh,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x2E7C5CFF),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.grey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : Colors.grey);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}