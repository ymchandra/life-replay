import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light and vibrant palette — playful violet + coral accents.
  static const Color background = Color(0xFFF6F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDE9FF);
  static const Color primary = Color(0xFF6C4DFF);
  static const Color primaryVariant = Color(0xFF5138CC);
  static const Color secondary = Color(0xFFFF5D8F);
  static const Color onBackground = Color(0xFF1F173D);
  static const Color onSurface = Color(0xFF2A2052);
  static const Color onSurfaceVariant = Color(0xFF6A5E96);
  static const Color error = Color(0xFFD9345E);
  static const Color divider = Color(0xFFD8D0FF);

  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.spaceGrotesk(
          color: onBackground, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(
          color: onBackground, fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.plusJakartaSans(
          color: onSurface, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.plusJakartaSans(color: onSurface, height: 1.45),
      bodyMedium: GoogleFonts.plusJakartaSans(color: onSurface, height: 1.4),
      bodySmall:
          GoogleFonts.plusJakartaSans(color: onSurfaceVariant, height: 1.35),
      labelLarge: GoogleFonts.plusJakartaSans(
          color: onSurface, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.plusJakartaSans(
          color: onSurfaceVariant, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.plusJakartaSans(
          color: onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600),
    );

    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: primary,
        primaryContainer: primaryVariant,
        secondary: secondary,
        secondaryContainer: Color(0xFFFFD7E3),
        tertiary: Color(0xFF2FB6FF),
        tertiaryContainer: Color(0xFFCEF1FF),
        appBarColor: background,
        error: error,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 6,
      scaffoldBackground: background,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        defaultRadius: 12,
        bottomNavigationBarElevation: 0,
      ),
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      dividerColor: divider,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: onBackground,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primary.withOpacity(0.14);
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return primary;
            return onSurfaceVariant;
          }),
          side: MaterialStateProperty.all(const BorderSide(color: divider)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceVariant,
        labelStyle: const TextStyle(color: onSurface, fontSize: 12),
        side: const BorderSide(color: divider),
      ),
    );
  }
}
