import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppTheme {
  static const Color _surface = Color(0xFF0E0E0E);
  static const Color _surfaceLowest = Color(0xFF000000);
  static const Color _primary = Color(0xFFF3FFCA);
  static const Color _primaryContainer = Color(0xFFCAFD00);
  static const Color _secondary = Color(0xFF59C7FF);
  static const Color _secondaryContainer = Color(0xFF102433);
  static const Color _outline = Color(0xFF484847);
  static const Color _onSurface = Color(0xFFE9E6E1);
  static const Color _onSurfaceVariant = Color(0xFFADAAAA);
  static const Color _error = Color(0xFFFF7979);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primary,
      onPrimary: Color(0xFF0B0B0B),
      primaryContainer: _primaryContainer,
      onPrimaryContainer: Color(0xFF0A1100),
      secondary: _secondary,
      onSecondary: Color(0xFF03131B),
      secondaryContainer: _secondaryContainer,
      onSecondaryContainer: Color(0xFFCFEEFF),
      tertiary: Color(0xFFFF8D5C),
      onTertiary: Color(0xFF231005),
      tertiaryContainer: Color(0xFF4B2511),
      onTertiaryContainer: Color(0xFFFFDCCA),
      error: _error,
      onError: Color(0xFF290303),
      errorContainer: Color(0xFF4A1010),
      onErrorContainer: Color(0xFFFFD7D7),
      surface: _surface,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      outline: _outline,
      outlineVariant: _outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE7E1D8),
      onInverseSurface: Color(0xFF1A1A1A),
      inversePrimary: Color(0xFF6C7B00),
      surfaceTint: _primary,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(useMaterial3: true, brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: _onSurface, displayColor: _onSurface);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 46,
        height: 0.96,
        letterSpacing: -0.92,
        fontWeight: FontWeight.w700,
        color: _onSurface,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        height: 1.0,
        letterSpacing: -0.72,
        fontWeight: FontWeight.w700,
        color: _onSurface,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        height: 1.05,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
        color: _onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 1.1,
        letterSpacing: -0.48,
        fontWeight: FontWeight.w700,
        color: _onSurface,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        height: 1.15,
        letterSpacing: -0.28,
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 1.2,
        letterSpacing: -0.18,
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: _onSurfaceVariant,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: _onSurfaceVariant,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: _onSurfaceVariant.withValues(alpha: 0.92),
        height: 1.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
        color: _secondary,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        letterSpacing: 0.9,
        color: _onSurfaceVariant,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: GoogleFonts.robotoMono().fontFamily,
        letterSpacing: 1.0,
        color: _onSurfaceVariant.withValues(alpha: 0.88),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      canvasColor: colorScheme.surface,
      dividerColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.86),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        titleTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surfaceContainer.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainer,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(space: 16, thickness: 0),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceBright;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.32);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.transparent,
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.secondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLowest,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
        helperStyle: textTheme.bodySmall,
        prefixIconColor: colorScheme.secondary,
        suffixIconColor: colorScheme.secondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.55),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          disabledBackgroundColor: colorScheme.surfaceBright,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          textStyle: textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          textStyle: textTheme.titleMedium?.copyWith(
            color: colorScheme.secondary,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          textStyle: textTheme.titleMedium?.copyWith(
            color: colorScheme.secondary,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: const InputDecorationTheme(),
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
