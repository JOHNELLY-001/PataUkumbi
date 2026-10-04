import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Single light theme for the whole app (Plus Jakarta Sans + coral).
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.coral,
    primary: AppTokens.coral,
    secondary: AppTokens.coral,
    surface: AppTokens.bg,
    error: AppTokens.coralDark,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppTokens.bg,
    colorScheme: scheme,
    textTheme: text.apply(
      bodyColor: AppTokens.ink,
      displayColor: AppTokens.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppTokens.bg,
      foregroundColor: AppTokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(
        color: AppTokens.ink,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.bg,
      hintStyle: const TextStyle(color: AppTokens.inkSecondary, fontSize: 15),
      labelStyle: const TextStyle(color: AppTokens.inkSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        borderSide: const BorderSide(color: AppTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        borderSide: const BorderSide(color: AppTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        borderSide: const BorderSide(color: AppTokens.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        borderSide: const BorderSide(color: AppTokens.coralDark),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.ink,
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppTokens.bgSecondary,
      selectedColor: AppTokens.ink,
      labelStyle: const TextStyle(color: AppTokens.ink, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        side: const BorderSide(color: AppTokens.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
    dividerColor: AppTokens.border,
  );
}
