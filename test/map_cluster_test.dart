import 'package:flutter_test/flutter_test.dart';

import 'package:e_venues/services/map_cluster.dart';
import 'package:e_venues/widgets/venue.dart';

Venue venueAt({required int id, required double lat, required double lng}) {
  return Venue(
    id: id,
    userId: 1,
    name: 'V$id',
    venueType: 'hall',
    description: '',
    district: '',
    ward: '',
    street: '',
    lat: lat,
    lng: lng,
    maxCapacity: 100,
    spaceType: 'indoor',
    parkingAvailable: false,
    pricingType: 'hour',
    pricingPerHour: 50000,
    pricingPerDay: null,
    facilities: '',
    coverImage: '',
    galleryImages: const [],
    endEventTime: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

void main() {
  test('distant venues stay single at high zoom', () {
    final venues = [
      venueAt(id: 1, lat: -6.8, lng: 39.28),
      venueAt(id: 2, lat: -6.9, lng: 39.38),
    ];
    final clusters = clusterVenues(venues, 15);
    expect(clusters.length, 2);
    expect(clusters.every((c) => c.isSingle), isTrue);
  });

  test('nearby venues collapse at low zoom', () {
    final venues = [
      venueAt(id: 1, lat: -6.8001, lng: 39.2801),
      venueAt(id: 2, lat: -6.8002, lng: 39.2802),
    ];
    final clusters = clusterVenues(venues, 8);
    expect(clusters.length, 1);
    expect(clusters.first.count, 2);
    expect(clusters.first.label, '2');
  });

  test('skips invalid coords', () {
    final venues = [
      venueAt(id: 1, lat: double.nan, lng: 39.28),
      venueAt(id: 2, lat: -6.8, lng: 39.28),
    ];
    final clusters = clusterVenues(venues, 15);
    expect(clusters.length, 1);
  });

  test('filterToBounds keeps padding, null bounds = all', () {
    final venues = [
      venueAt(id: 1, lat: -6.8, lng: 39.28),
      venueAt(id: 2, lat: -1.0, lng: 30.0),
    ];
    expect(filterToBounds(venues).length, 2);
    final filtered = filterToBounds(
      venues,
      minLat: -7.0,
      maxLat: -6.5,
      minLng: 39.0,
      maxLng: 39.5,
    );
    expect(filtered.length, 1);
    expect(filtered.first.id, 1);
  });
}
