import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../theme/tokens.dart';
import '../../markers/marker_icon.dart';
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
  List<Map<String, dynamic>> _venues = [];
  List<Map<String, dynamic>> _filteredVenues = [];
  Set<Marker> venueMarkers = {};
  String _mapStyle = "";
  bool _markersLoading = false;
  double _mapZoom = 13;
  CameraPosition? _lastCamera;

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
      setState(() => _mapStyle = style);
      mapController?.setMapStyle(_mapStyle);
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
          try {
            final icon =
                await createPriceMarker(price: price, pixelRatio: dpr);
            return Marker(
              markerId: MarkerId('v$id'),
              position: LatLng(lat, lng),
              icon: icon,
              onTap: () => _openDetails(v),
            );
          } catch (_) {
            return Marker(
              markerId: MarkerId('v$id'),
              position: LatLng(lat, lng),
              onTap: () => _openDetails(v),
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
          final icon = await createPriceMarker(
            price: '${members.length}',
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
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_mapStyle.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            mapController = controller;
            if (_mapStyle.isNotEmpty) {
              mapController!.setMapStyle(_mapStyle);
            }
          },
          onCameraMove: (pos) {
            _mapZoom = pos.zoom;
            _lastCamera = pos;
          },
          onCameraIdle: () => venueMarkersFromList(),
          initialCameraPosition: _lastCamera ??
              (userLocation != null
                  ? CameraPosition(target: userLocation!, zoom: 14)
                  : _initialCamera),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: venueMarkers,
          style: _mapStyle.isEmpty ? null : _mapStyle,
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
                    child: Text(_loadError!,
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
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 128,
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

  const _SearchPill({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTokens.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTokens.ink),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTokens.inkSecondary),
                ),
          hintText: 'Where to celebrate?',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
