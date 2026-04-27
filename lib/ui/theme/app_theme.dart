// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';

class AppColors {
  // Jaktbaserte farger - Fjell og naturfarger
  static const primary = Color(0xFF1F3A2D);      // Dyp skoggrønn (fjellskog)
  static const secondary = Color(0xFF5A4A42);    // Jord-grå-brun (ste)
  static const accent = Color(0xFFD97706);       // Oransje (fugler, sol)
  static const lightBackground = Color(0xFFF8F7F4); // Nøytral hys bakgrunn
  static const darkBackground = Color(0xFF0F1419);  // Natt i fjellene
  
  // Ekstra aksentfarger for dybde
  static const success = Color(0xFF10B981);      // Grønn (jagtsukess)
  static const warning = Color(0xFFF59E0B);      // Gul (varsel)
  static const error = Color(0xFFEF4444);        // Rød
  static const skyBlue = Color(0xFF60A5FA);      // Himmelblå
  
  // Proffe brand-farger for bedre dybde
  static const brandPrimary = Color(0xFF1B2E20);    // Dypere grønn for headers
  static const brandSecondary = Color(0xFF2A3D2F);  // Medium grønn
  static const brandAccent = Color(0xFFE67E22);     // Varm oransje
  static const brandSuccess = Color(0xFF27AE60);    // Profesjonell grønn
  static const brandWarning = Color(0xFFF39C12);    // Profesjonell gul
  static const brandError = Color(0xFFE74C3C);      // Profesjonell rød
  
  // Gradient farger
  static const gradientStart = Color(0xFF1F3A2D);   // Start av gradient
  static const gradientEnd = Color(0xFF2A3D2F);     // Slutt av gradient
  
  // Mørk modus forbedringer
  static const darkSurface = Color(0xFF1A1A1A);     // Bedre kontrast
  static const darkCard = Color(0xFF2A2A2A);        // Høyere kontrast kort
  static const darkTextPrimary = Color(0xFFE0E0E0); // Bedre lesbarhet
  static const darkTextSecondary = Color(0xFFB0B0B0); // Sekundær tekst
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadii {
  static const card = 16.0;
  static const button = 12.0;
  static const chip = 8.0;
  static const modal = 20.0;
}

// Gradient hjelpefunksjoner
class AppGradients {
  static LinearGradient primaryGradient() {
    return const LinearGradient(
      colors: [AppColors.gradientStart, AppColors.gradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static LinearGradient accentGradient() {
    return const LinearGradient(
      colors: [AppColors.accent, AppColors.brandAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static LinearGradient successGradient() {
    return const LinearGradient(
      colors: [AppColors.success, AppColors.brandSuccess],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// Forbedrede kort-stiler
class AppCardStyles {
  static CardThemeData elevatedCard() {
    return CardThemeData(
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
  
  static CardThemeData flatCard() {
    return CardThemeData(
      elevation: 0,
      color: AppColors.lightBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.brandSecondary,
      onSecondary: Colors.white,
      tertiary: AppColors.brandAccent,
      onTertiary: Colors.white,
      error: AppColors.brandError,
      onError: Colors.white,
      background: AppColors.lightBackground,
      onBackground: AppColors.brandPrimary,
      surface: Colors.white,
      onSurface: AppColors.brandPrimary,
      surfaceContainerHighest: AppColors.lightBackground,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: AppCardStyles.elevatedCard(),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.brandPrimary,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.brandPrimary,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
        ),
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          color: AppColors.brandPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(
            color: AppColors.brandPrimary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandAccent,
      onPrimary: Colors.white,
      secondary: AppColors.skyBlue,
      onSecondary: Colors.black,
      tertiary: AppColors.brandSuccess,
      onTertiary: Colors.black,
      error: AppColors.brandError,
      onError: Colors.black,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkCard,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.brandAccent,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 6,
        shadowColor: AppColors.brandAccent.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(
            color: AppColors.brandAccent.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: AppColors.brandAccent,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          color: AppColors.darkTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandSuccess,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandAccent,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(
            color: AppColors.brandAccent,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(
            color: AppColors.brandAccent.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(
            color: AppColors.brandAccent.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(
            color: AppColors.brandAccent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
