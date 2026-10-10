import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/api_config.dart';

/// Booking storage abstraction (Phase 5).
///
/// Today everything is local ([LocalBookingRepository]); when the backend
/// ships a booking-request endpoint, add [ApiBookingRepository] here and
/// flip [BookingProvider] to it — screens stay untouched.
abstract class BookingRepository {
  Future<List<Booking>> load();
  Future<Booking> create({
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
  });
  Future<void> cancel(String id);
}

/// Time slots offered in the booking flow.
abstract final class BookingSlots {
  static const fullDay = 'Full day';
  static const morning = 'Morning';
  static const afternoon = 'Afternoon';
  static const evening = 'Evening';

  static const List<String> all = [fullDay, morning, afternoon, evening];

  /// Billable hours per partial slot (estimates only — host confirms).
  static const Map<String, int> hours = {
    morning: 4,
    afternoon: 5,
    evening: 6,
  };
}

/// A reservation request. Status is NEVER 'confirmed' locally — the host
/// (later: the server) confirms. Language rule: "Request to book".
class Booking {
  final String id;
  final int venueId;
  final String venueName;
  final String coverImage;
  final DateTimeRangeDto dates;
  final int guests;
  final double total;
  final DateTime createdAt;

  final String status;
  final String eventType;
  final String slot;
  final List<String> requirements;
  final String notes;
  final String contactName;
  final String contactPhone;
  final double deposit;

  Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.coverImage,
    required this.dates,
    required this.guests,
    required this.total,
    required this.createdAt,
    this.status = 'requested',
    this.eventType = '',
    this.slot = BookingSlots.fullDay,
    this.requirements = const [],
    this.notes = '',
    this.contactName = '',
    this.contactPhone = '',
    this.deposit = 0,
  });

  int get nights => dates.end.difference(dates.start).inDays.clamp(1, 365);

  Booking copyWith({String? status}) => Booking(
        id: id,
        venueId: venueId,
        venueName: venueName,
        coverImage: coverImage,
        dates: dates,
        guests: guests,
        total: total,
        createdAt: createdAt,
        status: status ?? this.status,
        eventType: eventType,
        slot: slot,
        requirements: requirements,
        notes: notes,
        contactName: contactName,
        contactPhone: contactPhone,
        deposit: deposit,
      );

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
        'status': status,
        'eventType': eventType,
        'slot': slot,
        'requirements': requirements,
        'notes': notes,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'deposit': deposit,
      };

  /// All new keys default — v1 bookings (pre-Phase-5 JSON) still parse.
  /// Numbers tolerate strings (Postgres NUMERIC decodes as String).
  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        venueId: _toInt(json['venueId']),
        venueName: json['venueName']?.toString() ?? 'Venue',
        coverImage: json['coverImage']?.toString() ?? '',
        dates: DateTimeRangeDto(
          start: DateTime.parse(json['start'].toString()),
          end: DateTime.parse(json['end'].toString()),
        ),
        guests: _toInt(json['guests'], fallback: 1),
        total: _toDouble(json['total']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: json['status']?.toString() ?? 'requested',
        eventType: json['eventType']?.toString() ?? '',
        slot: json['slot']?.toString() ?? BookingSlots.fullDay,
        requirements: (json['requirements'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        notes: json['notes']?.toString() ?? '',
        contactName: json['contactName']?.toString() ?? '',
        contactPhone: json['contactPhone']?.toString() ?? '',
        deposit: _toDouble(json['deposit']),
      );
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(
          v?.toString().replaceAll(RegExp(r'[^0-9.\-]'), '') ?? '') ??
      0;
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

class DateTimeRangeDto {
  final DateTime start;
  final DateTime end;
  const DateTimeRangeDto({required this.start, required this.end});
}

/// Today's implementation: JSON in SharedPreferences, no payment.
class LocalBookingRepository implements BookingRepository {
  static const _key = 'bookings_v1';

  @override
  Future<List<Booking>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (json.decode(raw) as List).whereType<Map>();
      return list
          .map((e) => Booking.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const []; // Corrupt cache: start fresh.
    }
  }

  @override
  Future<Booking> create({
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
    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      venueId: venueId,
      venueName: venueName,
      coverImage: coverImage,
      dates: DateTimeRangeDto(start: start, end: end),
      guests: guests,
      total: total,
      createdAt: DateTime.now(),
      status: 'requested',
      eventType: eventType,
      slot: slot,
      requirements: List.of(requirements),
      notes: notes,
      contactName: contactName,
      contactPhone: contactPhone,
      deposit: deposit,
    );
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    await prefs.setString(
        _key,
        json.encode(
            [booking, ...current].map((b) => b.toJson()).toList()));
    return booking;
  }

  @override
  Future<void> cancel(String id) async {
    // Cancelled stays visible (Past filter + status badge).
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = [
      for (final b in current)
        b.id == id ? b.copyWith(status: 'cancelled') : b
    ];
    await prefs.setString(
        _key, json.encode(updated.map((b) => b.toJson()).toList()));
  }
}

/// Server implementation (backend Workstream C). Maps snake_case rows
/// into [Booking]; server is source of truth (totals computed there).
class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;

  ApiBookingRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Booking _map(Map<String, dynamic> j) => Booking.fromJson({
        'id': j['id'],
        'venueId': j['venue_id'],
        'venueName': j['venue_name'] ?? 'Venue',
        'coverImage': j['venue_cover'] ?? '',
        'start': j['start_date'],
        'end': j['end_date'],
        'guests': j['guests'],
        'total': j['total'],
        'createdAt': j['created_at'] ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        'status': j['status'] ?? 'requested',
        'eventType': j['event_type'] ?? '',
        'slot': j['slot'] ?? BookingSlots.fullDay,
        'requirements': j['requirements'] ?? const [],
        'notes': j['notes'] ?? '',
        'contactName': j['contact_name'] ?? '',
        'contactPhone': j['contact_phone'] ?? '',
        'deposit': j['deposit'] ?? 0,
      });

  @override
  Future<List<Booking>> load() async {
    final data = await _client.getJson(ApiConfig.myBookings());
    final list = data is List
        ? data
        : (data is Map ? (data['data'] as List? ?? []) : []);
    return list
        .whereType<Map>()
        .map((e) => _map(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Booking> create({
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
    final data = await _client.postJson(ApiConfig.bookings(), {
      'venue_id': venueId,
      'event_type': eventType,
      'start_date': _date(start),
      'end_date': _date(end),
      'slot': slot,
      'guests': guests,
      'requirements': requirements,
      'notes': notes,
      'contact_name': contactName,
      'contact_phone': contactPhone,
    });
    final row = data is Map
        ? (data['data'] is Map ? data['data'] : data)
        : {};
    return _map(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> cancel(String id) async {
    await _client.patchJson(ApiConfig.cancelBooking(id), {});
  }
}

/// Mid-flow draft, auto-saved per venue so leaving and coming back
/// never loses anything (Phase 3 smart list).
class BookingDraft {
  String eventType;
  DateTime? start;
  DateTime? end;
  String slot;
  int guests;
  Set<String> requirements;
  String notes;
  String contactName;
  String contactPhone;

  BookingDraft({
    this.eventType = '',
    this.start,
    this.end,
    this.slot = BookingSlots.fullDay,
    this.guests = 2,
    Set<String>? requirements,
    this.notes = '',
    this.contactName = '',
    this.contactPhone = '',
  }) : requirements = requirements ?? <String>{};

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'start': start?.toIso8601String(),
        'end': end?.toIso8601String(),
        'slot': slot,
        'guests': guests,
        'requirements': requirements.toList(),
        'notes': notes,
        'contactName': contactName,
        'contactPhone': contactPhone,
      };

  factory BookingDraft.fromJson(Map<String, dynamic> json) =>
      BookingDraft(
        eventType: json['eventType']?.toString() ?? '',
        start: json['start'] == null
            ? null
            : DateTime.tryParse(json['start'].toString()),
        end: json['end'] == null
            ? null
            : DateTime.tryParse(json['end'].toString()),
        slot: json['slot']?.toString() ?? BookingSlots.fullDay,
        guests: (json['guests'] as num?)?.toInt() ?? 2,
        requirements: (json['requirements'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            <String>{},
        notes: json['notes']?.toString() ?? '',
        contactName: json['contactName']?.toString() ?? '',
        contactPhone: json['contactPhone']?.toString() ?? '',
      );
}

abstract final class DraftStore {
  static String _key(int venueId) => 'booking_draft_$venueId';

  static Future<BookingDraft?> load(int venueId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(venueId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return BookingDraft.fromJson(
          Map<String, dynamic>.from(json.decode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int venueId, BookingDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(venueId), json.encode(draft.toJson()));
  }

  static Future<void> clear(int venueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(venueId));
  }
}
