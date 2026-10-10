import 'package:flutter/material.dart';

/// Coastal Haven Discovery tokens (UI_design.txt).
/// Warm coral accents on pristine neutral grounds; teal/green reserved
/// for verified/success states. Names stay semantic so screens don't care
/// about hex values.
abstract final class AppTokens {
  // Brand
  static const primary = Color(0xFFFF5A5F);
  static const primaryDeep = Color(0xFFB52330);
  static const primaryTint = Color(0xFFFFDAD8);
  static const heart = Color(0xFFFF5A5F);
  static const star = Color(0xFFFF5A5F);
  static const success = Color(0xFF006C4C);
  static const secondary = Color(0xFF006A62);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFBA1A1A);

  // Surfaces (warm light)
  static const bg = Color(0xFFFCF9F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF6F3F2);
  static const surfaceDim = Color(0xFFDCD9D9);
  static const border = Color(0xFFE5E2E1);
  static const inverseSurface = Color(0xFF303030);

  // Text
  static const ink = Color(0xFF1B1C1C);
  static const inkSecondary = Color(0xFF5A403F);
  static const inkTertiary = Color(0xFF8E706F);

  // Shape
  static const radiusCard = 16.0;
  static const radiusButton = 12.0;
  static const radiusChip = 20.0;
  static const buttonHeight = 48.0;

  // Type scale
  static const t28 = 28.0;
  static const t22 = 22.0;
  static const t18 = 18.0;
  static const t16 = 16.0;
  static const t14 = 14.0;
  static const t12 = 12.0;

  // Spacing scale
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  // Shadows (spec elevation levels 1-3)
  static const shadowCard = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const shadowSheet = [
    BoxShadow(color: Color(0x29000000), blurRadius: 30, offset: Offset(0, -8)),
  ];
  static const shadowPill = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
}
