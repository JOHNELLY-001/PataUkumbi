import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';
import '../../widgets/venue.dart';
import 'venue_tile.dart';

/// Server-paginated venue list with infinite scroll (extracted from home).
class PaginatedVenueList extends StatefulWidget {
  const PaginatedVenueList({super.key});

  @override
  State<PaginatedVenueList> createState() => _PaginatedVenueListState();
}

class _PaginatedVenueListState extends State<PaginatedVenueList> {
  final ScrollController _scroll = ScrollController();

  /// Ids already animated in — new pages stagger, refreshes don't replay.
  final Set<int> _seenIds = {};

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
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: 3,
            itemBuilder: (context, _) => const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                      width: double.infinity, height: 220, radius: 16),
                  SizedBox(height: 10),
                  SkeletonBox(width: 180, height: 16),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 14),
                ],
              ),
            ),
          );
        }
        if (venues.error != null && venues.items.isEmpty) {
          return EmptyState(
            icon: AppIcons.alert,
            title: 'Failed to load venues',
            subtitle: 'Network error',
            actionLabel: 'Retry',
            onAction: () => venues.refresh(),
          );
        }
        if (venues.items.isEmpty) {
          return const EmptyState(
            icon: AppIcons.search,
            title: 'No venues found',
            subtitle: 'Try a different search or clear your filters.',
          );
        }
        final groupedItems = _groupByDistrict(venues.items);
        return RefreshIndicator(
          onRefresh: () => venues.refresh(),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            itemCount: groupedItems.length + (venues.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= groupedItems.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final item = groupedItems[index];
              if (item is _DistrictHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink,
                    ),
                  ),
                );
              }
              final venue = (item as _VenueItem).venue;
              final tile = RepaintBoundary(
                child: VenueTile(venue: venue),
              );
              if (!_seenIds.add(venue.id)) return tile;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: child,
                  ),
                ),
                child: tile,
              );
            },
          ),
        );
      },
    );
  }

  List<Object> _groupByDistrict(List<Venue> items) {
    final groups = <String, List<Venue>>{};
    for (final venue in items) {
      final district = venue.district.trim().isEmpty
          ? 'Other locations'
          : venue.district.trim();
      groups.putIfAbsent(district, () => []).add(venue);
    }

    final groupedItems = <Object>[];
    for (final entry in groups.entries) {
      groupedItems.add(_DistrictHeader(entry.key));
      groupedItems.addAll(entry.value.map(_VenueItem.new));
    }
    return groupedItems;
  }
}

class _DistrictHeader {
  final String name;

  const _DistrictHeader(this.name);
}

class _VenueItem {
  final Venue venue;

  const _VenueItem(this.venue);
}
