import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_screen.dart';
import '../providers/venue_provider.dart';
import '../screens/saved_screen.dart';
import '../theme/tokens.dart';
import 'widgets/explore_map_view.dart';
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
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: IndexedStack(
        index: _tab,
        children: const [
          _ExploreView(),
          ExploreMapView(),
          SavedScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';
  static const _filters = [
    'All',
    'Halls',
    'Gardens',
    'Rooftops',
    'Beach',
    'Conference'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenueProvider>().load();
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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTokens.border),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) =>
                    context.read<VenueProvider>().setQuery(v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTokens.ink),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            context
                                .read<VenueProvider>()
                                .setQuery('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTokens.inkSecondary),
                        ),
                  hintText: 'Where to celebrate?',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _filter = f);
                    context.read<VenueProvider>().setTypeFilter(f);
                  },
                  child: FilterChipLabel(
                      label: f, active: _filter == f),
                );
              },
            ),
          ),
          const Expanded(child: PaginatedVenueList()),
        ],
      ),
    );
  }
}
