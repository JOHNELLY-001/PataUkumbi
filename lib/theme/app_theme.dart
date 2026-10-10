import 'package:flutter/material.dart';

import 'tokens.dart';

/// Coastal Haven theme (bundled Plus Jakarta Sans + coral primary).
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final text = base.textTheme.apply(
    fontFamily: 'Plus Jakarta Sans',
    bodyColor: AppTokens.ink,
    displayColor: AppTokens.ink,
  );

  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary,
    primary: AppTokens.primary,
    secondary: AppTokens.primary,
    surface: AppTokens.surface,
    error: AppTokens.error,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppTokens.bg,
    colorScheme: scheme,
    textTheme: text,
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
    cardTheme: CardThemeData(
      color: AppTokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: const BorderSide(color: AppTokens.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.surface,
      hintStyle: const TextStyle(color: AppTokens.inkTertiary, fontSize: 15),
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
        borderSide: const BorderSide(color: AppTokens.ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        borderSide: const BorderSide(color: AppTokens.error),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.primary,
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
        foregroundColor: AppTokens.primary,
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppTokens.surfaceSecondary,
      selectedColor: AppTokens.primaryTint,
      labelStyle: const TextStyle(color: AppTokens.ink, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        side: const BorderSide(color: AppTokens.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
    dividerColor: AppTokens.border,
  );
}
