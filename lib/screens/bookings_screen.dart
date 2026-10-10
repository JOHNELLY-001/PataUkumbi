import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../services/cloudinary.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';

/// My Bookings: local reservations with status chips,
/// Upcoming / Past filters, and cancel.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _showPast = false;

  bool _isPast(Booking b) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(b.dates.end).isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();
    final upcoming =
        bookings.items.where((b) => !_isPast(b)).toList();
    final past = bookings.items.where((b) => _isPast(b)).toList();
    final shown = _showPast ? past : upcoming;
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('My bookings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                AppChip(
                  label: 'Upcoming (${upcoming.length})',
                  selected: !_showPast,
                  onTap: () =>
                      setState(() => _showPast = false),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Past (${past.length})',
                  selected: _showPast,
                  onTap: () => setState(() => _showPast = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? EmptyState(
                    icon: AppIcons.calendar,
                    title: _showPast
                        ? 'No past bookings'
                        : 'No upcoming bookings',
                    subtitle: _showPast
                        ? 'Finished trips will appear here.'
                        : 'Reserve a venue and your trips will appear here.',
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final b = shown[i];
                      final fmt = DateFormat('d MMM yyyy');
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTokens.surface,
                          borderRadius: BorderRadius.circular(
                              AppTokens.radiusCard),
                          border:
                              Border.all(color: AppTokens.border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.horizontal(
                                      left: Radius.circular(
                                          AppTokens.radiusCard)),
                              child: b.coverImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cloudinaryThumb(
                                          b.coverImage,
                                          width: 300),
                                      width: 96,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 300,
                                    )
                                  : Container(
                                      width: 96,
                                      height: 104,
                                      color: AppTokens
                                          .surfaceSecondary,
                                      child: const Icon(
                                          AppIcons.imageBroken,
                                          color: AppTokens
                                              .inkTertiary),
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(b.venueName,
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style:
                                                  const TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                      color: AppTokens
                                                          .ink)),
                                        ),
                                        StatusBadge(
                                          label: _statusLabel(
                                              b.status),
                                          kind: _statusKind(
                                              b.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${fmt.format(b.dates.start)} – ${fmt.format(b.dates.end)} · ${b.guests} guests',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTokens
                                              .inkSecondary),
                                    ),
                                    if (b.eventType.isNotEmpty ||
                                        b.slot.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          b.eventType,
                                          b.slot
                                        ]
                                            .where((e) =>
                                                e.isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTokens
                                                .inkSecondary),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                        'TSh ${b.total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w700,
                                            color:
                                                AppTokens.ink)),
                                  ],
                                ),
                              ),
                            ),
                            if (!_showPast)
                              IconButton(
                                icon: const Icon(
                                    AppIcons.cancel,
                                    color:
                                        AppTokens.inkSecondary),
                                onPressed: () => context
                                    .read<BookingProvider>()
                                    .cancel(b.id),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Requested';
    return status[0].toUpperCase() + status.substring(1);
  }

  StatusKind _statusKind(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusKind.success;
      case 'cancelled':
      case 'declined':
        return StatusKind.error;
      default:
        return StatusKind.warning;
    }
  }
}
