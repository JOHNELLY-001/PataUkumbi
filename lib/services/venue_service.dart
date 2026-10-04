import 'package:flutter/foundation.dart';

import '../widgets/venue.dart';
import 'api_client.dart';
import 'api_config.dart';

class PaginatedVenues {
  final List<Venue> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedVenues({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

class VenueService {
  static final ApiClient _client = ApiClient();

  /// Server-side paginated fetch. Forwards page/limit/search/venueType/bbox
  /// to the backend; handles both the new `{data, meta}` envelope and the
  /// legacy bare array.
  static Future<PaginatedVenues> fetchVenuesPage({
    int page = 1,
    int limit = 20,
    String? search,
    String? venueType,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) async {
    final data = await _client.getJson(
      ApiConfig.venueList(
        page: page,
        limit: limit,
        search: search,
        venueType: venueType,
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      ),
    );

    if (data is List) {
      final raw = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final items = await compute(_parseVenues, raw);
      return PaginatedVenues(
        items: items,
        page: 1,
        limit: items.length,
        total: items.length,
        totalPages: 1,
      );
    }

    final map = Map<String, dynamic>.from(data as Map);
    final list = (map['data'] as List? ?? []);
    final meta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};
    final raw = list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    // Heavy parsing (double/DateTime per item) runs off the UI thread.
    final items = await compute(_parseVenues, raw);
    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final total = asInt(meta['total'], items.length);
    final totalPages = asInt(meta['totalPages'], 1);
    return PaginatedVenues(
      items: items,
      page: asInt(meta['page'], page),
      limit: asInt(meta['limit'], limit),
      total: total,
      totalPages: totalPages,
    );
  }

  /// Backwards-compatible helper: fetches one page and returns items.
  static Future<List<Venue>> fetchVenues({
    int? page,
    int? limit,
    String? search,
  }) async {
    final res = await fetchVenuesPage(
      page: page ?? 1,
      limit: limit ?? 50,
      search: search,
    );
    return res.items;
  }

  static Future<Map<String, dynamic>> fetchVenueById(int id) async {
    final data = await _client.getJson(ApiConfig.venueDetail(id));
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected venue detail response');
  }
}

/// Top-level for `compute()`: parses venue JSON off the UI thread.
List<Venue> _parseVenues(List<Map<String, dynamic>> raw) {
  return raw.map(Venue.fromJson).toList();
}
