import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Football Theme - Elite sports management experience
/// Design: shadcn/ui-inspired with high contrast, 8dp grid, elite proportions

class PremiumSpacing {
  // 8dp spacing grid for consistency (shadcn-inspired)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class PremiumRadii {
  // Corner radii for consistent UI (shadcn-inspired)
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 9999.0;
}

class PremiumShadows {
  // Elevated shadow system (shadcn-inspired depth)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 4,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F000000), // 12% black
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x29000000), // 16% black
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x14000000), // 8% black
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  // Glow effects for premium UI elements
  static List<BoxShadow> glow(Color color, {double intensity = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
}

class PremiumColors {
  // Primary - Rich Blue (elevated, high-contrast)
  static const primary = Color(0xFF1565C0); // Deeper blue
  static const primaryLight = Color(0xFF1976D2);
  static const primaryDark = Color(0xFF0D47A1);

  // Secondary - Vibrant Green (grass energy)
  static const secondary = Color(0xFF2E7D32); // Deep forest green
  static const secondaryLight = Color(0xFF4CAF50);
  static const secondaryDark = Color(0xFF1B5E20);

  // Accent - Electric Purple (premium highlight)
  static const accent = Color(0xFF6A1B9A); // Deep purple
  static const accentLight = Color(0xFF9C27B0);
  static const accentDark = Color(0xFF4A148C);

  // Background - High contrast light mode
  static const background = Color(0xFFFAFAFA); // Soft white
  static const surface = Color(0xFFFFFFFF); // Pure white
  static const surfaceVariant = Color(0xFFF5F5F5); // Very light gray
  static const surfaceElevated = Color(0xFFFFFFFF); // Elevated surface

  // Text - High contrast hierarchy
  static const textPrimary = Color(0xFF09090B); // Near black (shadcn zinc-950)
  static const textSecondary =
      Color(0xFF52525B); // Medium gray (shadcn zinc-600)
  static const textTertiary = Color(0xFFA1A1AA); // Light gray (shadcn zinc-400)
  static const textMuted =
      Color(0xFFD4D4D8); // Very light gray (shadcn zinc-300)

  // Borders - Subtle but defined
  static const border = Color(0xFFE4E4E7); // Light border (shadcn zinc-200)
  static const borderStrong = Color(0xFFD4D4D8); // Stronger border

  // Status
  static const success = Color(0xFF16A34A); // Green-600
  static const warning = Color(0xFFEA580C); // Orange-600
  static const error = Color(0xFFDC2626); // Red-600
  static const info = Color(0xFF0284C7); // Sky-600

  // Divider
  static const divider = Color(0xFFF4F4F5); // Very subtle

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

class PremiumTypography {
  // Headings - Orbitron (geometric, athletic)
  static TextStyle heading1 = GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: PremiumColors.textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.orbitron(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: PremiumColors.textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.orbitron(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: PremiumColors.textPrimary,
  );

  // Body - Heebo (Hebrew support, clean, modern)
  // Heebo is a Google Font with excellent Hebrew glyph coverage
  static TextStyle bodyLarge = GoogleFonts.heebo(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PremiumColors.textPrimary,
    height: 1.6, // Slightly increased for Hebrew readability
  );

  static TextStyle bodyMedium = GoogleFonts.heebo(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PremiumColors.textSecondary,
    height: 1.6,
  );

  static TextStyle bodySmall = GoogleFonts.heebo(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PremiumColors.textTertiary,
    height: 1.5,
  );

  // Labels - Rubik (Hebrew support, bold, geometric)
  // Rubik is a Google Font with strong Hebrew glyph coverage
  static TextStyle labelSmall = GoogleFonts.rubik(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: PremiumColors.textTertiary,
  );
  static TextStyle labelLarge = GoogleFonts.rubik(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: PremiumColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.rubik(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: PremiumColors.textSecondary,
  );

  // Uppercase headlines for tech precision
  static TextStyle techHeadline = GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
    color: PremiumColors.secondary,
  );
}

ThemeData get premiumTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Changed to light for Hattrick style
      scaffoldBackgroundColor: PremiumColors.background,

      colorScheme: const ColorScheme.light(
        primary: PremiumColors.primary,
        onPrimary: Colors.white,
        primaryContainer: PremiumColors.primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: PremiumColors.secondary,
        onSecondary: Colors.white,
        tertiary: PremiumColors.accent,
        onTertiary: Colors.white,
        error: PremiumColors.error,
        onError: Colors.white,
        surface: PremiumColors.surface,
        onSurface: PremiumColors.textPrimary,
        surfaceContainerHighest: PremiumColors.surfaceVariant,
        onSurfaceVariant: PremiumColors.textPrimary,
        outline: PremiumColors.textTertiary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: PremiumColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: PremiumTypography.heading2.copyWith(
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: PremiumColors.surface,
        elevation: 0,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumRadii.lg),
          side: BorderSide(
            color: PremiumColors.border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: PremiumSpacing.md,
          vertical: PremiumSpacing.sm,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: PremiumSpacing.lg,
            vertical: PremiumSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumRadii.md),
          ),
          textStyle: PremiumTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PremiumColors.secondary,
          side: const BorderSide(color: PremiumColors.secondary, width: 2),
          padding: EdgeInsets.symmetric(
            horizontal: PremiumSpacing.lg,
            vertical: PremiumSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumRadii.md),
          ),
          textStyle: PremiumTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PremiumColors.secondary,
          textStyle: PremiumTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PremiumColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: PremiumSpacing.md,
          vertical: PremiumSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumRadii.md),
          borderSide: const BorderSide(color: PremiumColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumRadii.md),
          borderSide: const BorderSide(color: PremiumColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumRadii.md),
          borderSide: const BorderSide(color: PremiumColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PremiumRadii.md),
          borderSide: const BorderSide(color: PremiumColors.error),
        ),
        labelStyle: PremiumTypography.labelMedium,
        hintStyle: PremiumTypography.bodyMedium.copyWith(
          color: PremiumColors.textTertiary,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: PremiumTypography.heading1,
        displayMedium: PremiumTypography.heading2,
        displaySmall: PremiumTypography.heading3,
        headlineLarge: PremiumTypography.heading1,
        headlineMedium: PremiumTypography.heading2,
        headlineSmall: PremiumTypography.heading3,
        titleLarge: PremiumTypography.labelLarge,
        titleMedium: PremiumTypography.labelMedium,
        titleSmall: PremiumTypography.bodySmall,
        bodyLarge: PremiumTypography.bodyLarge,
        bodyMedium: PremiumTypography.bodyMedium,
        bodySmall: PremiumTypography.bodySmall,
        labelLarge: PremiumTypography.labelLarge,
        labelMedium: PremiumTypography.labelMedium,
        labelSmall: PremiumTypography.bodySmall,
      ),

      iconTheme: const IconThemeData(
        color: PremiumColors.textSecondary,
        size: 24,
      ),

      dividerTheme: const DividerThemeData(
        color: PremiumColors.surfaceVariant,
        thickness: 1,
        space: 1,
      ),
    );
