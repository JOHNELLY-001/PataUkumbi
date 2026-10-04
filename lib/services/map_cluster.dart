import 'dart:math' as math;

import '../widgets/venue.dart';

/// A cluster of nearby venues rendered as one map marker.
///
/// Dependency-free grid clustering: at low zoom nearby venues collapse into
/// `<count>` bubbles; at high zoom each venue gets its own price marker.
/// Keeps rendered marker count bounded (~dozens) for hundreds of venues.
class VenueCluster {
  final double lat;
  final double lng;
  final List<Venue> members;

  const VenueCluster({required this.lat, required this.lng, required this.members});

  bool get isSingle => members.length == 1;
  int get count => members.length;

  String get label {
    if (isSingle) {
      final v = members.first;
      final price = v.pricingPerHour ?? v.pricingPerDay;
      if (price != null) return _short(price);
      return '•';
    }
    return '$count';
  }

  static String _short(double value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k % 1 == 0 ? k.toInt() : k}k';
    }
    return value.toStringAsFixed(0);
  }
}

/// Grid-cluster [venues] for the given map [zoom] (1-20).
///
/// Cell size halves per zoom level: zoom 13 -> ~0.02°, zoom 10 -> ~0.16°.
/// Venues with invalid coords are skipped.
List<VenueCluster> clusterVenues(List<Venue> venues, double zoom) {
  final cell = 2.56 / math.pow(2, zoom.clamp(1, 20)); // degrees
  final grid = <String, List<Venue>>{};

  for (final v in venues) {
    if (!v.lat.isFinite || !v.lng.isFinite) continue;
    if (v.lat == 0 && v.lng == 0) continue;
    final key = '${(v.lat / cell).floor()}:${(v.lng / cell).floor()}';
    grid.putIfAbsent(key, () => []).add(v);
  }

  return grid.values.map((members) {
    final lat = members.map((v) => v.lat).reduce((a, b) => a + b) / members.length;
    final lng = members.map((v) => v.lng).reduce((a, b) => a + b) / members.length;
    return VenueCluster(lat: lat, lng: lng, members: members);
  }).toList();
}

/// Filter venues to the visible map bounds (with small padding so markers
/// don't pop at edges). Null bounds = no filtering.
List<Venue> filterToBounds(List<Venue> venues, {
  double? minLat,
  double? maxLat,
  double? minLng,
  double? maxLng,
  double padding = 0.05,
}) {
  if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
    return venues;
  }
  return venues.where((v) {
    return v.lat >= minLat - padding &&
        v.lat <= maxLat + padding &&
        v.lng >= minLng - padding &&
        v.lng <= maxLng + padding;
  }).toList();
}
