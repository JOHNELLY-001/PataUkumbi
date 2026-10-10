import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Section title row with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppTokens.t18,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: AppTokens.t14,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
