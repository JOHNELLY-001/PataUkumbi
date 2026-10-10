import 'package:flutter/foundation.dart';

import '../booking/booking_repository.dart';
import '../services/auth_token.dart';

export '../booking/booking_repository.dart'
    show Booking, DateTimeRangeDto, BookingSlots;

/// Reactive store with two backends: local JSON always, server copy when
/// logged in ([syncAuth] flips between them — wired via ProxyProvider in
/// main.dart). Screens watch this; the source is invisible to them.
class BookingProvider extends ChangeNotifier {
  final LocalBookingRepository _local;
  final ApiBookingRepository _remote;

  BookingProvider()
      : _local = LocalBookingRepository(),
        _remote = ApiBookingRepository();

  final List<Booking> _items = [];
  List<Booking> get items => List.unmodifiable(_items);
  int get count => _items.length;

  bool _remoteActive = false;
  bool _syncing = false;

  /// Called on every auth change. Loads the server copy on login
  /// (pushing unsynced local requests first), local copy on logout.
  Future<void> syncAuth(bool loggedIn) async {
    if (loggedIn && !_remoteActive) {
      await useRemote();
    } else if (!loggedIn && _remoteActive) {
      await useLocal();
    }
  }

  Future<void> restore() async {
    if (AuthTokenStore.token != null) {
      await useRemote();
    } else {
      await useLocal();
    }
  }

  Future<void> useLocal() async {
    _remoteActive = false;
    final loaded = await _local.load();
    _items
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> useRemote() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // Push requests made while logged out, then read server truth.
      final pending =
          _items.where((b) => b.status == 'requested').toList();
      for (final p in pending) {
        try {
          await _remote.create(
            venueId: p.venueId,
            venueName: p.venueName,
            coverImage: p.coverImage,
            start: p.dates.start,
            end: p.dates.end,
            guests: p.guests,
            total: p.total,
            eventType: p.eventType,
            slot: p.slot,
            requirements: p.requirements,
            notes: p.notes,
            contactName: p.contactName,
            contactPhone: p.contactPhone,
            deposit: p.deposit,
          );
        } catch (_) {
          // Keep the local copy; it stays visible until it syncs.
        }
      }
      final remote = await _remote.load();
      _items
        ..clear()
        ..addAll(remote);
      _remoteActive = true;
    } catch (_) {
      // Offline / server down: stay on the local copy.
      if (_items.isEmpty) await useLocal();
    } finally {
      _syncing = false;
    }
    notifyListeners();
  }

  BookingRepository get _active => _remoteActive ? _remote : _local;

  Future<Booking> add({
    required int venueId,
    required String venueName,
    required String coverImage,
    required DateTime start,
    required DateTime end,
    required int guests,
    required double total,
    String eventType = '',
    String slot = BookingSlots.fullDay,
    List<String> requirements = const [],
    String notes = '',
    String contactName = '',
    String contactPhone = '',
    double deposit = 0,
  }) async {
    final booking = await _active.create(
      venueId: venueId,
      venueName: venueName,
      coverImage: coverImage,
      start: start,
      end: end,
      guests: guests,
      total: total,
      eventType: eventType,
      slot: slot,
      requirements: requirements,
      notes: notes,
      contactName: contactName,
      contactPhone: contactPhone,
      deposit: deposit,
    );
    _items.insert(0, booking);
    notifyListeners();
    return booking;
  }

  Future<void> cancel(String id) async {
    await _active.cancel(id);
    // Re-read so server-side status flips (cancelled stays visible).
    if (_remoteActive) {
      final remote = await _remote.load();
      _items
        ..clear()
        ..addAll(remote);
    } else {
      final loaded = await _local.load();
      _items
        ..clear()
        ..addAll(loaded);
    }
    notifyListeners();
  }

  /// Booked date ranges for one venue — the flow greys these out.
  List<DateTimeRangeDto> bookedRanges(int venueId) => _items
      .where((b) => b.venueId == venueId)
      .map((b) => b.dates)
      .toList();
}
