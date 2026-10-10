import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Primary / secondary / ghost button with built-in loading state.
/// Primary styling matches the theme; secondary and ghost are outlined.
enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.width,
    this.height = AppTokens.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? Colors.white
                  : AppTokens.primary,
            ),
          )
        : Text(label);
    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTokens.primary,
              side: const BorderSide(color: AppTokens.primary),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTokens.radiusButton),
              ),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            onPressed: loading ? null : onPressed,
            child: child,
          ),
        );
      case AppButtonVariant.ghost:
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppTokens.primary,
          ),
          onPressed: loading ? null : onPressed,
          child: child,
        );
    }
  }
}
