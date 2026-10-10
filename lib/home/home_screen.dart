import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_screen.dart';
import '../providers/saved_provider.dart';
import '../providers/venue_provider.dart';
import '../screens/saved_screen.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';
import 'widgets/explore_map_view.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/home_chrome.dart';
import 'widgets/paginated_venue_list.dart';

/// Tab shell: Explore / Map / Saved / Profile (Airbnb-style).
/// Explore owns search+filter+list; Map keeps its own state via KeepAlive.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final savedCount = context.watch<SavedProvider>().count;
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          _ExploreView(onMapTap: () => setState(() => _tab = 1)),
          const ExploreMapView(),
          const SavedScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _tab,
        savedCount: savedCount,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _ExploreView extends StatefulWidget {
  final VoidCallback? onMapTap;
  const _ExploreView({this.onMapTap});

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final hasText = _search.text.isNotEmpty;
      if (hasText != _showClear && mounted) {
        setState(() => _showClear = hasText);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final venues = context.read<VenueProvider>();
      venues.load();
      venues.loadHistories();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final venues = context.watch<VenueProvider>();
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTokens.border),
                boxShadow: AppTokens.shadowPill,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTokens.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(AppIcons.search,
                        color: AppTokens.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Where to celebrate?',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink)),
                        TextField(
                          controller: _search,
                          textInputAction:
                              TextInputAction.search,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTokens.ink),
                          onChanged: (v) => context
                              .read<VenueProvider>()
                              .setQuery(v),
                          onSubmitted: (v) => context
                              .read<VenueProvider>()
                              .saveSearch(v),
                          decoration: InputDecoration(
                            // hintText:
                            //     'Any location • Any venue • Any hall',
                            hintStyle: const TextStyle(
                                fontSize: 12,
                                color:
                                    AppTokens.inkSecondary),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: !_showClear
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    iconSize: 18,
                                    onPressed: () {
                                      _search.clear();
                                      context
                                          .read<
                                              VenueProvider>()
                                          .setQuery('');
                                    },
                                    icon: const Icon(
                                        AppIcons.clear,
                                        color: AppTokens
                                            .inkSecondary),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        showFilterSheet(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTokens.border),
                      ),
                      child: const Icon(AppIcons.filter,
                          size: 19, color: AppTokens.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: VenueProvider.eventTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = VenueProvider.eventTypes[i];
                return AppChip(
                  label: _chipLabel(t),
                  emoji: _chipEmoji(t),
                  selected: venues.eventType == t,
                  onTap: () => venues.setEventType(t),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text(_featuredSpotsLabel(venues),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink)),
                const Spacer(),
                Text('${venues.total} available',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.inkSecondary)),
              ],
            ),
          ),
          const Expanded(child: PaginatedVenueList()),
            ],
          ),
          if (widget.onMapTap != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Open map view',
                  child: GestureDetector(
                    onTap: widget.onMapTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTokens.inverseSurface,
                        borderRadius:
                            BorderRadius.circular(24),
                        boxShadow: AppTokens.shadowCard,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.map,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Map View',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Design labels + emoji per event chip ("Any event" shows as All).
  String _chipLabel(String t) => t == 'Any event' ? 'All' : t;

  String _chipEmoji(String t) => switch (t) {
        'Weddings' => '💍',
        'Conferences' => '💼',
        'Corporate' => '🏢',
        'Parties' => '🎉',
        'Birthdays' => '🎂',
        'Graduations' => '🎓',
        'Workshops' => '🛠️',
        _ => '✨',
      };

  String _featuredSpotsLabel(VenueProvider venues) {
    final districts = venues.items
        .map((venue) => venue.district.trim())
        .where((district) => district.isNotEmpty)
        .toSet()
        .toList();

    if (districts.length == 1) {
      return 'Featured Spots in ${districts.first}';
    }
    if (districts.length > 1) {
      return 'Featured Spots in various places';
    }
    return 'Featured Spots';
  }
}
