import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Small status pill: success / warning / error / info.
enum StatusKind { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusKind kind;

  const StatusBadge({super.key, required this.label, required this.kind});

  Color get _bg => switch (kind) {
        StatusKind.success => const Color(0xFFDCFCE7),
        StatusKind.warning => const Color(0xFFFEF3C7),
        StatusKind.error => const Color(0xFFFEE2E2),
        StatusKind.info => AppTokens.primaryTint,
      };

  Color get _fg => switch (kind) {
        StatusKind.success => AppTokens.success,
        StatusKind.warning => AppTokens.warning,
        StatusKind.error => AppTokens.error,
        StatusKind.info => AppTokens.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTokens.t12,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }
}
