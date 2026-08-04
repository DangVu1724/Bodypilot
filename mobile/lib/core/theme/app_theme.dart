import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFF97316);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF111827);

  static TextStyle get headlineStyle => GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5);
  static TextStyle get semiboldStyle => GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get bodyStyle => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(
      Typography.material2018().black,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600),
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
          error: const Color(0xFFEF4444),
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: const Color(0xFFFB923C),
          onSecondary: Colors.white,
          onSurface: textPrimary,
        );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFE5E5E5),
      canvasColor: const Color(0xFFE5E5E5),
      cardColor: Colors.white,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: primary, selectionColor: Color(0xFFFEDEA9)),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      Typography.material2018().white,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600),
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          surface: darkSurface,
          error: const Color(0xFFEF4444),
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: const Color(0xFFF59E0B),
          onSecondary: Colors.white,
          onSurface: Colors.white,
        );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkSurface,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
        hintStyle: const TextStyle(color: Colors.white70),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: primary, selectionColor: Color(0xFFFEDEA9)),
    );
  }
}
