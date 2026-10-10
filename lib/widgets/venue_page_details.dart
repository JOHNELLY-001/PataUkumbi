import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../providers/saved_provider.dart';
import '../services/venue_service.dart';
import '../theme/tokens.dart';
import 'booking_sheet.dart';

class VenueDetailPage extends StatefulWidget {
  final int venueId;
  final String heroTag;

  const VenueDetailPage(
      {super.key, required this.venueId, required this.heroTag});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  final PageController _galleryController =
      PageController(viewportFraction: 0.92);
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = VenueService.fetchVenueById(widget.venueId);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  void _openBooking(Map<String, dynamic> v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: BookingSheet(venue: v),
      ),
    ).then((booked) {
      if (booked == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed 🎉')),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        context.watch<SavedProvider>().isSaved(widget.venueId);
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
          final gallery =
              (v['gallery_images'] as List? ?? []).take(6).toList();
          final nightly = _nightlyRate(v);

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
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: AppTokens.ink),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: saved
                                  ? AppTokens.coral
                                  : AppTokens.ink,
                            ),
                            onPressed: () => context
                                .read<SavedProvider>()
                                .toggle(widget.venueId),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: widget.heroTag,
                        child: CachedNetworkImage(
                          imageUrl:
                              v['cover_image']?.toString() ?? '',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppTokens.bgSecondary),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTokens.bgSecondary,
                            child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTokens.inkTertiary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            (v['name']?.toString() ?? 'Venue')
                                .replaceAll('_', ' '),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTokens.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${v['venue_type'] ?? ''} · ${v['ward'] ?? ''}, ${v['district'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppTokens.inkSecondary),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _AmenityGrid(venue: v),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
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
                          if (gallery.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Photos',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.ink)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                controller: _galleryController,
                                itemCount: gallery.length,
                                itemBuilder: (context, index) =>
                                    Container(
                                  margin: const EdgeInsets.only(
                                      right: 8),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: gallery[index]
                                          .toString(),
                                      fit: BoxFit.cover,
                                      memCacheWidth: 700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SmoothPageIndicator(
                                controller: _galleryController,
                                count: gallery.length,
                                effect: const WormEffect(
                                  dotHeight: 7,
                                  dotWidth: 7,
                                  activeDotColor: AppTokens.ink,
                                  dotColor: AppTokens.border,
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: AppTokens.border)),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink)),
                            const Text('per night',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTokens.inkSecondary)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 48),
                          ),
                          onPressed: () => _openBooking(v),
                          child: const Text('Reserve'),
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

  String _nightlyRate(Map<String, dynamic> v) {
    for (final key in ['pricing_per_day', 'pricing_per_hour']) {
      final raw = v[key]?.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final value = double.tryParse(raw ?? '');
      if (value != null) return 'TSh ${_short(value)}';
    }
    return 'See prices';
  }

  String _short(double value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k % 1 == 0 ? k.toInt() : k}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _AmenityGrid extends StatelessWidget {
  final Map<String, dynamic> venue;
  const _AmenityGrid({required this.venue});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.people_outline_rounded,
          '${venue['max_capacity'] ?? '–'} guests'),
      (Icons.meeting_room_outlined,
          (venue['space_type']?.toString() ?? 'Flexible space')),
      if (venue['parking_available'] == true)
        (Icons.local_parking_outlined, 'Free parking'),
      (Icons.schedule_outlined,
          'Until ${venue['end_event_time'] ?? 'late'}'),
      (Icons.wifi_rounded, 'Fast wifi'),
      (Icons.restaurant_outlined, 'Catering friendly'),
    ].take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 40,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Row(
        children: [
          const SizedBox(width: 2),
          Icon(items[i].$1, size: 20, color: AppTokens.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(items[i].$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppTokens.ink)),
          ),
        ],
      ),
    );
  }
}
