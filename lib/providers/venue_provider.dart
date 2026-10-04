import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/venue_service.dart';
import '../widgets/venue.dart';

/// Server-side paginated venue state.
///
/// - List view pages through `GET /venuelist?page&limit&search&venue_type`
///   (20/page), appending on scroll — O(page) memory, not O(catalog).
/// - Map keeps a light `mapPoints` cache (limit 100) for clustering; list
///   pages and map points stay independent so scrolling never rebuilds the map.
/// - Search/filter are debounced (350ms) and reset to page 1 server-side.
class VenueProvider extends ChangeNotifier {
  static const int pageSize = 20;

  List<Venue> _items = [];
  List<Venue> get items => _items;

  /// Backwards-compat for existing UI: accumulated server items.
  List<Venue> get all => _items;
  List<Venue> get visible => _items;

  /// Legacy Future API used by older screens; resolves to current items.
  Future<List<Venue>>? _future;
  Future<List<Venue>>? get future => _future;

  int _page = 0;
  int _totalPages = 1;
  int _total = 0;
  int get total => _total;
  bool get hasMore => _page < _totalPages;

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  String _query = '';
  String get query => _query;

  String _typeFilter = 'All';
  String get typeFilter => _typeFilter;

  bool _isMapView = true;
  bool get isMapView => _isMapView;

  Timer? _debounce;
  int _requestId = 0;

  /// Light cache for map clustering (id/lat/lng only matter).
  List<Venue> _mapPoints = [];
  List<Venue> get mapPoints => _mapPoints;

  /// Initial load (page 1 + map points). Safe to call repeatedly.
  void load() {
    if (_loading || (_page > 0 && _items.isNotEmpty)) return;
    refresh();
    refreshMapPoints();
  }

  Future<void> refresh() async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await VenueService.fetchVenuesPage(
        page: 1,
        limit: pageSize,
        search: _query.isEmpty ? null : _query,
        venueType: _typeFilter,
      );
      if (id != _requestId) return;
      _items = res.items;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _future = Future.value(_items);
    } catch (e) {
      if (id != _requestId) return;
      _error = e.toString();
      _future = Future.error(e);
    } finally {
      if (id == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final res = await VenueService.fetchVenuesPage(
        page: _page + 1,
        limit: pageSize,
        search: _query.isEmpty ? null : _query,
        venueType: _typeFilter,
      );
      _items = [..._items, ...res.items];
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _future = Future.value(_items);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshMapPoints() async {
    try {
      final res = await VenueService.fetchVenuesPage(page: 1, limit: 100);
      _mapPoints = res.items;
      notifyListeners();
    } catch (_) {
      // Map keeps stale points; list error surfaces separately.
    }
  }

  void setQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      if (q == _query) return;
      _query = q;
      refresh();
    });
  }

  void setTypeFilter(String value) {
    if (_typeFilter == value) return;
    _typeFilter = value;
    refresh();
  }

  void setMapView(bool value) {
    if (_isMapView == value) return;
    _isMapView = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
