import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Cores Premium Dark Mode
  static const Color bgMain = Color(0xFF0B0B0F);
  static const Color bgSecondary = Color(0xFF121218);
  static const Color cardColor = Color(0xFF191820);
  static const Color surfaceElevated = Color(0xFF292630);
  static const Color primary = Color(0xFF813DF5);
  static const Color primaryGradientStart = Color(0xFF6730E8);
  static const Color primaryGradientEnd = Color(0xFFA56BFF);
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFF87171);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain, // Substitui o antigo colorScheme.background
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryGradientEnd,
        surface: cardColor,
        error: danger,
      ),
      // Tipografia explícita e segura contra conflitos
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(textStyle: baseTextTheme.displayLarge, color: textMain, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.manrope(textStyle: baseTextTheme.displayMedium, color: textMain, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.manrope(textStyle: baseTextTheme.headlineLarge, color: textMain, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.manrope(textStyle: baseTextTheme.titleLarge, color: textMain, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.inter(textStyle: baseTextTheme.bodyLarge, color: textMain),
        bodyMedium: GoogleFonts.inter(textStyle: baseTextTheme.bodyMedium, color: textSecondary),
        labelLarge: GoogleFonts.inter(textStyle: baseTextTheme.labelLarge, color: textMain, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(color: textMain, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: textMain),
      ),
      // Correção para o Material 3
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textMain,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.5)),
      ),
    );
  }
}