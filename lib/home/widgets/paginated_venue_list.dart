import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import 'venue_tile.dart';

/// Server-paginated venue list with infinite scroll (extracted from home).
class PaginatedVenueList extends StatefulWidget {
  const PaginatedVenueList({super.key});

  @override
  State<PaginatedVenueList> createState() => _PaginatedVenueListState();
}

class _PaginatedVenueListState extends State<PaginatedVenueList> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scroll.offset >= max - 400) {
      context.read<VenueProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VenueProvider>(
      builder: (context, venues, _) {
        if (venues.loading && venues.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (venues.error != null && venues.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load venues',
                    style: TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 4),
                Text(venues.error!,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => venues.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (venues.items.isEmpty) {
          return const Center(
            child: Text('No venues found',
                style: TextStyle(color: Colors.white38)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => venues.refresh(),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            itemCount: venues.items.length + (venues.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= venues.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return RepaintBoundary(
                child: VenueTile(venue: venues.items[index]),
              );
            },
          ),
        );
      },
    );
  }
}
