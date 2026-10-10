import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/venue_tile.dart';
import '../providers/saved_provider.dart';
import '../providers/venue_provider.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// Wishlist tab: venues the user hearted, resolved against loaded data.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final venues = context.read<VenueProvider>();
      if (venues.items.isEmpty && !venues.loading) {
        venues.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>();
    final provider = context.watch<VenueProvider>();
    final items =
        provider.items.where((v) => saved.ids.contains(v.id)).toList();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('Saved')),
      body: saved.ids.isEmpty
          ? const EmptyState(
              icon: AppIcons.saved,
              title: 'No saved venues yet',
              subtitle:
                  'Tap the heart on any venue and it will live here.')
          : provider.loading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.download,
                      title: 'Still loading your saved venues',
                      subtitle:
                          'We are fetching the latest venues. Pull to refresh on Explore if this persists.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.refresh(),
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.only(top: 12, bottom: 24),
                        itemCount: items.length,
                        itemBuilder: (context, i) => VenueTile(
                            venue: items[i], heroPrefix: 'saved'),
                      ),
                    ),
    );
  }
}
