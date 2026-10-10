import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';
import '../../markers/marker_icon.dart';
import '../../widgets/venue_page_details.dart';
import 'compare_sheet.dart';
import 'filter_sheet.dart';
import 'map_overlay_card.dart';
import 'venue_bottom_card.dart';

/// Map tab: light map, white pill markers, single-card carousel.
/// Owns its fetch/markers/camera so list scrolling never rebuilds the map.
class ExploreMapView extends StatefulWidget {
  const ExploreMapView({super.key});

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _loadError;
  LatLng? userLocation;
  GoogleMapController? mapController;
  LatLngBounds? _fetchedBounds;
  bool _viewportFetching = false;
  MapType _mapType = MapType.normal;

  Future<void> _recenter() async {
    final target = userLocation ?? _initialCamera.target;
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, 14),
    );
  }
  List<Map<String, dynamic>> _venues = [];
  List<Map<String, dynamic>> _filteredVenues = [];
  Set<Marker> venueMarkers = {};
  String _mapStyle = "";
  bool _markersLoading = false;
  double _mapZoom = 13;
  CameraPosition? _lastCamera;
  String? _selectedMarkerId;
  final Set<String> _compareIds = {};

  final TextEditingController _searchController = TextEditingController();

  final CameraPosition _initialCamera =
      const CameraPosition(target: LatLng(-6.8, 39.28), zoom: 13);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    getUserLocation();
    loadVenueList();
    _searchController.addListener(_applyLocalFilter);
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle
          .loadString('assets/map_styles/light_map.json');
      if (!mounted) return;
      // GoogleMap.style (set in build) applies this; no setMapStyle call.
      setState(() => _mapStyle = style);
    } catch (_) {
      // Keep default style.
    }
  }

  Future<void> loadVenueList() async {
    try {
      final client = ApiClient();
      final data = await client.getJson(ApiConfig.venueList(limit: 100));
      client.close();
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      if (!mounted) return;
      setState(() {
        _venues =
            list.whereType<Map>().map(Map<String, dynamic>.from).toList();
        _filteredVenues = _venues;
        _isLoading = false;
        _loadError = null;
      });
      venueMarkersFromList();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load venues: $e';
      });
    }
  }

  Future<void> venueMarkersFromList() async {
    if (_markersLoading || _venues.isEmpty || !mounted) return;
    _markersLoading = true;
    try {
      final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
      final cell = 2.56 / math.pow(2, _mapZoom.clamp(1, 20));
      final grid = <String, List<Map<String, dynamic>>>{};
      for (final v in _filteredVenues) {
        final lat = double.tryParse(v['lat']?.toString() ?? '');
        final lng = double.tryParse(v['lng']?.toString() ?? '');
        if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
          continue;
        }
        final key = '${(lat / cell).floor()}:${(lng / cell).floor()}';
        grid.putIfAbsent(key, () => []).add(v);
      }
      final groups = grid.values.toList();
      final clusters =
          groups.length > 150 ? groups.sublist(0, 150) : groups;
      final futures = clusters.map((members) async {
        if (members.length == 1) {
          final v = members.first;
          final lat = double.parse(v['lat'].toString());
          final lng = double.parse(v['lng'].toString());
          final id = v['id']?.toString() ?? '${lat.hashCode}_${lng.hashCode}';
          final price =
              (v['pricing_per_hour'] ?? v['pricing_per_day'] ?? '--')
                  .toString();
          final selected = _selectedMarkerId == 'v$id';
          try {
            final icon = await createPriceMarker(
              price: price,
              pixelRatio: dpr,
              selected: selected,
            );
            return Marker(
              markerId: MarkerId('v$id'),
              position: LatLng(lat, lng),
              icon: icon,
              onTap: () => _selectAndOpen('v$id', v),
            );
          } catch (_) {
            return Marker(
              markerId: MarkerId('v$id'),
              position: LatLng(lat, lng),
              onTap: () => _selectAndOpen('v$id', v),
            );
          }
        }
        final lat = members
                .map((v) => double.parse(v['lat'].toString()))
                .reduce((a, b) => a + b) /
            members.length;
        final lng = members
                .map((v) => double.parse(v['lng'].toString()))
                .reduce((a, b) => a + b) /
            members.length;
        final key = members.map((v) => v['id']).join(',');
        try {
          final icon = await createClusterMarker(
            count: members.length,
            pixelRatio: dpr,
          );
          return Marker(
            markerId: MarkerId('c${key.hashCode}'),
            position: LatLng(lat, lng),
            icon: icon,
            onTap: _zoomIntoCluster,
          );
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        venueMarkers = results.whereType<Marker>().toSet();
      });
    } finally {
      _markersLoading = false;
    }
  }

  void _zoomIntoCluster() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Viewport fetch: when the user pans outside the already-fetched area,
  /// reload with a padded bbox instead of the full catalog.
  Future<void> _refetchForViewport() async {
    if (!mounted || mapController == null || _viewportFetching) return;
    _viewportFetching = true;
    try {
      final bounds = await mapController!.getVisibleRegion();
      final f = _fetchedBounds;
      if (f != null &&
          f.northeast.latitude >= bounds.northeast.latitude &&
          f.northeast.longitude >= bounds.northeast.longitude &&
          f.southwest.latitude <= bounds.southwest.latitude &&
          f.southwest.longitude <= bounds.southwest.longitude) {
        return;
      }
      final padLat =
          (bounds.northeast.latitude - bounds.southwest.latitude) * 0.25;
      final padLng =
          (bounds.northeast.longitude - bounds.southwest.longitude) * 0.25;
      final client = ApiClient();
      final data = await client.getJson(ApiConfig.venueList(
        limit: 100,
        minLat: bounds.southwest.latitude - padLat,
        maxLat: bounds.northeast.latitude + padLat,
        minLng: bounds.southwest.longitude - padLng,
        maxLng: bounds.northeast.longitude + padLng,
      ));
      client.close();
      final list = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : []);
      if (!mounted) return;
      final q = _searchController.text.trim().toLowerCase();
      setState(() {
        _venues =
            list.whereType<Map>().map(Map<String, dynamic>.from).toList();
        _filteredVenues = _venues.where((v) {
          return q.isEmpty ||
              (v['name']?.toString().toLowerCase().contains(q) ??
                  false) ||
              (v['venue_type']
                      ?.toString()
                      .toLowerCase()
                      .contains(q) ??
                  false);
        }).toList();
        _isLoading = false;
        _fetchedBounds = LatLngBounds(
          southwest: LatLng(bounds.southwest.latitude - padLat,
              bounds.southwest.longitude - padLng),
          northeast: LatLng(bounds.northeast.latitude + padLat,
              bounds.northeast.longitude + padLng),
        );
      });
      venueMarkersFromList();
    } catch (_) {
      // Keep stale points; marker rebuild already ran.
    } finally {
      _viewportFetching = false;
    }
  }

  void _applyLocalFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredVenues = _venues.where((v) {
        return q.isEmpty ||
            (v['name']?.toString().toLowerCase().contains(q) ?? false) ||
            (v['venue_type']?.toString().toLowerCase().contains(q) ??
                false);
      }).toList();
    });
    venueMarkersFromList();
  }

  Future<void> getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 12),
      );
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      // Silently keep fallback camera.
    }
  }

  void _openDetails(Map<String, dynamic> v) {
    final id = v['id']?.toString();
    _selectAndOpen(id == null ? null : 'v$id', v);
  }

  /// View Details pushes the full page directly (preview sheet skipped).
  void _openDetailPage(Map<String, dynamic> v) {
    final id = int.tryParse(v['id']?.toString() ?? '');
    if (id == null) return;
    context.read<VenueProvider>().recordViewed(id);
    Navigator.of(context).push(
      MaterialPageRoute(
        // No source hero on this path (compare sheet, carousel button),
        // so the transition fades instead of flying.
        builder: (_) =>
            VenueDetailPage(venueId: id, heroTag: 'mapview-$id'),
      ),
    );
  }

  /// Highlights the tapped price pill (blue fill) while its sheet is
  /// open, then restores it.
  void _selectAndOpen(String? markerKey, Map<String, dynamic> v) {
    if (markerKey != null && markerKey != _selectedMarkerId) {
      setState(() => _selectedMarkerId = markerKey);
      venueMarkersFromList();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: VenueBottomCard(venue: v),
          ),
        ),
      ),
    ).then((_) {
      if (mounted && _selectedMarkerId != null) {
        setState(() => _selectedMarkerId = null);
        venueMarkersFromList();
      }
    });
  }

  void _toggleCompare(Map<String, dynamic> v) {
    final id = v['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (!_compareIds.contains(id) && _compareIds.length >= 3) {
      AppSnack.info(context, 'You can compare up to 3 venues.');
      return;
    }
    setState(() {
      if (_compareIds.contains(id)) {
        _compareIds.remove(id);
      } else {
        _compareIds.add(id);
      }
    });
  }

  void _openCompare() {
    final venues = _filteredVenues
        .where((v) => _compareIds.contains(v['id']?.toString()))
        .toList();
    showCompareSheet(
      context,
      venues: venues,
      onOpen: (v) {
        Navigator.of(context).pop();
        _openDetails(v);
      },
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// google_maps_flutter only renders on Android/iOS (and web with a valid
  /// JS key). On Edge/Windows/Linux the plugin throws
  /// "Cannot read properties of undefined (reading 'maps')", so show a
  /// crash-free list fallback instead. Re-enable web once a valid key is in
  /// web/index.html.
  bool get _isMapSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_mapStyle.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isMapSupported) {
      return _MapFallback(
        isLoading: _isLoading,
        loadError: _loadError,
        venues: _filteredVenues,
        searchController: _searchController,
        onSearchChanged: (v) {
          _applyLocalFilter();
          context.read<VenueProvider>().setQuery(v);
        },
        onClear: () {
          _searchController.clear();
          _applyLocalFilter();
          context.read<VenueProvider>().setQuery('');
        },
        onRetry: () {
          setState(() {
            _isLoading = true;
            _loadError = null;
          });
          loadVenueList();
        },
        onOpen: _openDetails,
      );
    }
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            mapController = controller;
          },
          onCameraMove: (pos) {
            _mapZoom = pos.zoom;
            _lastCamera = pos;
          },
          onCameraIdle: () {
            venueMarkersFromList();
            _refetchForViewport();
          },
          initialCameraPosition: _lastCamera ??
              (userLocation != null
                  ? CameraPosition(target: userLocation!, zoom: 14)
                  : _initialCamera),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: _mapType,
          markers: venueMarkers,
          style: _mapStyle.isEmpty ? null : _mapStyle,
        ),
        Positioned(
          right: 16,
          bottom: 224,
          child: Column(
            children: [
              _MapControlButton(
                label: 'Recenter on my location',
                icon: AppIcons.recenter,
                onTap: _recenter,
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                label: _mapType == MapType.normal
                    ? 'Switch to satellite view'
                    : 'Switch to standard view',
                icon: AppIcons.layers,
                onTap: () => setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                }),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _SearchPill(
            controller: _searchController,
            onChanged: (_) {
              _applyLocalFilter();
              // Keep server list in sync for when user returns to Explore.
              context
                  .read<VenueProvider>()
                  .setQuery(_searchController.text);
            },
            onClear: () {
              _searchController.clear();
              _applyLocalFilter();
              context.read<VenueProvider>().setQuery('');
            },
            onFilter: () => showFilterSheet(context),
          ),
        ),
        if (_loadError != null)
          Positioned(
            top: 76,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Could not load venues',
                        style: const TextStyle(
                            color: AppTokens.ink, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _loadError = null;
                      });
                      loadVenueList();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        if (_compareIds.isNotEmpty)
          Positioned(
            bottom: 224,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _openCompare,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTokens.ink,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTokens.shadowSheet,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.check,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('Compare (${_compareIds.length})',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _compareIds.clear()),
                        child: const Icon(AppIcons.close,
                            color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 130,
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : _filteredVenues.isEmpty
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppTokens.radiusCard),
                        ),
                        child: const Text('No venues in this area',
                            style: TextStyle(
                                color: AppTokens.inkSecondary)),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredVenues.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final v = _filteredVenues[i];
                          return MapOverlayCard(
                            venue: v,
                            onTap: () => _openDetails(v),
                            onOpen: () => _openDetailPage(v),
                            compareSelected: _compareIds.contains(
                                v['id']?.toString()),
                            onCompareToggle: () =>
                                _toggleCompare(v),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onFilter;

  const _SearchPill({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.shadowPill,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(AppIcons.search,
                color: AppTokens.primary, size: 24),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              style: const TextStyle(
                  fontSize: 14, color: AppTokens.ink),
              decoration: InputDecoration(
                hintText: 'Where to celebrate?',
                hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppTokens.inkSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        iconSize: 20,
                        onPressed: onClear,
                        icon: const Icon(AppIcons.clear,
                            color: AppTokens.inkSecondary),
                      ),
              ),
            ),
          ),
          if (onFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: onFilter,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTokens.border),
                  ),
                  child: const Icon(AppIcons.filter,
                      size: 20, color: AppTokens.ink),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Round white floating map control (recenter / layers).
