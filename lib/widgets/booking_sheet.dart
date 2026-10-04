import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../theme/tokens.dart';

/// Airbnb-style booking: dates, guests, price breakdown, confirm.
/// Writes to [BookingProvider] (local store, no payment).
class BookingSheet extends StatefulWidget {
  final Map<String, dynamic> venue;
  const BookingSheet({super.key, required this.venue});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  DateTime? _start;
  DateTime? _end;
  int _guests = 2;
  bool _saving = false;

  int get _maxGuests {
    final raw = widget.venue['max_capacity'];
    final n = raw is num ? raw.toInt() : int.tryParse('$raw');
    return (n == null || n <= 0) ? 500 : n;
  }

  double get _nightly {
    for (final key in ['pricing_per_day', 'pricing_per_hour']) {
      final raw = widget.venue[key]
          ?.toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      final v = double.tryParse(raw ?? '');
      if (v != null) return v;
    }
    return 0;
  }

  int get _nights {
    if (_start == null || _end == null) return 1;
    return _end!.difference(_start!).inDays.clamp(1, 365);
  }

  double get _subtotal => _nightly * _nights;
  double get _service => _subtotal * 0.12;
  double get _total => _subtotal + _service;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTokens.coral,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  Future<void> _confirm() async {
    if (_start == null || _end == null || _nightly <= 0) return;
    setState(() => _saving = true);
    try {
      final id = widget.venue['id'] is num
          ? (widget.venue['id'] as num).toInt()
          : int.tryParse('${widget.venue['id']}') ?? 0;
      await context.read<BookingProvider>().add(
            venueId: id,
            venueName:
                widget.venue['name']?.toString().replaceAll('_', ' ') ??
                    'Venue',
            coverImage: widget.venue['cover_image']?.toString() ?? '',
            start: _start!,
            end: _end!,
            guests: _guests,
            total: _total,
          );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM');
    final datesLabel = _start == null
        ? 'Select dates'
        : '${fmt.format(_start!)} – ${fmt.format(_end!)} ($_nights night${_nights > 1 ? 's' : ''})';
    final valid = _start != null && _nightly > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your booking',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink)),
            const SizedBox(height: 16),
            _RowButton(
              icon: Icons.calendar_month_outlined,
              title: 'Dates',
              value: datesLabel,
              onTap: _pickDates,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTokens.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      color: AppTokens.ink),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Guests',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.ink)),
                  ),
                  IconButton(
                    onPressed: _guests > 1
                        ? () => setState(() => _guests--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text('$_guests',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: _guests < _maxGuests
                        ? () => setState(() => _guests++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Price details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink)),
            const SizedBox(height: 8),
            _PriceLine(
                label:
                    'TSh ${_fmt(_nightly)} × $_nights night${_nights > 1 ? 's' : ''}',
                value: 'TSh ${_fmt(_subtotal)}'),
            const _PriceLine(
                label: 'Cleaning fee', value: 'Included'),
            _PriceLine(
                label: 'Service fee (12%)',
                value: 'TSh ${_fmt(_service)}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.ink)),
                Text('TSh ${_fmt(_total)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.ink)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: valid && !_saving ? _confirm : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_nightly <= 0
                      ? 'Price on request'
                      : 'Confirm booking'),
            ),
            if (_nightly <= 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('This host confirms pricing on request.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.inkSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      final k = v / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}k';
    }
    return v.toStringAsFixed(0);
  }
}

class _RowButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _RowButton({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
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
            Icon(icon, color: AppTokens.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTokens.inkSecondary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTokens.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  const _PriceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppTokens.ink)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: AppTokens.ink)),
        ],
      ),
    );
  }
}
