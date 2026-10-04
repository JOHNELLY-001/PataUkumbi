import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/saved_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/venue.dart';
import '../../widgets/venuePageDetails.dart';

/// Airbnb-style row: photo with heart, name, rating line, price only.
class VenueTile extends StatelessWidget {
  final Venue venue;

  const VenueTile({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>().isSaved(venue.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VenueDetailPage(
              venueId: venue.id,
              heroTag: 'venue-${venue.id}',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTokens.radiusCard),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: venue.coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: venue.coverImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) => Container(
                                color: AppTokens.bgSecondary),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTokens.bgSecondary,
                              child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppTokens.inkTertiary),
                            ),
                          )
                        : Container(
                            color: AppTokens.bgSecondary,
                            child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTokens.inkTertiary),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        context.read<SavedProvider>().toggle(venue.id),
                    child: Icon(
                      saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: saved ? AppTokens.coral : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    venue.name.replaceAll('_', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink),
                  ),
                ),
                const Icon(Icons.star_rounded,
                    size: 16, color: AppTokens.ink),
                const SizedBox(width: 2),
                const Text('New',
                    style: TextStyle(
                        fontSize: 13, color: AppTokens.ink)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${venue.ward}, ${venue.district}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppTokens.inkSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              venue.priceLabel,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTokens.ink,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
