import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Selectable pill (Coastal spec: 36px, full radius, label-md).
/// Selected = dark ink surface + white text; optional leading emoji.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.inverseSurface
              : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          border: Border.all(
            color: selected
                ? AppTokens.inverseSurface
                : AppTokens.border,
          ),
        ),
        child: Center(
          child: Text(
            emoji != null ? '$emoji  $label' : label,
            style: TextStyle(
              color: selected ? Colors.white : AppTokens.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
