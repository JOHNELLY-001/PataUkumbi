import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/venue_tile.dart';
import '../providers/saved_provider.dart';
import '../providers/venue_provider.dart';
import '../theme/tokens.dart';

/// Wishlist tab: venues the user hearted, resolved against loaded data.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>();
    final all = context.watch<VenueProvider>().items;
    final items =
        all.where((v) => saved.ids.contains(v.id)).toList();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Saved')),
      body: saved.ids.isEmpty
          ? const _Empty(
              icon: Icons.favorite_border_rounded,
              title: 'No saved stays yet',
              subtitle:
                  'Tap the heart on any venue and it will live here.')
          : items.isEmpty
              ? const _Empty(
                  icon: Icons.cloud_download_outlined,
                  title: 'Saved venues are loading',
                  subtitle:
                      'Open Explore once to load venue details.')
              : ListView.builder(
                  padding:
                      const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      VenueTile(venue: items[i]),
                ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Empty(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTokens.inkTertiary),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTokens.inkSecondary)),
          ],
        ),
      ),
    );
  }
}
