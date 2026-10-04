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

      facilities: json['facilities']?.toString() ?? '',

      coverImage: json['cover_image']?.toString() ?? '',
      galleryImages: _asStringList(json['gallery_images']),

      endEventTime: json['end_event_time']?.toString() ?? '',
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
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
  return double.tryParse(v.toString());
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
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
  return const [];
}

DateTime _asDate(dynamic v) {
  try {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.parse(v.toString());
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
