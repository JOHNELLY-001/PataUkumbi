import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Single white map carousel card: photo, name, area, price.
class MapOverlayCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onTap;

  const MapOverlayCard({
    super.key,
    required this.venue,
    required this.onTap,
    // ignore: unused_element_parameter
    Color? accent,
  });

  @override
  Widget build(BuildContext context) {
    final cover = venue['cover_image']?.toString();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.border),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppTokens.radiusCard)),
              child: cover != null && cover.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (_, __) => Container(
                        width: 110,
                        height: 110,
                        color: AppTokens.bgSecondary,
                      ),
                      errorWidget: (_, __, ___) => const SizedBox(
                        width: 110,
                        height: 110,
                        child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTokens.inkTertiary),
                      ),
                    )
                  : const SizedBox(
                      width: 110,
                      height: 110,
                      child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTokens.inkTertiary),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        (venue['name']?.toString() ?? 'Unknown')
                            .replaceAll('_', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTokens.ink)),
                    const SizedBox(height: 2),
                    Text(
                      venue['venue_type']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTokens.inkSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      venue['pricing_per_hour'] != null
                          ? 'TSh ${venue['pricing_per_hour']}'
                          : 'See prices',
                      style: const TextStyle(
                          color: AppTokens.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
