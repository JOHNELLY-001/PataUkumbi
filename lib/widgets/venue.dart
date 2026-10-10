class Venue {
  final int id;
  final int userId;

  final String name;
  final String venueType;
  final String description;

  final String district;
  final String ward;
  final String street;

  final double lat;
  final double lng;

  final int maxCapacity;
  final String spaceType;

  final bool parkingAvailable;
  final String pricingType;

  final double? pricingPerHour;
  final double? pricingPerDay;

  final String facilities;

  final String coverImage;
  final List<String> galleryImages;

  final String endEventTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Phase 4 — contact/location/policy fields. Backend does not send most
  // of these yet; every one defaults to '' so missing data never breaks UI.
  final String phone;
  final String whatsapp;
  final String landmark;
  final String restrictions;

  // Canonical event tags (backend event_types JSONB). Empty until tagged.
  final List<String> eventTypes;

  Venue({
    required this.id,
    required this.userId,
    required this.name,
    required this.venueType,
    required this.description,
    required this.district,
    required this.ward,
    required this.street,
    required this.lat,
    required this.lng,
    required this.maxCapacity,
    required this.spaceType,
    required this.parkingAvailable,
    required this.pricingType,
    this.pricingPerHour,
    this.pricingPerDay,
    required this.facilities,
    required this.coverImage,
    required this.galleryImages,
    required this.endEventTime,
    required this.createdAt,
    required this.updatedAt,
    this.phone = '',
    this.whatsapp = '',
    this.landmark = '',
    this.restrictions = '',
    this.eventTypes = const [],
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,

      name: json['name']?.toString() ?? 'Unnamed venue',
      venueType: json['venue_type']?.toString() ?? 'unknown',
      description: json['description']?.toString() ?? '',

      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      street: json['street']?.toString() ?? '',

      lat: _asDouble(json['lat']) ?? -6.8,
      lng: _asDouble(json['lng']) ?? 39.28,

      maxCapacity: _asInt(json['max_capacity']) ?? 0,
      spaceType: json['space_type']?.toString() ?? '',

      parkingAvailable: _asBool(json['parking_available']),
      pricingType: json['pricing_type']?.toString() ?? 'unknown',

      pricingPerHour: _asDouble(json['pricing_per_hour']),

      pricingPerDay: _asDouble(json['pricing_per_day']),

      facilities: _asFacilities(json['facilities']),

      coverImage: json['cover_image']?.toString() ?? '',
      galleryImages: _asStringList(json['gallery_images'] ?? json['galleryImages']),

      endEventTime: json['end_event_time']?.toString() ?? '',
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      phone: json['phone']?.toString().trim() ??
          json['contact_phone']?.toString().trim() ??
          '',
      whatsapp: json['whatsapp']?.toString().trim() ??
          json['whatsapp_number']?.toString().trim() ??
          '',
      landmark: json['landmark']?.toString().trim() ?? '',
      restrictions: json['restrictions_policies']?.toString().trim() ??
          json['restrictions']?.toString().trim() ??
          json['policies']?.toString().trim() ??
          '',
      eventTypes: _asEventTypes(json['event_types']),
    );
  }

  static List<String> _asEventTypes(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      final s = v.trim();
      if (s.startsWith('[')) return _asStringList(s);
      return s
          .split(RegExp(r'[,;\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// "Good for" event chips. Tagged venues use their backend event_types;
  /// untagged fall back to the capacity heuristic.
  List<String> get goodFor {
    if (eventTypes.isNotEmpty) return eventTypes.take(4).toList();
    final chips = <String>[];
    if (maxCapacity >= 250) {
      chips.addAll(['Weddings', 'Conferences', 'Corporate']);
    } else if (maxCapacity >= 80) {
      chips.addAll(['Parties', 'Graduations', 'Corporate']);
    } else if (maxCapacity > 0) {
      chips.addAll(['Birthdays', 'Meetups']);
    } else {
      chips.addAll(['Parties', 'Meetups']);
    }
    if (facilities.toLowerCase().contains('wifi') &&
        !chips.contains('Workshops')) {
      chips.add('Workshops');
    }
    return chips;
  }

  /// Digits (and leading +) only — for tel:/wa.me links.
  static String dialable(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.startsWith('+') ? digits : digits;
  }

  String get priceLabel {
    if (pricingType == 'hour' && pricingPerHour != null) {
      return 'TZS ${pricingPerHour!.toStringAsFixed(0)} / hour';
    }
    if (pricingType == 'day' && pricingPerDay != null) {
      return 'TZS ${pricingPerDay!.toStringAsFixed(0)} / day';
    }
    if (pricingType == 'both') {
      return 'From TZS ${pricingPerHour?.toStringAsFixed(0) ?? '-'}';
    }
    return 'Pricing unavailable';
  }
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  // Admin may save "250,000" or "TSh 250k" — extract numeric part.
  final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
  return double.tryParse(cleaned);
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final d = _asDouble(v);
  return d?.toInt();
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return const [];
    // Backend may store JSON-encoded array as text.
    if (s.startsWith('[')) {
      try {
        // Minimal parse without dart:convert dependency issues in compute:
        // strip brackets/quotes and split.
        final inner = s.substring(1, s.length - 1);
        return inner
            .split(',')
            .map((e) => e.trim().replaceAll(RegExp('^["\']|["\']\$'), ''))
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return const [];
      }
    }
    // Split on whitespace too: backend sometimes space-separates gallery URLs.
    return s.split(RegExp(r'[\s,;\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty && e.startsWith('http')).toList();
  }
  return const [];
}

String _asFacilities(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is List) return v.map((e) => e.toString()).where((e) => e.isNotEmpty).join(', ');
  return v.toString();
}

DateTime _asDate(dynamic v) {
  try {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.parse(v.toString());
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
