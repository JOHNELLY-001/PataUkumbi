import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../../theme/tokens.dart';
import '../../ui/ui.dart';

/// Explore filter sheet: event type, date, guests + live result count.
/// Date/guests are frontend intent (backend can't filter on them yet);
/// event type is carried into the booking draft (Phase 5).
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<VenueProvider>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.eventDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTokens.primary,
              ),
        ),
        child: child!,
      ),
    );
    provider.setEventDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenueProvider>();
    final dateLabel = provider.eventDate == null
        ? 'Any date'
        : DateFormat('EEE, d MMM yyyy').format(provider.eventDate!);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Filters'),
            const SizedBox(height: 12),
            const _Label('Event type'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final t in VenueProvider.eventTypes)
                  AppChip(
                    label: t,
                    selected: provider.eventType == t,
                    onTap: () => provider.setEventType(t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const _Label('Date'),
            const SizedBox(height: 4),
            _RowButton(
              icon: AppIcons.calendar,
              value: dateLabel,
              onTap: () => _pickDate(context),
              onClear: provider.eventDate == null
                  ? null
                  : () => provider.setEventDate(null),
            ),
            const SizedBox(height: 12),
            const _Label('Guests'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTokens.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.guests,
                      color: AppTokens.ink, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${provider.guests} guests',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fewer guests',
                    onPressed: provider.guests > 1
                        ? () => provider
                            .setGuests(provider.guests - 1)
                        : null,
                    icon: const Icon(AppIcons.remove),
                  ),
                  IconButton(
                    tooltip: 'More guests',
                    onPressed: provider.guests < 500
                        ? () => provider
                            .setGuests(provider.guests + 1)
                        : null,
                    icon: const Icon(AppIcons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Venues too small for your party are dimmed in the list.',
              style: const TextStyle(
                  fontSize: 12, color: AppTokens.inkSecondary),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider.loading && provider.items.isEmpty
                        ? 'Finding venues…'
                        : '${provider.total} venue${provider.total == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.resetEventFilters(),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Show ${provider.total} venue${provider.total == 1 ? '' : 's'}',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTokens.inkSecondary));
  }
}

class _RowButton extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _RowButton({
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTokens.ink, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink)),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(AppIcons.clear,
                    color: AppTokens.inkSecondary, size: 20),
              )
            else
              const Icon(AppIcons.chevron,
                  color: AppTokens.inkSecondary),
          ],
        ),
      ),
    );
  }
}
