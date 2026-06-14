import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Nest palette — warm, grounding, calm. Derived from the brand logo
/// (white linework on a soft cornflower blue) and the wellness iconography.
class NestColors {
  NestColors._();

  /// Primary brand blue, sampled from the logo background.
  static const Color blue = Color(0xFF4A72B0);
  static const Color blueDeep = Color(0xFF34527F);
  static const Color blueSoft = Color(0xFF7E9FD1);
  static const Color blueMist = Color(0xFFDCE6F4);

  /// Warm, nurturing backdrop — like soft morning light.
  static const Color cream = Color(0xFFF7F3EB);
  static const Color creamDeep = Color(0xFFEFE7D8);
  static const Color sand = Color(0xFFE7DcC8);

  /// A gentle, supportive accent (terracotta warmth) for highlights.
  static const Color clay = Color(0xFFD79A77);
  static const Color sage = Color(0xFF8FA98C);

  static const Color ink = Color(0xFF2B3A52);
  static const Color inkSoft = Color(0xFF5C6B82);

  static const Color surface = Color(0xFFFFFFFF);
}

class NestTheme {
  NestTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NestColors.blue,
        primary: NestColors.blue,
        secondary: NestColors.clay,
        surface: NestColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: NestColors.cream,
    );

    final textTheme = GoogleFonts.nunitoSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: NestColors.ink, displayColor: NestColors.ink);

    return base.copyWith(
      textTheme: textTheme.copyWith(
        // Warm, rounded display face for the few large, emotional moments.
        displaySmall: GoogleFonts.fraunces(
          textStyle: textTheme.displaySmall,
          color: NestColors.ink,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: GoogleFonts.fraunces(
          textStyle: textTheme.headlineMedium,
          color: NestColors.ink,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: GoogleFonts.fraunces(
          textStyle: textTheme.headlineSmall,
          color: NestColors.ink,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.fraunces(
          textStyle: textTheme.titleLarge,
          color: NestColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: NestColors.ink,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: NestColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NestColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: NestColors.blueDeep),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NestColors.blueDeep,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  /// Soft, ambient backdrop gradient used across calming surfaces.
  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [NestColors.cream, NestColors.blueMist],
  );

  /// Deep, immersive gradient for the "Hold Me" sanctuary.
  static const LinearGradient sanctuaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [NestColors.blueDeep, NestColors.blue, Color(0xFF6488BD)],
  );
}
