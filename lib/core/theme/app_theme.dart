import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Indigo + Amber palette for clear focus and warm accents.
  static const Color background = Color(0xFFF5F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8E7FF);
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color onBackground = Color(0xFF1A1B3A);
  static const Color onSurface = Color(0xFF23254A);
  static const Color onSurfaceVariant = Color(0xFF666A91);
  static const Color error = Color(0xFFD14343);
  static const Color divider = Color(0xFFD8D9F4);

  static Color moodColor(int mood, {Color? fallback}) {
    switch (mood) {
      case 1:
        return const Color(0xFFB45309);
      case 2:
        return const Color(0xFFD97706);
      case 3:
        return secondary;
      case 4:
        return const Color(0xFF818CF8);
      case 5:
        return primary;
      default:
        return fallback ?? onSurfaceVariant;
    }
  }

  static Color phaseColor(String phaseType) {
    switch (phaseType) {
      case 'work':
        return primary;
      case 'travel':
        return const Color(0xFF7C83F6);
      case 'social':
        return secondary;
      case 'creative':
        return const Color(0xFF8B5CF6);
      case 'recovery':
        return const Color(0xFFFBBF24);
      default:
        return onSurfaceVariant;
    }
  }

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
        secondaryContainer: Color(0xFFFFE8BF),
        tertiary: Color(0xFF8B5CF6),
        tertiaryContainer: Color(0xFFEDE9FE),
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
        backgroundColor: secondary,
        foregroundColor: onBackground,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        indicatorColor: secondary,
        labelColor: secondary,
        unselectedLabelColor: onSurfaceVariant,
        dividerColor: divider.withOpacity(0.5),
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
