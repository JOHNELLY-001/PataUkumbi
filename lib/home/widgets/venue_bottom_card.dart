import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../../services/cloudinary.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';
import '../../widgets/venue_page_details.dart';

/// White bottom-sheet preview: photo, name, area, price, View button.
class VenueBottomCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  const VenueBottomCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final gallery = (venue['gallery_images'] as List?) ?? [];
    final cover = venue['cover_image']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cover.isNotEmpty)
          Hero(
            tag: 'map-${venue['id']}',
            child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppTokens.radiusCard),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: cloudinaryThumb(cover),
                fit: BoxFit.cover,
                memCacheWidth: 800,
                errorWidget: (_, __, ___) => Container(
                  color: AppTokens.surfaceSecondary,
                  child: const Icon(AppIcons.imageBroken,
                      color: AppTokens.inkTertiary),
                ),
              ),
            ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          (venue['name']?.toString() ?? 'Unknown')
              .replaceAll('_', ' '),
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTokens.ink),
        ),
        const SizedBox(height: 2),
        Text(
          '${venue['ward'] ?? ''}, ${venue['district'] ?? ''}',
          style: const TextStyle(
              color: AppTokens.inkSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _priceLabel(venue),
                style: const TextStyle(
                    color: AppTokens.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(110, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () {
                  final id =
                      int.tryParse(venue['id']?.toString() ?? '');
                  Navigator.of(context).pop();
                  if (id != null) {
                    context.read<VenueProvider>().recordViewed(id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                      builder: (_) => VenueDetailPage(
                        venueId: id,
                        heroTag: 'map-$id',
                      ),
                      ),
                    );
                  }
                },
                child: const Text('View'),
              ),
            ),
          ],
        ),
        if (gallery.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length.clamp(0, 6),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = gallery[index]?.toString().trim() ?? '';
                if (!url.startsWith('http')) return const SizedBox.shrink();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                                      imageUrl:
                                          cloudinaryThumb(url,
                                              width: 400),
                                      width: 120,
                    height: 84,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 84,
                      color: AppTokens.surfaceSecondary,
                      child: const Icon(
                          AppIcons.imageBroken,
                          color: AppTokens.inkTertiary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _priceLabel(Map<String, dynamic> venue) {
    for (final key in ['pricing_per_day', 'pricing_per_hour']) {
      final raw =
          venue[key]?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
      final v = double.tryParse(raw);
      if (v == null) continue;
      final t = venue['pricing_type']?.toString().toLowerCase() ?? '';
      final suffix = t.contains('hour')
          ? ' / hour'
          : t.contains('day')
              ? ' / day'
              : ' / event';
      return 'TSh ${_short(v)}$suffix';
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
