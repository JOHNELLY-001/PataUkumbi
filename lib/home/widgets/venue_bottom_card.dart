import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/venuePageDetails.dart';

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
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppTokens.radiusCard),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                memCacheWidth: 800,
                errorWidget: (_, __, ___) => Container(
                  color: AppTokens.bgSecondary,
                  child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTokens.inkTertiary),
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
                venue['pricing_per_hour'] != null
                    ? 'TSh ${venue['pricing_per_hour']} / night'
                    : 'See prices',
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VenueDetailPage(
                          venueId: id,
                          heroTag: 'venue-$id',
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
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: gallery[index].toString(),
                  width: 120,
                  height: 84,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
