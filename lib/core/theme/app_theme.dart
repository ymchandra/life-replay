import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warm, atmospheric palette — dark aged-paper tones with amber accents
  static const Color background = Color(0xFF12100E);
  static const Color surface = Color(0xFF1E1A16);
  static const Color surfaceVariant = Color(0xFF2A251F);
  static const Color primary = Color(0xFFC8956B);       // warm amber / terracotta
  static const Color primaryVariant = Color(0xFFB07B52);
  static const Color secondary = Color(0xFF9E8572);     // muted warm brown
  static const Color onBackground = Color(0xFFF0E6D3);  // warm cream
  static const Color onSurface = Color(0xFFD4C4A8);     // warm parchment
  static const Color onSurfaceVariant = Color(0xFF8C7B6B); // muted warm
  static const Color error = Color(0xFFE07B6B);         // warm red
  static const Color divider = Color(0xFF332D26);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        surfaceVariant: surfaceVariant,
        primary: primary,
        primaryContainer: primaryVariant,
        secondary: secondary,
        onBackground: onBackground,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      textTheme: TextTheme(
        // Serif headings for warmth and narrative quality
        displayLarge: GoogleFonts.playfairDisplay(color: onBackground),
        displayMedium: GoogleFonts.playfairDisplay(color: onBackground),
        displaySmall: GoogleFonts.playfairDisplay(color: onBackground),
        headlineLarge: GoogleFonts.playfairDisplay(color: onBackground),
        headlineMedium: GoogleFonts.playfairDisplay(
            color: onBackground, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.playfairDisplay(
            color: onBackground, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.playfairDisplay(
            color: onBackground, fontWeight: FontWeight.w600),
        // Humanist sans for body — readable, warm
        titleMedium: GoogleFonts.inter(
            color: onBackground, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(
            color: onSurface, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: onSurface, height: 1.6),
        bodyMedium: GoogleFonts.inter(color: onSurface, height: 1.5),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant, height: 1.5),
        labelLarge: GoogleFonts.inter(
            color: onSurface, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.inter(color: onSurfaceVariant),
        labelSmall:
            GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: onBackground,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black54,
        elevation: 0,
        indicatorColor: primary.withOpacity(0.15),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: onSurfaceVariant, size: 22);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.inter(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: onSurfaceVariant,
            fontSize: 11,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant),
        hintStyle: const TextStyle(color: onSurfaceVariant),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primary.withOpacity(0.18);
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return primary;
            return onSurfaceVariant;
          }),
          side: MaterialStateProperty.all(
              const BorderSide(color: divider)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: const TextStyle(color: onSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: divider),
      ),
    );
  }
}
