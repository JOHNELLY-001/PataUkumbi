import 'package:flutter/material.dart';

/// Airbnb-grade design tokens. Every screen reads from here — no hardcoded
/// colors, radii, or text styles anywhere else.
abstract final class AppTokens {
  // Brand
  static const coral = Color(0xFFFF5A5F);
  static const coralDark = Color(0xFFE04146);
  static const success = Color(0xFF008A00);
  static const star = Color(0xFFFFB400);

  // Surfaces (light)
  static const bg = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF7F7F7);
  static const border = Color(0xFFEBEBEB);

  // Text
  static const ink = Color(0xFF222222);
  static const inkSecondary = Color(0xFF717171);
  static const inkTertiary = Color(0xFFB0B0B0);

  // Shape
  static const radiusCard = 16.0;
  static const radiusButton = 12.0;
  static const radiusChip = 20.0;
  static const buttonHeight = 52.0;

  // Spacing scale
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}
