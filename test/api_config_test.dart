import 'package:flutter_test/flutter_test.dart';

import 'package:e_venues/services/api_config.dart';

void main() {
  test('venueList builds pagination + search params', () {
    final uri = ApiConfig.venueList(page: 2, limit: 20, search: 'hall');
    expect(uri.queryParameters['page'], '2');
    expect(uri.queryParameters['limit'], '20');
    expect(uri.queryParameters['search'], 'hall');
  });

  test('venueList omits All filter + includes bbox', () {
    final uri = ApiConfig.venueList(
      venueType: 'All',
      minLat: -7.0,
      maxLat: -6.5,
      minLng: 39.0,
      maxLng: 39.5,
    );
    expect(uri.queryParameters.containsKey('venue_type'), isFalse);
    expect(uri.queryParameters['minLat'], '-7.0');

    final withType = ApiConfig.venueList(venueType: 'hall');
    expect(withType.queryParameters['venue_type'], 'hall');
  });

  test('endpoints share one base', () {
    expect(ApiConfig.login().host, ApiConfig.venueDetail(1).host);
  });
}
