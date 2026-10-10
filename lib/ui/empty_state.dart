import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Friendly empty state: phosphor icon + title + subtitle + action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTokens.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTokens.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTokens.t18,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTokens.t14,
                color: AppTokens.inkSecondary,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
