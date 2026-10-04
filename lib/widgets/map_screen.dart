import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? userLocation;
  String _mapStyle = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadMapStyle(), _locate()]);
  }

  // Load JSON map style from assets, then apply if map already exists.
  Future<void> _loadMapStyle() async {
    try {
      final style =
          await rootBundle.loadString('assets/map_styles/map_style.json');
      if (!mounted) return;
      setState(() => _mapStyle = style);
      mapController?.setMapStyle(_mapStyle);
    } catch (_) {
      // Fall back to default Google style.
    }
  }

  Future<void> _locate() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _error = 'Location services disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _error = 'Location permission denied');
        return;
      }
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 12),
      );
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get location: $e');
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _locate();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : userLocation == null
              ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
              : GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (_mapStyle.isNotEmpty) {
                      mapController!.setMapStyle(_mapStyle);
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: userLocation!,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
    );
  }
}
