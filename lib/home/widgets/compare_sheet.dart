import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/cloudinary.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';

/// Side-by-side compare table for up to 3 venues.
Future<void> showCompareSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> venues,
  required ValueChanged<Map<String, dynamic>> onOpen,
}) {
  final shown = venues.take(3).toList();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Compare venues'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 86),
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _CompareHeader(venue: shown[i])),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _Row(
                label: 'Type',
                values: shown
                    .map((v) => _str(v['venue_type']))
                    .toList()),
            _Row(
                label: 'Capacity',
                values: shown
                    .map((v) => _cap(v['max_capacity']))
                    .toList()),
            _Row(
                label: 'Per day',
                values:
                    shown.map((v) => _money(v['pricing_per_day'])).toList()),
            _Row(
                label: 'Per hour',
                values: shown
                    .map((v) => _money(v['pricing_per_hour']))
                    .toList()),
            _Row(
                label: 'Area',
                values: shown.map((v) => _area(v)).toList()),
            _Row(
                label: 'Parking',
                values:
                    shown.map((v) => _yesNo(v['parking_available'])).toList()),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'View',
                      height: 44,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => onOpen(shown[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompareHeader extends StatelessWidget {
  final Map<String, dynamic> venue;
  const _CompareHeader({required this.venue});

  @override
  Widget build(BuildContext context) {
    final cover = venue['cover_image']?.toString() ?? '';
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: cover.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: cloudinaryThumb(cover, width: 400),
                  height: 90,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  errorWidget: (_, __, ___) => Container(
                    height: 90,
                    color: AppTokens.surfaceSecondary,
                    child: const Icon(AppIcons.imageBroken,
                        color: AppTokens.inkTertiary),
                  ),
                )
              : Container(
                  height: 90,
                  color: AppTokens.surfaceSecondary,
                  child: const Icon(AppIcons.imageBroken,
                      color: AppTokens.inkTertiary),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          (venue['name']?.toString() ?? 'Unknown')
              .replaceAll('_', ' '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final List<String> values;
  const _Row({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.inkSecondary)),
          ),
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Text(values[i],
                  style: const TextStyle(
                      fontSize: 13, color: AppTokens.ink)),
            ),
          ],
        ],
      ),
    );
  }
}

String _str(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? '–' : s.replaceAll('_', ' ');
}

String _cap(dynamic v) {
  final n = v is num ? v.toInt() : int.tryParse('$v');
  if (n == null || n <= 0) return '–';
  return '$n guests';
}

String _money(dynamic v) {
  final raw = v?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
  final d = double.tryParse(raw);
  if (d == null) return '–';
  return 'TSh ${PriceText.compact(d)}';
}

String _area(Map<String, dynamic> v) {
  final parts = [
    v['ward']?.toString().trim() ?? '',
    v['district']?.toString().trim() ?? ''
  ].where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? '–' : parts.join(', ');
}

String _yesNo(dynamic v) {
  if (v is bool) return v ? 'Yes' : '–';
  if (v is num) return v != 0 ? 'Yes' : '–';
  final s = v?.toString().toLowerCase().trim() ?? '';
  return (s == 'true' || s == '1' || s == 'yes' || s == 'available')
      ? 'Yes'
      : '–';
}
