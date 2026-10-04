import 'package:flutter_test/flutter_test.dart';

import 'package:e_venues/widgets/venue.dart';

Map<String, dynamic> baseJson() => {
      'id': 1,
      'user_id': 7,
      'name': 'Test_Hall',
      'venue_type': 'hall',
      'description': 'Nice place',
      'district': 'Ilala',
      'ward': 'Kariakoo',
      'street': 'Mafia St',
      'lat': '-6.8',
      'lng': '39.28',
      'max_capacity': 200,
      'space_type': 'indoor',
      'parking_available': true,
      'pricing_type': 'hour',
      'pricing_per_hour': '250000',
      'pricing_per_day': null,
      'facilities': 'AC, Sound',
      'cover_image': 'https://example.com/cover.jpg',
      'gallery_images': ['https://example.com/1.jpg'],
      'end_event_time': '22:00',
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-02T00:00:00.000Z',
    };

void main() {
  test('parses string numerics', () {
    final v = Venue.fromJson(baseJson());
    expect(v.lat, -6.8);
    expect(v.pricingPerHour, 250000);
    expect(v.priceLabel, contains('250000'));
  });

  test('parses numeric (not string) payload + null gallery', () {
    final json = baseJson()
      ..['lat'] = -6.81
      ..['lng'] = 39.29
      ..['pricing_per_hour'] = 50000
      ..['max_capacity'] = '300'
      ..['gallery_images'] = null
      ..['facilities'] = null;
    final v = Venue.fromJson(json);
    expect(v.lat, -6.81);
    expect(v.maxCapacity, 300);
    expect(v.galleryImages, isEmpty);
    expect(v.facilities, '');
  });

  test('never throws on garbage', () {
    final json = baseJson()
      ..['lat'] = 'not-a-number'
      ..['pricing_per_hour'] = 'free'
      ..['created_at'] = 'garbage';
    final v = Venue.fromJson(json);
    expect(v.lat, -6.8); // fallback
    expect(v.pricingPerHour, isNull);
    expect(v.createdAt.millisecondsSinceEpoch, 0);
  });

  test('price labels per pricing_type', () {
    final hour = Venue.fromJson(baseJson());
    expect(hour.priceLabel, contains('/ hour'));

    final day = Venue.fromJson(baseJson()
      ..['pricing_type'] = 'day'
      ..['pricing_per_day'] = '1000000');
    expect(day.priceLabel, contains('/ day'));

    final unknown = Venue.fromJson(baseJson()..['pricing_type'] = 'weird');
    expect(unknown.priceLabel, 'Pricing unavailable');
  });
}
