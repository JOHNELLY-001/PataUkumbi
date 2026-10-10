import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// "TSh 250k" with shared compact formatting (250000 -> 250k, 2M...).
class PriceText extends StatelessWidget {
  final double value;
  final String suffix;
  final double fontSize;
  final FontWeight fontWeight;

  const PriceText(
    this.value, {
    super.key,
    this.suffix = '',
    this.fontSize = AppTokens.t14,
    this.fontWeight = FontWeight.w700,
  });

  /// Shared compact formatter (single source of truth for prices).
  static String compact(double value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k % 1 == 0 ? k.toInt() : k}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'TSh ${compact(value)}$suffix',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: AppTokens.ink,
      ),
    );
  }
}
