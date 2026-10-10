import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/saved_provider.dart';
import '../providers/venue_provider.dart';
import '../services/cloudinary.dart';
import '../services/venue_service.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';
import '../booking/booking_flow_page.dart';
import 'venue.dart';

class VenueDetailPage extends StatefulWidget {
  final int venueId;
  final String heroTag;

  const VenueDetailPage(
      {super.key, required this.venueId, required this.heroTag});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  // TODO(backend): hardcoded demo extras until ratings/host APIs exist.
  // Keep them in one labeled block so they read as placeholders.
  static const _demoRating = '4.9';
  static const _demoReviews = '128 reviews';
  static const _demoHostName = 'Serena Hospitality Group';
  static const _demoHostMeta = 'Premier Luxury Partner • 8 yrs hosting';

  final PageController _heroController = PageController();
  late Future<Map<String, dynamic>> _future;
  bool _showAllAmenities = false;
  int _heroPage = 0;

  @override
  void initState() {
    super.initState();
    _future = VenueService.fetchVenueById(widget.venueId);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _openBooking(Map<String, dynamic> v) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingFlowPage(venue: v),
      ),
    );
  }

  void _openGallery(List<String> photos, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullscreenGallery(photos: photos, initialIndex: index),
      ),
    );
  }

  Future<void> _shareVenue(Map<String, dynamic> v) async {
    final name =
        (v['name']?.toString() ?? 'Venue').replaceAll('_', ' ');
    final area = _address(v);
    await SharePlus.instance.share(ShareParams(
        text:
            '$name — ${area.isNotEmpty ? area : 'Dar es Salaam'} on Haven'));
  }

  Future<void> _openExternal(Uri uri, String failMessage) async {
    try {
      final ok = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) AppSnack.error(context, failMessage);
    } catch (_) {
      if (mounted) AppSnack.error(context, failMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        context.watch<SavedProvider>().isSaved(widget.venueId);
    final filters = context.watch<VenueProvider>();
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load this venue.',
                        style:
                            TextStyle(color: AppTokens.inkSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _future = VenueService.fetchVenueById(
                            widget.venueId);
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final v = snapshot.data!;
          final model =
              Venue.fromJson(Map<String, dynamic>.from(v));
          final photos = _photos(v);
          final nightly = _nightlyRate(v);
          final perLabel = _perLabel(v);
          final facilities = _facilityList(v);
          final policies = _policyList(model.restrictions);
          final address = _address(v);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: AppTokens.bg,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: AppTokens.surface,
                        child: IconButton(
                          tooltip: 'Back',
                          icon: const Icon(AppIcons.back,
                              color: AppTokens.ink),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 4, 8),
                        child: CircleAvatar(
                          backgroundColor: AppTokens.surface,
                          child: IconButton(
                            tooltip: 'Share venue',
                            icon: const Icon(AppIcons.share,
                                color: AppTokens.ink,
                                size: 20),
                            onPressed: () => _shareVenue(v),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        child: CircleAvatar(
                          backgroundColor: AppTokens.surface,
                          child: FavoriteButton(
                            saved: saved,
                            idleColor: AppTokens.ink,
                            iconSize: 24,
                            onToggle: (_) => context
                                .read<SavedProvider>()
                                .toggle(widget.venueId),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: photos.isEmpty
                          ? Container(
                              color: AppTokens.surfaceSecondary,
                              child: const Icon(
                                  AppIcons.imageBroken,
                                  size: 64,
                                  color: AppTokens.inkTertiary),
                            )
                          : GestureDetector(
                              onTap: () => _openGallery(photos, 0),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  PageView.builder(
                                    controller: _heroController,
                                    itemCount: photos.length,
                                    onPageChanged: (i) => setState(
                                        () => _heroPage = i),
                                    itemBuilder: (context, i) =>
                                        GestureDetector(
                                      onTap: () =>
                                          _openGallery(photos, i),
                                      child: _heroPhoto(
                                          photos[i], i),
                                    ),
                                  ),
                                  const Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 120,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment
                                              .topCenter,
                                          end: Alignment
                                              .bottomCenter,
                                          colors: [
                                            Color(0x66000000),
                                            Colors.transparent
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 16,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(
                                                alpha: 0.6),
                                        borderRadius:
                                            BorderRadius.circular(
                                                16),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              AppIcons.gallery,
                                              size: 13,
                                              color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                              '${_heroPage + 1} / ${photos.length}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (photos.length > 1)
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: SmoothPageIndicator(
                                          controller:
                                              _heroController,
                                          count: photos.length,
                                          effect:
                                              const WormEffect(
                                            dotHeight: 7,
                                            dotWidth: 7,
                                            activeDotColor:
                                                Colors.white,
                                            dotColor:
                                                Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTokens.primaryTint,
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        AppIcons.verified,
                                        size: 13,
                                        color:
                                            AppTokens.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified ${(v['venue_type']?.toString() ?? 'venue').replaceAll('_', ' ')}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: AppTokens.ink),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '• ${v['ward'] ?? ''}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTokens
                                          .inkSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (v['name']?.toString() ?? 'Venue')
                                .replaceAll('_', ' '),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              const Icon(AppIcons.star,
                                  size: 16,
                                  color: AppTokens.primary),
                              const Text(_demoRating,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: AppTokens.ink)),
                              const Text(
                                '($_demoReviews)',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTokens
                                        .inkSecondary,
                                    decoration: TextDecoration
                                        .underline),
                              ),
                              const Text('•',
                                  style: TextStyle(
                                      color: AppTokens.border)),
                              const Icon(AppIcons.location,
                                  size: 16,
                                  color: AppTokens.primary),
                              Text(
                                _headerLocation(v, model),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTokens
                                        .inkSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _HostSnippet(venue: model),
                          const SizedBox(height: 12),
                          _FactBadges(venue: model),
                          const SizedBox(height: 16),
                          const Text('About this space',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink)),
                          const SizedBox(height: 6),
                          Text(
                            v['description']?.toString().isNotEmpty ==
                                    true
                                ? v['description'].toString()
                                : 'A well-kept space for weddings, conferences and celebrations. Contact the host for a tour.',
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppTokens.ink),
                          ),
                          if (model.goodFor.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 0,
                              children: [
                                for (final g in model.goodFor)
                                  AppChip(
                                    label: g,
                                    selected:
                                        filters.eventType ==
                                            g,
                                    onTap: () {
                                      filters.setEventType(g);
                                      AppSnack.info(context,
                                          'Explore filter set to $g');
                                    },
                                  ),
                              ],
                            ),
                          ],
                          if (facilities.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SectionHeader(
                              title: 'What this venue offers',
                              actionLabel:
                                  facilities.length > 4
                                      ? (_showAllAmenities
                                          ? 'Show less'
                                          : 'All ${facilities.length}')
                                      : null,
                              onAction: () => setState(() =>
                                  _showAllAmenities =
                                      !_showAllAmenities),
                            ),
                            const SizedBox(height: 8),
                            _AmenityCards(
                              facilities: facilities,
                              expanded: _showAllAmenities,
                            ),
                          ],
                          if (policies.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Policies & Inclusions',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.ink)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTokens.surface,
                                borderRadius:
                                    BorderRadius.circular(
                                        AppTokens.radiusCard),
                                border: Border.all(
                                    color: AppTokens.border),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < policies.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(height: 24),
                                    _PolicyRow(text: policies[i]),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text('Where you’ll celebrate',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink)),
                          if (address.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 2, bottom: 8),
                              child: Text(address,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          AppTokens.inkSecondary)),
                            ),
                          if (address.isEmpty)
                            const SizedBox(height: 8),
                          if (_miniMapSupported &&
                              model.lat.isFinite &&
                              model.lng.isFinite)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.radiusCard),
                              child: SizedBox(
                                height: 170,
                                child: GoogleMap(
                                  initialCameraPosition:
                                      CameraPosition(
                                    target: LatLng(
                                        model.lat, model.lng),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId(
                                          'venue'),
                                      position: LatLng(
                                          model.lat,
                                          model.lng),
                                    ),
                                  },
                                  liteModeEnabled: true,
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Get directions',
                            variant: AppButtonVariant.secondary,
                            height: 44,
                            onPressed: (model.lat.isFinite &&
                                    model.lng.isFinite)
                                ? () => _openExternal(
                                      Uri.parse(
                                          'https://www.google.com/maps/dir/?api=1&destination=${model.lat},${model.lng}'),
                                      'Could not open Maps.',
                                    )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('Contact host',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink)),
                          const SizedBox(height: 8),
                          _HostCard(venue: model),
                          if (photos.length > 1) ...[
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(
                                  child: Text('Venue Gallery',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: AppTokens.ink)),
                                ),
                                Text('Swipe to explore',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTokens
                                            .inkSecondary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 170,
                              child: ListView.separated(
                                scrollDirection:
                                    Axis.horizontal,
                                itemCount: photos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder:
                                    (context, index) =>
                                        GestureDetector(
                                  onTap: () => _openGallery(
                                      photos, index),
                                  child: Container(
                                    width: 260,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      border: Border.all(
                                          color: AppTokens
                                              .border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                              16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl:
                                                cloudinaryThumb(
                                                    photos[
                                                        index],
                                                    width: 700),
                                            fit: BoxFit.cover,
                                            memCacheWidth: 700,
                                            errorWidget: (_,
                                                    __,
                                                    ___) =>
                                                Container(
                                              color: AppTokens
                                                  .surfaceSecondary,
                                              child: const Icon(
                                                  AppIcons
                                                      .imageBroken,
                                                  color: AppTokens
                                                      .inkTertiary),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                          horizontal:
                                                              8,
                                                          vertical:
                                                              4),
                                              decoration:
                                                  BoxDecoration(
                                                color: Colors
                                                    .black
                                                    .withValues(
                                                        alpha:
                                                            0.6),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            8),
                                              ),
                                              child: Text(
                                                  'Photo ${index + 1}',
                                                  style: const TextStyle(
                                                      color: Colors
                                                          .white,
                                                      fontSize:
                                                          11,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppTokens.surface,
                    border: Border(
                        top: BorderSide(
                            color: AppTokens.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(nightly,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink)),
                            Row(
                              children: [
                                const Icon(
                                    AppIcons.calendarCheck,
                                    size: 13,
                                    color: AppTokens.success),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                      _estimateContext(
                                          filters,
                                          perLabel),
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: AppTokens
                                              .success)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(190, 48),
                          ),
                          onPressed: () => _openBooking(v),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Reserve Venue'),
                              SizedBox(width: 6),
                              Icon(AppIcons.forward,
                                  size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _miniMapSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Detail side of the Hero flight. Only page 0 participates: every
  /// list uses a unique tag per tab (explore-/saved-/viewed-/map-id),
  /// so the IndexedStack never holds duplicates — the old shared-tag
  /// crash. Popping while swiped past page 0 simply fades.
  Widget _heroPhoto(String url, int index) {
    final img = CachedNetworkImage(
      imageUrl: cloudinaryThumb(url, width: 1200),
      fit: BoxFit.cover,
      memCacheWidth: 1000,
      placeholder: (_, __) =>
          Container(color: AppTokens.surfaceSecondary),
      errorWidget: (_, __, ___) => Container(
        color: AppTokens.surfaceSecondary,
        child: const Icon(AppIcons.imageBroken,
            size: 64, color: AppTokens.inkTertiary),
      ),
    );
    if (index == 0) {
      return Hero(tag: widget.heroTag, child: img);
    }
    return img;
  }

  /// Hero + gallery: only valid http(s) URLs — empty/garbage strings
  /// caused ImageCodecException during page transitions.
  List<String> _photos(Map<String, dynamic> v) {
    bool valid(dynamic e) {
      final s = e?.toString().trim() ?? '';
      return s.startsWith('http://') || s.startsWith('https://');
    }

    final out = <String>[];
    final cover = v['cover_image']?.toString().trim() ?? '';
    if (valid(cover)) out.add(cover);
    final gallery = v['gallery_images'];
    final items = gallery is List
        ? gallery.where(valid).map((e) => e.toString().trim())
        : (gallery is String
            ? gallery
                .split(RegExp(r'[\s,;\n]+'))
                .map((e) => e.trim())
                .where(valid)
            : <String>[]);
    for (final url in items) {
      if (out.length >= 6) break;
      if (!out.contains(url)) out.add(url);
    }
    return out;
  }

  String _nightlyRate(Map<String, dynamic> v) {
    for (final key in ['pricing_per_day', 'pricing_per_hour']) {
      final raw = v[key]?.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final value = double.tryParse(raw ?? '');
      if (value != null) return 'TSh ${PriceText.compact(value)}';
    }
    return 'See prices';
  }

  String _perLabel(Map<String, dynamic> v) {
    final t = v['pricing_type']?.toString().toLowerCase() ?? '';
    if (t.contains('hour')) return 'per hour';
    if (t.contains('day')) return 'per day';
    if (t.contains('both')) return 'per event';
    return 'per event';
  }

  /// "per event · 150 guests · Fri, 12 Jun" — reflects Explore filters
  /// when the user set them, so the bar feels live.
  String _estimateContext(VenueProvider filters, String perLabel) {
    final parts = <String>[perLabel];
    if (filters.guestsSet) parts.add('${filters.guests} guests');
    if (filters.eventDate != null) {
      parts.add(DateFormat('EEE, d MMM').format(filters.eventDate!));
    }
    return parts.join(' · ');
  }

  String _address(Map<String, dynamic> v) {
    return [
      v['street']?.toString().trim() ?? '',
      v['ward']?.toString().trim() ?? '',
      v['district']?.toString().trim() ?? '',
    ].where((e) => e.isNotEmpty).join(', ');
  }

  /// Header location line with landmark suffix ("(near Slipway)").
  String _headerLocation(Map<String, dynamic> v, Venue model) {
    final base = [
      v['ward']?.toString().trim() ?? '',
      v['district']?.toString().trim() ?? '',
    ].where((e) => e.isNotEmpty).join(', ');
    final landmark = model.landmark.trim();
    if (base.isEmpty) return landmark;
    if (landmark.isEmpty) return base;
    return '$base (near $landmark)';
  }

  List<String> _facilityList(Map<String, dynamic> v) {
    final raw = v['facilities']?.toString().trim() ?? '';
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[,;•\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _policyList(String restrictions) {
    final raw = restrictions.trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[•\n;]+'))
        .map((e) => e.trim().replaceAll(RegExp(r'\.+$'), ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// Host snippet under the header: avatar, hardcoded host identity,
/// chat shortcut into WhatsApp when a number exists.
class _HostSnippet extends StatelessWidget {
  final Venue venue;
  const _HostSnippet({required this.venue});

  @override
  Widget build(BuildContext context) {
    final phone =
        venue.phone.isNotEmpty ? venue.phone : venue.whatsapp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTokens.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.profile,
                color: AppTokens.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    // TODO(backend): hardcoded until host APIs exist.
                    _VenueDetailPageState._demoHostName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink)),
                Text(
                    _VenueDetailPageState._demoHostMeta,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.inkSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Contact host',
            onPressed: phone.isEmpty
                ? () => AppSnack.info(context,
                    'The host adds contact details soon.')
                : () => _openWhatsapp(context, venue, phone),
            icon: const Icon(AppIcons.chat,
                size: 20, color: AppTokens.primary),
          ),
        ],
      ),
    );
  }

  static Future<void> _openWhatsapp(
      BuildContext context, Venue venue, String phone) async {
    final name = venue.name.replaceAll('_', ' ');
    final uri = Uri.parse(
        'https://wa.me/${Venue.dialable(phone)}?text=${Uri.encodeComponent('Hi! Is "$name" available for my event?')}');
    try {
      final ok = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnack.error(context, 'Could not open WhatsApp.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.error(context, 'Could not open WhatsApp.');
      }
    }
  }
}

/// Three spec badges: capacity, space type, district zone.
class _FactBadges extends StatelessWidget {
  final Venue venue;
  const _FactBadges({required this.venue});

  @override
  Widget build(BuildContext context) {
    final v = venue;
    final badges = <(IconData, String, String)>[
      (
        AppIcons.capacity,
        v.maxCapacity > 0 ? '${v.maxCapacity}' : '–',
        'Max Capacity'
      ),
      (
        AppIcons.room,
        v.spaceType.isNotEmpty ? v.spaceType : 'Flexible',
        'Space Type'
      ),
      (
        AppIcons.building,
        v.district.isNotEmpty ? v.district : 'Dar',
        'Prime Zone'
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTokens.border),
              ),
              child: Column(
                children: [
                  Icon(badges[i].$1,
                      size: 22, color: AppTokens.primary),
                  const SizedBox(height: 4),
                  Text(badges[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink)),
                  Text(badges[i].$3,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTokens.inkSecondary)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Amenity cards with coral icon tiles (spec). Icons by keyword.
class _AmenityCards extends StatelessWidget {
  final List<String> facilities;
  final bool expanded;
  const _AmenityCards({required this.facilities, required this.expanded});

  static IconData _iconFor(String facility) {
    final f = facility.toLowerCase();
    if (f.contains('wifi')) return AppIcons.wifi;
    if (f.contains('park')) return AppIcons.parking;
    if (f.contains('stage') ||
        f.contains('sound') ||
        f.contains('mic')) {
      return AppIcons.soundEq;
    }
    if (f.contains('power') ||
        f.contains('generator') ||
        f.contains('backup')) {
      return AppIcons.generator;
    }
    if (f.contains('cater') ||
        f.contains('food') ||
        f.contains('bar') ||
        f.contains('kitchen')) {
      return AppIcons.catering;
    }
    if (f.contains('ac') ||
        f.contains('air') ||
        f.contains('cool') ||
        f.contains('chill')) {
      return AppIcons.ac;
    }
    return AppIcons.checkCircle;
  }

  @override
  Widget build(BuildContext context) {
    final items = expanded ? facilities : facilities.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 64,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTokens.border),
          boxShadow: AppTokens.shadowCard,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconFor(items[i]),
                  size: 19, color: AppTokens.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(items[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Policy row: tinted icon tile + bold title (spec).
class _PolicyRow extends StatelessWidget {
  final String text;
  const _PolicyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = text.toLowerCase();
    final IconData icon;
    final Color color;
    if (t.contains('clean')) {
      icon = AppIcons.checkCircle;
      color = AppTokens.success;
    } else if (t.contains('secur') || t.contains('safe')) {
      icon = AppIcons.shield;
      color = AppTokens.secondary;
    } else if (t.contains('time') ||
        t.contains('curfew') ||
        t.contains('pm') ||
        t.contains('am') ||
        t.contains(':')) {
      icon = AppIcons.clock;
      color = AppTokens.primary;
    } else {
      icon = AppIcons.info;
      color = AppTokens.inkSecondary;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTokens.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppTokens.ink)),
          ),
        ),
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  final Venue venue;
  const _HostCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final phone = venue.phone.isNotEmpty
        ? venue.phone
        : venue.whatsapp;
    final hasContact = phone.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTokens.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.profile,
                    color: AppTokens.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hosted by the venue team',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink)),
                    Text(
                      hasContact
                          ? phone
                          : 'Direct calling & WhatsApp appear here once the host adds a number.',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTokens.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasContact) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Call',
                    height: 44,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _call(context, phone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'WhatsApp',
                    height: 44,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        _whatsapp(context, venue, phone),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:${Venue.dialable(phone)}');
    try {
      final ok = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnack.error(context, 'Could not start the call app.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.error(context, 'Could not start the call app.');
      }
    }
  }

  Future<void> _whatsapp(
      BuildContext context, Venue venue, String phone) async {
    final name = venue.name.replaceAll('_', ' ');
    final uri = Uri.parse(
        'https://wa.me/${Venue.dialable(phone)}?text=${Uri.encodeComponent('Hi! Is "$name" available for my event?')}');
    try {
      final ok = await launchUrl(uri,
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnack.error(context, 'Could not open WhatsApp.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.error(context, 'Could not open WhatsApp.');
      }
    }
  }
}

/// Full-screen photo viewer: swipe + pinch zoom, counter, close.
class _FullscreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const _FullscreenGallery(
      {required this.photos, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pc =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl:
                        cloudinaryThumb(widget.photos[i], width: 1600),
                    fit: BoxFit.contain,
                    memCacheWidth: 1200,
                    placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white)),
                    errorWidget: (_, __, ___) => const Icon(
                        AppIcons.imageBroken,
                        size: 64,
                        color: Colors.white38),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(AppIcons.back,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text('${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _pc,
                    count: widget.photos.length,
                    effect: const WormEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white38,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
