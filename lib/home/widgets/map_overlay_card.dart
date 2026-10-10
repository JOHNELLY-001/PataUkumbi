import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/saved_provider.dart';
import '../../services/cloudinary.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';

/// Coastal map carousel card (320px): 110px thumb with heart, area,
/// title, capacity, coral price + View Details bar. Compare toggle kept.
/// compareSelected null hides the toggle (web/desktop fallback list).
/// Data logic (open/compare/selection) is unchanged.
class MapOverlayCard extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final bool? compareSelected;
  final VoidCallback? onCompareToggle;

  const MapOverlayCard({
    super.key,
    required this.venue,
    required this.onTap,
    required this.onOpen,
    this.compareSelected,
    this.onCompareToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cover = venue['cover_image']?.toString();
    final venueId = int.tryParse(venue['id']?.toString() ?? '');
    final saved =
        venueId == null ? false : context.watch<SavedProvider>().isSaved(venueId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius:
              BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 24,
                offset: Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: cover != null && cover.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cloudinaryThumb(cover,
                                  width: 400),
                              width: 110,
                              height: 105,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              placeholder: (_, __) => Container(
                                width: 110,
                                height: 105,
                                color: AppTokens.surfaceSecondary,
                              ),
                              errorWidget: (_, __, ___) =>
                                  const SizedBox(
                                width: 110,
                                height: 105,
                                child: Icon(
                                    AppIcons.imageBroken,
                                    color:
                                        AppTokens.inkTertiary),
                              ),
                            )
                          : const SizedBox(
                              width: 110,
                              height: 105,
                              child: Icon(AppIcons.imageBroken,
                                  color: AppTokens.inkTertiary),
                            ),
                    ),
                    if (compareSelected != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Semantics(
                          button: true,
                          checked: compareSelected!,
                          label: 'Compare venue',
                          child: GestureDetector(
                            onTap: onCompareToggle,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: compareSelected!
                                    ? AppTokens.primary
                                    : AppTokens.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: compareSelected!
                                      ? AppTokens.primary
                                      : AppTokens.border,
                                ),
                                boxShadow:
                                    AppTokens.shadowCard,
                              ),
                              child: Icon(
                                AppIcons.check,
                                size: 15,
                                color: compareSelected!
                                    ? Colors.white
                                    : AppTokens.inkTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (venueId != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FavoriteButton(
                              saved: saved,
                              iconSize: 16,
                              idleColor: AppTokens.ink,
                              onToggle: (_) => context
                                  .read<SavedProvider>()
                                  .toggle(venueId),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          (venue['name']?.toString() ??
                                  'Unknown')
                              .replaceAll('_', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTokens.ink)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(AppIcons.location,
                              size: 13,
                              color: AppTokens.inkTertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _area(venue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppTokens.inkSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(AppIcons.guests,
                              size: 13,
                              color: AppTokens.inkSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _capacity(venue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppTokens.inkSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _priceLine(venue),
                    ],
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _type(venue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTokens.inkSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Details',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(AppIcons.forward,
                              size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _area(Map<String, dynamic> venue) {
    final parts = [
      venue['ward']?.toString().trim() ?? '',
      venue['district']?.toString().trim() ?? ''
    ].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) {
      return venue['venue_type']?.toString() ?? '';
    }
    return parts.join(', ');
  }

  String _capacity(Map<String, dynamic> venue) {
    final raw = venue['max_capacity'];
    final n = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (n == null || n <= 0) return 'Capacity on request';
    return 'Up to $n guests';
  }

  String _type(Map<String, dynamic> venue) =>
      (venue['venue_type']?.toString() ?? '').replaceAll('_', ' ');

  Widget _priceLine(Map<String, dynamic> venue) {
    for (final key in ['pricing_per_day', 'pricing_per_hour']) {
      final raw = venue[key]
              ?.toString()
              .replaceAll(RegExp(r'[^0-9.]'), '') ??
          '';
      final v = double.tryParse(raw);
      if (v != null) {
        return Row(
          children: [
            Text('TSh ${PriceText.compact(v)}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.primary)),
            const Text(' / day',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTokens.inkSecondary)),
          ],
        );
      }
    }
    return const Text('See prices',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTokens.ink));
  }
}
