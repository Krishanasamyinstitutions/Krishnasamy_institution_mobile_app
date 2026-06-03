import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // App Title - 22px, w600
        displayLarge: TextStyle(
          fontSize: AppSizes.appTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Main Amount - 24px, w700
        displayMedium: TextStyle(
          fontSize: AppSizes.mainAmount,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        // Section Title - 18px, w600
        displaySmall: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        // Body Text - 14px, w400
        bodyLarge: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        // Secondary Text - 12px, w400
        bodySmall: TextStyle(
          fontSize: AppSizes.secondaryText,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        // Tag - 12px, w600
        labelLarge: TextStyle(
          fontSize: AppSizes.tagText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.textLg,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _amberFilledButtonStyle(),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _amberOutlinedButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _amberTextButtonStyle(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4,
          vertical: AppSizes.s4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: AppSizes.textSm,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedXl),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Dark mode colors
  static const Color _darkScaffold = Color(0xFF121218);
  static const Color _darkSurface = Color(0xFF1E1E2A);
  static const Color _darkCard = Color(0xFF1E1E2A);
  static const Color _darkBorder = Color(0xFF2D2D3D);
  static const Color _darkTextPrimary = Color(0xFFF3F4F6);
  static const Color _darkTextSecondary = Color(0xFFD1D5DB);
  static const Color _darkTextTertiary = Color(0xFF9CA3AF);
  static const Color _darkTextHint = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: _darkScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppSizes.appTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: AppSizes.mainAmount,
          fontWeight: FontWeight.w700,
          color: _darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: _darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: _darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: AppSizes.secondaryText,
          fontWeight: FontWeight.w400,
          color: _darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: AppSizes.tagText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.textLg,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _amberFilledButtonStyle(),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _amberOutlinedButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _amberTextButtonStyle(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4,
          vertical: AppSizes.s4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: _darkTextHint,
          fontSize: AppSizes.textSm,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedXl),
          side: const BorderSide(color: _darkBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.normal,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Button styles with full state handling
  //
  // Five states are supported via WidgetStateProperty:
  //   default   — idle (no interaction)
  //   hovered   — mouse pointer over the button (web / desktop only)
  //   focused   — keyboard focus ring (web / desktop)
  //   pressed   — finger / mouse down
  //   disabled  — onPressed: null
  //
  // Color tokens used:
  //   buttonPrimary       (#D2913C, amber base)
  //   buttonPrimaryHover  (#B5752A, darker amber for hover / pressed)
  //   gray300             (#D1D1DB, disabled fill)
  // ──────────────────────────────────────────────────────────────────────────

  static ButtonStyle _amberFilledButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.gray300;
        if (states.contains(WidgetState.pressed)) {
          return AppColors.buttonPrimaryHover;
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.buttonPrimaryHover;
        }
        if (states.contains(WidgetState.focused)) {
          return AppColors.buttonPrimaryHover;
        }
        return AppColors.buttonPrimary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(alpha: 0.7);
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.pressed)) return 1;
        if (states.contains(WidgetState.hovered)) return 4;
        return 0;
      }),
      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.forbidden;
        }
        return SystemMouseCursors.click;
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: AppSizes.s6,
          vertical: AppSizes.s4,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ButtonStyle _amberOutlinedButtonStyle() {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.gray400;
        if (states.contains(WidgetState.pressed)) {
          return AppColors.buttonPrimaryHover;
        }
        return AppColors.buttonPrimary;
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.focused)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.06);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith<BorderSide>((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: AppColors.gray300);
        }
        if (states.contains(WidgetState.pressed)) {
          return const BorderSide(
              color: AppColors.buttonPrimaryHover, width: 1.5);
        }
        return const BorderSide(color: AppColors.buttonPrimary, width: 1.5);
      }),
      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.forbidden;
        }
        return SystemMouseCursors.click;
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: AppSizes.s6,
          vertical: AppSizes.s4,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ButtonStyle _amberTextButtonStyle() {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.gray400;
        if (states.contains(WidgetState.pressed)) {
          return AppColors.buttonPrimaryHover;
        }
        return AppColors.buttonPrimary;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return AppColors.buttonPrimary.withValues(alpha: 0.10);
        }
        return Colors.transparent;
      }),
      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.forbidden;
        }
        return SystemMouseCursors.click;
      }),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
