import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local booking store (no payment): date range + guests + price breakdown,
/// persisted so My Bookings survives restarts.
class Booking {
  final String id;
  final int venueId;
  final String venueName;
  final String coverImage;
  final DateTimeRangeDto dates;
  final int guests;
  final double total;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.coverImage,
    required this.dates,
    required this.guests,
    required this.total,
    required this.createdAt,
  });

  int get nights => dates.end.difference(dates.start).inDays.clamp(1, 365);

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'venueName': venueName,
        'coverImage': coverImage,
        'start': dates.start.toIso8601String(),
        'end': dates.end.toIso8601String(),
        'guests': guests,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        venueId: (json['venueId'] as num).toInt(),
        venueName: json['venueName']?.toString() ?? 'Venue',
        coverImage: json['coverImage']?.toString() ?? '',
        dates: DateTimeRangeDto(
          start: DateTime.parse(json['start'].toString()),
          end: DateTime.parse(json['end'].toString()),
        ),
        guests: (json['guests'] as num?)?.toInt() ?? 1,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class DateTimeRangeDto {
  final DateTime start;
  final DateTime end;
  const DateTimeRangeDto({required this.start, required this.end});
}

class BookingProvider extends ChangeNotifier {
  static const _key = 'bookings_v1';

  final List<Booking> _items = [];
  List<Booking> get items => List.unmodifiable(_items);
  int get count => _items.length;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (json.decode(raw) as List).whereType<Map>();
      _items
        ..clear()
        ..addAll(list.map(
            (e) => Booking.fromJson(Map<String, dynamic>.from(e))));
      notifyListeners();
    } catch (_) {
      // Corrupt cache: start fresh.
    }
  }

  Future<Booking> add({
    required int venueId,
    required String venueName,
    required String coverImage,
    required DateTime start,
    required DateTime end,
    required int guests,
    required double total,
  }) async {
    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      venueId: venueId,
      venueName: venueName,
      coverImage: coverImage,
      dates: DateTimeRangeDto(start: start, end: end),
      guests: guests,
      total: total,
      createdAt: DateTime.now(),
    );
    _items.insert(0, booking);
    notifyListeners();
    await _persist();
    return booking;
  }

  Future<void> cancel(String id) async {
    _items.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(_items.map((b) => b.toJson()).toList()));
  }
}
