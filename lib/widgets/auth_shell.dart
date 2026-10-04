import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Shared white auth layout: coral mark, title, single-column form.
/// Keeps login/register visually identical with minimal code.
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTokens.coral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.place_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              Text(title,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 15, color: AppTokens.inkSecondary)),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