class _MapControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.shadowCard,
          ),
          child: Icon(icon, size: 20, color: AppTokens.ink),
        ),
      ),
    );
  }
}

/// Crash-free fallback for web/desktop where GoogleMap can't render.
/// Reuses the same venue data + bottom-sheet details, so customers can
/// still browse on Edge/Windows.
class _MapFallback extends StatelessWidget {
  final bool isLoading;
  final String? loadError;
  final List<Map<String, dynamic>> venues;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final VoidCallback onRetry;
  final ValueChanged<Map<String, dynamic>> onOpen;

  const _MapFallback({
    required this.isLoading,
    required this.loadError,
    required this.venues,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _SearchPill(
              controller: searchController,
              onChanged: onSearchChanged,
              onClear: onClear,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.border),
              ),
              child: const Text(
                'Map preview is unavailable on web/desktop. Browse venues below — full map works on Android/iOS.',
                style: TextStyle(fontSize: 12, color: AppTokens.inkSecondary),
              ),
            ),
          ),
          if (loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(loadError!,
                        style: const TextStyle(
                            color: AppTokens.ink, fontSize: 13)),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : venues.isEmpty
                    ? const Center(
                        child: Text('No venues in this area',
                            style: TextStyle(
                                color: AppTokens.inkSecondary)),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: venues.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => MapOverlayCard(
                          venue: venues[i],
                          onTap: () => onOpen(venues[i]),
                          onOpen: () => onOpen(venues[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
