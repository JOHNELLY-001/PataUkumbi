import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../booking/booking_flow_page.dart';
import '../../providers/saved_provider.dart';
import '../../providers/venue_provider.dart';
import '../../services/cloudinary.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';
import '../../widgets/venue.dart';
import '../../widgets/venue_page_details.dart';

/// Coastal venue card: white 16px card, 16:10 swipeable photo, capacity
/// pill overlay, fit badge, name + location, price row + Quick Reserve.
/// Data logic (pagination model, saved, viewed, fit) is unchanged.
class VenueTile extends StatefulWidget {
  final Venue venue;

  /// Prefixes the Hero tag so Explore/Saved lists (both KeepAlive in
  /// the same IndexedStack) never share tags for the same venue.
  final String heroPrefix;

  const VenueTile({super.key, required this.venue, this.heroPrefix = 'explore'});

  @override
  State<VenueTile> createState() => _VenueTileState();
}

class _VenueTileState extends State<VenueTile> {
  late final PageController _gallery = PageController();

  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  void _openDetail() {
    final venue = widget.venue;
    context.read<VenueProvider>().recordViewed(venue.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailPage(
          venueId: venue.id,
          heroTag: '${widget.heroPrefix}-${venue.id}',
        ),
      ),
    );
  }

  void _quickReserve() {
    final venue = widget.venue;
    context.read<VenueProvider>().recordViewed(venue.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFlowPage(venue: {
          'id': venue.id,
          'name': venue.name,
          'cover_image': venue.coverImage,
          'pricing_per_day': venue.pricingPerDay,
          'pricing_per_hour': venue.pricingPerHour,
          'pricing_type': venue.pricingType,
          'max_capacity': venue.maxCapacity,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final saved = context.watch<SavedProvider>().isSaved(venue.id);
    final venues = context.watch<VenueProvider>();
    final showFit = venues.guestsSet;
    final fits = venues.fitsGuests(venue);
    final photos = _photos(venue);

    final card = Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: '${widget.heroPrefix}-${venue.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTokens.radiusCard)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: photos.isEmpty
                        ? Container(
                            color: AppTokens.surfaceSecondary,
                            child: const Icon(AppIcons.imageBroken,
                                size: 48,
                                color: AppTokens.inkTertiary),
                          )
                        : PageView.builder(
                            controller: _gallery,
                            itemCount: photos.length,
                            itemBuilder: (context, i) =>
                                CachedNetworkImage(
                              imageUrl:
                                  cloudinaryThumb(photos[i]),
                              fit: BoxFit.cover,
                              memCacheWidth: 800,
                              placeholder: (_, __) =>
                                  const SkeletonBox(
                                width: double.infinity,
                                height: double.infinity,
                                radius: 0,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTokens.surfaceSecondary,
                                child: const Icon(
                                    AppIcons.imageBroken,
                                    size: 48,
                                    color: AppTokens.inkTertiary),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (photos.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _gallery,
                      count: photos.length,
                      effect: const WormEffect(
                        dotHeight: 6,
                        dotWidth: 6,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white60,
                      ),
                    ),
                  ),
                ),
              if (showFit)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _FitBadge(
                    fits: fits,
                    guests: venues.guests,
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppTokens.shadowCard,
                  ),
                  child: Center(
                    child: FavoriteButton(
                      saved: saved,
                      iconSize: 24,
                      idleColor: AppTokens.ink,
                      onToggle: (_) => context
                          .read<SavedProvider>()
                          .toggle(venue.id),
                    ),
                  ),
                ),
              ),
              if (venue.maxCapacity > 0)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.guests,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Up to ${venue.maxCapacity} guests',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(AppIcons.location,
                        size: 15,
                        color: AppTokens.inkTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationLine(venue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTokens.inkSecondary),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Builder(builder: (_) {
                      final value = venue.pricingPerDay ??
                          venue.pricingPerHour;
                      if (value == null) {
                        return const Text('See prices',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink));
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PriceText(value, fontSize: 14),
                          Text(
                            _perSuffix(venue),
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    AppTokens.inkSecondary),
                          ),
                        ],
                      );
                    }),
                    const Spacer(),
                    GestureDetector(
                      onTap: _quickReserve,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTokens.surfaceSecondary,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Quick Reserve',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.ink)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: _openDetail,
      child: showFit && !fits ? Opacity(opacity: 0.55, child: card) : card,
    );
  }

  List<String> _photos(Venue venue) {
    final out = <String>[];
    if (venue.coverImage.trim().isNotEmpty) {
      out.add(venue.coverImage.trim());
    }
    for (final g in venue.galleryImages) {
      if (out.length >= 4) break;
      final url = g.trim();
      if (url.startsWith('http') && !out.contains(url)) out.add(url);
    }
    return out;
  }

  String _locationLine(Venue venue) {
    final parts = [venue.ward.trim(), venue.district.trim()]
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Dar es Salaam';
    return parts.join(', ');
  }

  String _perSuffix(Venue venue) {
    final t = venue.pricingType.toLowerCase();
    if (t.contains('hour')) return ' / hour';
    if (t.contains('day')) return ' / day';
    return '';
  }
}

class _FitBadge extends StatelessWidget {
  final bool fits;
  final int guests;
  const _FitBadge({required this.fits, required this.guests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fits
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        fits ? 'Fits $guests guests' : 'Too small for $guests',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fits ? AppTokens.success : AppTokens.error,
        ),
      ),
    );
  }
}
