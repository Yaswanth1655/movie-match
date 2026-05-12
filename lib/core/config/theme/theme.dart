import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTheme {
  static OutlineInputBorder _border([
    Color color = AppPalette.grey,
    double width = 1.0,
  ]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.primaryColor,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.primaryColor,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final baseTextTheme = GoogleFonts.urbanistTextTheme(
      isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        titleSpacing: 16,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: GoogleFonts.urbanist(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceVariant,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.urbanist(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(0.4),
        contentPadding: const EdgeInsets.all(18),
        labelStyle: GoogleFonts.urbanist(color: scheme.onSurfaceVariant),
        hintStyle: GoogleFonts.urbanist(
          color: scheme.onSurfaceVariant.withOpacity(0.7),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        border: _border(scheme.outlineVariant),
        enabledBorder: _border(scheme.outlineVariant),
        focusedBorder: _border(scheme.primary, 2),
        errorBorder: _border(AppPalette.errorBorder),
        focusedErrorBorder: _border(AppPalette.errorBorder, 2),
      ),
    );
  }

  static final ThemeData lightThemeMode = _buildTheme(_lightScheme);
  static final ThemeData darkThemeMode = _buildTheme(_darkScheme);
}
