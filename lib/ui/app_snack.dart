import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Consistent SnackBars: success / error / info.
abstract final class AppSnack {
  static void show(
    BuildContext context,
    String message, {
    Color background = AppTokens.ink,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message,
          {SnackBarAction? action}) =>
      show(context, message,
          background: AppTokens.success, action: action);

  static void error(BuildContext context, String message) =>
      show(context, message, background: AppTokens.error);

  static void info(BuildContext context, String message) =>
      show(context, message);
}
