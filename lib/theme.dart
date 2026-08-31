import 'package:flutter/material.dart';

/// Paleta: blanco / grises fríos / azul.
class AppColors {
  AppColors._();
  static const blue = Color(0xFF2563EB); // primario
  // Manual de identidad Estadio Monumental Simón Bolívar.
  static const navy = Color(0xFF041941); // Azul Medianoche (fondo del logo)
  static const skyDeep = Color(0xFF00A4FF); // Azul Cielo Profundo
  static const skyLight = Color(0xFF99E0FF); // Azul Cielo Claro
  static const blueDark = Color(0xFF1E40AF); // títulos / énfasis
  static const blueSoft = Color(0xFFEFF4FF); // fondos suaves
  static const ink = Color(0xFF0F172A); // texto principal
  static const gray = Color(0xFF64748B); // texto secundario
  static const grayLight = Color(0xFF94A3B8); // hints
  static const line = Color(0xFFE2E8F0); // bordes
  static const surface = Color(0xFFF8FAFC); // fondo app
  static const white = Colors.white;
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const ok = Color(0xFF16A34A);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      surface: AppColors.white,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.grayLight),
      labelStyle: const TextStyle(color: AppColors.gray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blueDark,
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: AppColors.line),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.blueSoft,
        selectedForegroundColor: AppColors.blueDark,
        side: const BorderSide(color: AppColors.line),
        visualDensity: VisualDensity.compact,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: AppColors.line),
      backgroundColor: AppColors.white,
      selectedColor: AppColors.blueSoft,
      labelStyle: const TextStyle(color: AppColors.ink, fontSize: 13),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
    ),
  );
}
