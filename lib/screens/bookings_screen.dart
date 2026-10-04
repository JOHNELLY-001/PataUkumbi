import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../theme/tokens.dart';

/// My Bookings: local reservations with cancel.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(title: const Text('My bookings')),
      body: bookings.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.calendar_month_outlined,
                        size: 56, color: AppTokens.inkTertiary),
                    SizedBox(height: 12),
                    Text('No bookings yet',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink)),
                    SizedBox(height: 6),
                    Text(
                        'Reserve a venue and your trips will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTokens.inkSecondary)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: bookings.items.length,
              itemBuilder: (context, i) {
                final b = bookings.items[i];
                final fmt = DateFormat('d MMM yyyy');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        AppTokens.radiusCard),
                    border: Border.all(color: AppTokens.border),
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
                                imageUrl: b.coverImage,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                              )
                            : Container(
                                width: 96,
                                height: 96,
                                color: AppTokens.bgSecondary,
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppTokens.inkTertiary),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(b.venueName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTokens.ink)),
                              const SizedBox(height: 2),
                              Text(
                                '${fmt.format(b.dates.start)} – ${fmt.format(b.dates.end)} · ${b.guests} guests',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTokens.inkSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text('TSh ${b.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTokens.ink)),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.cancel_outlined,
                            color: AppTokens.inkSecondary),
                        onPressed: () => context
                            .read<BookingProvider>()
                            .cancel(b.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
