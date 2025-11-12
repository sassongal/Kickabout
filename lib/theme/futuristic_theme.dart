import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Futuristic Football Theme - Next-gen mobile experience
/// Design: Football meets AI - clean geometry, data-visual cues, kinetic UI

class FuturisticColors {
  // Primary - Blue (Hattrick style)
  static const primary = Color(0xFF1976D2); // Blue like Hattrick
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF1565C0);
  
  // Secondary - Green (Hattrick style - grass green)
  static const secondary = Color(0xFF4CAF50); // Green like Hattrick
  static const secondaryLight = Color(0xFF81C784);
  static const secondaryDark = Color(0xFF388E3C);
  
  // Accent - Purple
  static const accent = Color(0xFF9C27B0); // Purple
  static const accentLight = Color(0xFFBA68C8);
  static const accentDark = Color(0xFF7B1FA2);
  
  // Background - Light (Hattrick style)
  static const background = Color(0xFFF5F5F5); // Light gray/white like Hattrick
  static const surface = Color(0xFFFFFFFF); // White
  static const surfaceVariant = Color(0xFFE0E0E0); // Light gray
  
  // Text - Dark for light background
  static const textPrimary = Color(0xFF212121); // Dark gray/black
  static const textSecondary = Color(0xFF757575); // Medium gray
  static const textTertiary = Color(0xFF9E9E9E); // Light gray
  
  // Status
  static const success = Color(0xFF4CAF50); // Green
  static const warning = Color(0xFFFF9800); // Orange
  static const error = Color(0xFFE53935); // Red
  static const info = Color(0xFF1976D2); // Blue
  
  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
  
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );
  
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surface],
  );
}

class FuturisticTypography {
  // Headings - Orbitron (geometric, athletic)
  static TextStyle heading1 = GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: FuturisticColors.textPrimary,
  );
  
  static TextStyle heading2 = GoogleFonts.orbitron(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: FuturisticColors.textPrimary,
  );
  
  static TextStyle heading3 = GoogleFonts.orbitron(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: FuturisticColors.textPrimary,
  );
  
  // Body - Inter (clean, modern)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: FuturisticColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: FuturisticColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: FuturisticColors.textTertiary,
    height: 1.4,
  );
  
  // Labels - Montserrat (bold, geometric)
  static TextStyle labelSmall = GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: FuturisticColors.textTertiary,
  );
  static TextStyle labelLarge = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: FuturisticColors.textPrimary,
  );
  
  static TextStyle labelMedium = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: FuturisticColors.textSecondary,
  );
  
  // Uppercase headlines for tech precision
  static TextStyle techHeadline = GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
    color: FuturisticColors.secondary,
  );
}

ThemeData get futuristicDarkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light, // Changed to light for Hattrick style
  scaffoldBackgroundColor: FuturisticColors.background,
  
  colorScheme: const ColorScheme.light(
    primary: FuturisticColors.primary,
    onPrimary: Colors.white,
    primaryContainer: FuturisticColors.primaryLight,
    onPrimaryContainer: Colors.white,
    secondary: FuturisticColors.secondary,
    onSecondary: Colors.white,
    tertiary: FuturisticColors.accent,
    onTertiary: Colors.white,
    error: FuturisticColors.error,
    onError: Colors.white,
    surface: FuturisticColors.surface,
    onSurface: FuturisticColors.textPrimary,
    surfaceContainerHighest: FuturisticColors.surfaceVariant,
    onSurfaceVariant: FuturisticColors.textPrimary,
    outline: FuturisticColors.textTertiary,
  ),
  
  appBarTheme: AppBarTheme(
    backgroundColor: FuturisticColors.primary,
    foregroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: FuturisticTypography.heading2.copyWith(
      color: Colors.white,
    ),
  ),
  
  cardTheme: CardThemeData(
    color: FuturisticColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: FuturisticColors.surfaceVariant,
        width: 1,
      ),
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FuturisticColors.primary,
      foregroundColor: FuturisticColors.textPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: FuturisticTypography.labelLarge,
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: FuturisticColors.secondary,
      side: const BorderSide(color: FuturisticColors.secondary, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: FuturisticTypography.labelLarge,
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: FuturisticColors.secondary,
      textStyle: FuturisticTypography.labelLarge,
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: FuturisticColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: FuturisticColors.surfaceVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: FuturisticColors.surfaceVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FuturisticColors.secondary, width: 2),
    ),
    labelStyle: FuturisticTypography.labelMedium,
    hintStyle: FuturisticTypography.bodyMedium.copyWith(
      color: FuturisticColors.textTertiary,
    ),
  ),
  
  textTheme: TextTheme(
    displayLarge: FuturisticTypography.heading1,
    displayMedium: FuturisticTypography.heading2,
    displaySmall: FuturisticTypography.heading3,
    headlineLarge: FuturisticTypography.heading1,
    headlineMedium: FuturisticTypography.heading2,
    headlineSmall: FuturisticTypography.heading3,
    titleLarge: FuturisticTypography.labelLarge,
    titleMedium: FuturisticTypography.labelMedium,
    titleSmall: FuturisticTypography.bodySmall,
    bodyLarge: FuturisticTypography.bodyLarge,
    bodyMedium: FuturisticTypography.bodyMedium,
    bodySmall: FuturisticTypography.bodySmall,
    labelLarge: FuturisticTypography.labelLarge,
    labelMedium: FuturisticTypography.labelMedium,
    labelSmall: FuturisticTypography.bodySmall,
  ),
  
  iconTheme: const IconThemeData(
    color: FuturisticColors.textSecondary,
    size: 24,
  ),
  
  dividerTheme: const DividerThemeData(
    color: FuturisticColors.surfaceVariant,
    thickness: 1,
    space: 1,
  ),
);

