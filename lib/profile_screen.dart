import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/saved_provider.dart';
import 'theme/tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final bookings = context.watch<BookingProvider>().count;
    final saved = context.watch<SavedProvider>().count;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTokens.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 36, color: AppTokens.inkSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loggedIn ? 'Welcome back' : 'Guest explorer',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink)),
                    const Text('Dar es Salaam, Tanzania',
                        style: TextStyle(
                            color: AppTokens.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Row(
            icon: Icons.calendar_month_outlined,
            title: 'My bookings',
            trailing: '$bookings',
            onTap: () =>
                Navigator.of(context).pushNamed('/bookings'),
          ),
          _Row(
            icon: Icons.favorite_border_rounded,
            title: 'Saved',
            trailing: '$saved',
            onTap: () =>
                Navigator.of(context).pushNamed('/saved'),
          ),
          _Row(
            icon: Icons.logout_rounded,
            title: loggedIn ? 'Log out' : 'Log in',
            onTap: () async {
              if (loggedIn) {
                await context.read<AuthProvider>().logout();
              }
              if (context.mounted) {
                Navigator.of(context)
                    .pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('E-Venues · v1.0',
                style: TextStyle(
                    color: AppTokens.inkTertiary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTokens.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, color: AppTokens.ink)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(
                      color: AppTokens.inkSecondary)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppTokens.inkSecondary),
          ],
        ),
      ),
    );
  }
}
