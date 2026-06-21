import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // ─── Headline Font: Montserrat ───
  static TextTheme montserratTextTheme([TextTheme? base]) {
    final theme = GoogleFonts.montserratTextTheme(base);
    return theme.copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 45, fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 36, fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 18, fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 16, fontWeight: FontWeight.w600,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.8,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.8,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8,
      ),
    );
  }

  // ─── Body Font: Inter ───
  // Applied by overriding body styles on top of the Montserrat text theme
  static TextTheme withInterBody(TextTheme base) {
    return base.copyWith(
      bodyLarge: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
      ),
    );
  }

  // ─── Data/Mono Font: JetBrains Mono ───
  static TextStyle dataLarge({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 28, fontWeight: FontWeight.w700, color: color,
  );
  static TextStyle dataMedium({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 20, fontWeight: FontWeight.w600, color: color,
  );
  static TextStyle dataSmall({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 16, fontWeight: FontWeight.w500, color: color,
  );
  static TextStyle dataTiny({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w400, color: color,
  );
  static TextStyle dataLabel({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color,
  );

  // ─── Convenience: Build complete TextTheme ───
  static TextTheme buildTextTheme([TextTheme? base]) {
    final headlineTheme = montserratTextTheme(base);
    return withInterBody(headlineTheme);
  }
}