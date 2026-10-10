import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/venue_provider.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../theme/tokens.dart';
import '../ui/ui.dart';
import 'booking_repository.dart';

/// 4-step booking flow: Event details -> Requirements -> Review ->
/// Confirmation. Draft auto-saves per venue; booked dates grey out.
/// Language rule: "Request to book" — never "Confirmed".
class BookingFlowPage extends StatefulWidget {
  final Map<String, dynamic> venue;
  const BookingFlowPage({super.key, required this.venue});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  static const _requirementsOptions = [
    'Catering',
    'Décor',
    'Sound system',
    'Setup help',
  ];

  int _step = 0;
  bool _saving = false;
  Booking? _done;

  final _draft = BookingDraft();
  final _notes = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _reviewKey = GlobalKey<FormState>();

  int get _venueId {
    final v = widget.venue;
    return v['id'] is num
        ? (v['id'] as num).toInt()
        : int.tryParse('${v['id']}') ?? 0;
  }

  int get _maxGuests {
    final raw = widget.venue['max_capacity'];
    final n = raw is num ? raw.toInt() : int.tryParse('$raw');
    return (n == null || n <= 0) ? 500 : n;
  }

  @override
  void initState() {
    super.initState();
    // Contact prefill from the logged-in profile (draft wins if present).
    final auth = context.read<AuthProvider>();
    if (auth.displayName.isNotEmpty) {
      _name.text = auth.displayName;
    }
    if (auth.profilePhone.isNotEmpty) {
      _phone.text = auth.profilePhone;
    }
    final filters = context.read<VenueProvider>();
    if (filters.eventType != 'Any event') {
      _draft.eventType = filters.eventType;
    }
    if (filters.eventDate != null) {
      _draft.start = filters.eventDate;
      _draft.end = filters.eventDate;
    }
    _draft.guests = filters.guests.clamp(1, _maxGuests);
    _notes.addListener(() {
      _draft.notes = _notes.text;
      _persist();
    });
    _name.addListener(() {
      _draft.contactName = _name.text;
      _persist();
    });
    _phone.addListener(() {
      _draft.contactPhone = _phone.text;
      _persist();
    });
    DraftStore.load(_venueId).then((saved) {
      if (saved != null && mounted) {
        setState(() {
          _draft
            ..eventType = saved.eventType
            ..start = saved.start
            ..end = saved.end
            ..slot = saved.slot
            ..guests = saved.guests.clamp(1, _maxGuests)
            ..requirements = saved.requirements
            ..notes = saved.notes
            ..contactName = saved.contactName
            ..contactPhone = saved.contactPhone;
          _notes.text = saved.notes;
          _name.text = saved.contactName;
          _phone.text = saved.contactPhone;
        });
      }
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _persist() => unawaited(DraftStore.save(_venueId, _draft));

  /// Mutate the draft from step widgets, then rebuild + auto-save.
  void updateDraft(void Function() apply) {
    setState(apply);
    _persist();
  }

  void goStep(int delta) => setState(() => _step += delta);

  // ---------- pricing (estimates — host confirms) ----------

  double? _num(dynamic raw) {
    if (raw == null) return null;
    final cleaned =
        raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  double? get _slotPrice {
    final day = _num(widget.venue['pricing_per_day']);
    final hour = _num(widget.venue['pricing_per_hour']);
    if (_draft.slot == BookingSlots.fullDay) {
      return day ?? (hour != null ? hour * 8 : null);
    }
    final h = BookingSlots.hours[_draft.slot] ?? 4;
    if (hour != null) return hour * h;
    return day != null ? day / 2 : null;
  }

  int get _days {
    if (_draft.start == null || _draft.end == null) return 1;
    return _draft.end!.difference(_draft.start!).inDays.clamp(1, 365);
  }

  double get _subtotal => (_slotPrice ?? 0) * _days;
  double get _service => _subtotal * 0.12;
  double get _total => _subtotal + _service;

  /// Per-venue deposit rule (backend deposit_percent), 30 fallback.
  double get _depositRate {
    final raw = widget.venue['deposit_percent'];
    final n = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (n == null) return 0.30;
    return n.clamp(0, 100) / 100;
  }

  double get _deposit => _total * _depositRate;

  // ---------- date picking with booked dates greyed out ----------

  bool _isBooked(DateTime day, List<DateTimeRangeDto> ranges) {
    final d = DateUtils.dateOnly(day);
    for (final r in ranges) {
      var cur = DateUtils.dateOnly(r.start);
      final end = DateUtils.dateOnly(r.end);
      while (!cur.isAfter(end)) {
        if (cur == d) return true;
        cur = cur.add(const Duration(days: 1));
      }
    }
    return false;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Server blocks merged in: 'yyyy-MM-dd:slot'. A day is grey when a
  /// Full-day block covers it, or all three partial slots are taken.
  bool _serverBlocked(DateTime day, Set<String> blocked) {
    final d = _ymd(day);
    if (blocked.contains('$d:Full day')) return true;
    return blocked.contains('$d:Morning') &&
        blocked.contains('$d:Afternoon') &&
        blocked.contains('$d:Evening');
  }

  Future<void> _pickDates() async {
    final ranges =
        context.read<BookingProvider>().bookedRanges(_venueId);
    final now = DateTime.now();
    final last = DateTime(now.year + 1, now.month, now.day);
    final blocked = <String>{};
    try {
      final data = await ApiClient().getJson(
          ApiConfig.venueAvailability(_venueId,
              from: _ymd(now), to: _ymd(last)));
      final list = data is Map
          ? (data['booked'] as List? ?? [])
          : [];
      for (final e in list.whereType<Map>()) {
        final s = DateTime.tryParse('${e['start']}');
        final en = DateTime.tryParse('${e['end']}');
        final slot = '${e['slot']}';
        if (s == null || en == null) continue;
        var cur = DateUtils.dateOnly(s);
        final end = DateUtils.dateOnly(en);
        while (!cur.isAfter(end)) {
          blocked.add('${_ymd(cur)}:$slot');
          cur = cur.add(const Duration(days: 1));
        }
      }
    } catch (_) {
      // Offline: local ranges still grey out.
    }
    if (!mounted) return;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: last,
      initialDateRange: _draft.start != null && _draft.end != null
          ? DateTimeRange(start: _draft.start!, end: _draft.end!)
          : null,
      selectableDayPredicate: (day, _, __) =>
          !_isBooked(day, ranges) && !_serverBlocked(day, blocked),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTokens.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _draft.start = picked.start;
        _draft.end = picked.end;
      });
      _persist();
    }
  }

  Future<void> _submit() async {
    if (!(_reviewKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final booking =
          await context.read<BookingProvider>().add(
                venueId: _venueId,
                venueName: widget.venue['name']
                        ?.toString()
                        .replaceAll('_', ' ') ??
                    'Venue',
                coverImage:
                    widget.venue['cover_image']?.toString() ?? '',
                start: _draft.start!,
                end: _draft.end!,
                guests: _draft.guests,
                total: _total,
                eventType: _draft.eventType,
                slot: _draft.slot,
                requirements: _draft.requirements.toList(),
                notes: _draft.notes.trim(),
                contactName: _draft.contactName.trim(),
                contactPhone: _draft.contactPhone.trim(),
                deposit: _deposit,
              );
      await DraftStore.clear(_venueId);
      if (mounted) setState(() => _done = booking);
    } on ApiException catch (e) {
      // Server rejections (409 double-book, 400 validation, offline):
      // stay on the review step and explain. Draft is kept.
      if (mounted) AppSnack.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnack.error(context,
            'Something went wrong. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- build ----------

  static const _titles = [
    'Event details',
    'Requirements',
    'Review request',
    'Request sent',
  ];

  @override
  Widget build(BuildContext context) {
    final venueName =
        widget.venue['name']?.toString().replaceAll('_', ' ') ?? 'Venue';
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(_done != null ? _titles[3] : _titles[_step]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepBar(step: _done != null ? 3 : _step),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: _done != null
                    ? _Confirmation(done: _done!)
                    : switch (_step) {
                        0 => _DetailsStep(state: this),
                        1 => _RequirementsStep(state: this),
                        _ => _ReviewStep(state: this),
                      },
              ),
            ),
            _BottomBar(state: this, venueName: venueName),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? AppTokens.primary
                      : AppTokens.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final _BookingFlowPageState state;
  final String venueName;
  const _BottomBar({required this.state, required this.venueName});

  @override
  Widget build(BuildContext context) {
    if (state._done != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          border: Border(top: BorderSide(color: AppTokens.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'View my bookings',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/bookings');
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Done',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    final isLast = state._step == 2;
    final canNext = switch (state._step) {
      0 =>
        state._draft.eventType.isNotEmpty &&
            state._draft.start != null &&
            state._draft.end != null,
      _ => true,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(top: BorderSide(color: AppTokens.border)),
      ),
      child: Row(
        children: [
          if (state._step > 0)
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: AppButtonVariant.secondary,
                onPressed: () => state.goStep(-1),
              ),
            ),
          if (state._step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              label: isLast ? 'Request to book' : 'Continue',
              loading: state._saving,
              onPressed: !canNext || state._saving
                  ? null
                  : () {
                      if (isLast) {
                        state._submit();
                      } else {
                        state.goStep(1);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- step 1: event details ----------

class _DetailsStep extends StatelessWidget {
  final _BookingFlowPageState state;
  const _DetailsStep({required this.state});

  @override
  Widget build(BuildContext context) {
    final draft = state._draft;
    final fmt = DateFormat('EEE, d MMM');
    final datesLabel = draft.start == null
        ? 'Select dates'
        : '${fmt.format(draft.start!)} – ${fmt.format(draft.end!)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Event type'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in VenueProvider.eventTypes
                .where((e) => e != 'Any event'))
              AppChip(
                label: t,
                selected: draft.eventType == t,
                onTap: () =>
                    state.updateDraft(() => draft.eventType = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _Label('Dates'),
        const SizedBox(height: 8),
        _TapRow(
          icon: AppIcons.calendar,
          value: datesLabel,
          onTap: state._pickDates,
        ),
        const SizedBox(height: 4),
        const Text(
          'Already-booked dates are greyed out.',
          style:
              TextStyle(fontSize: 12, color: AppTokens.inkSecondary),
        ),
        const SizedBox(height: 16),
        const _Label('Time slot'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in BookingSlots.all)
              AppChip(
                label: s,
                selected: draft.slot == s,
                onTap: () =>
                    state.updateDraft(() => draft.slot = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const _Label('Guests'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: Border.all(color: AppTokens.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.guests,
                  color: AppTokens.ink, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${draft.guests} guest${draft.guests == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink),
                ),
              ),
              IconButton(
                tooltip: 'Fewer guests',
                onPressed: draft.guests > 1
                    ? () =>
                        state.updateDraft(() => draft.guests--)
                    : null,
                icon: const Icon(AppIcons.remove),
              ),
              IconButton(
                tooltip: 'More guests',
                onPressed: draft.guests < state._maxGuests
                    ? () =>
                        state.updateDraft(() => draft.guests++)
                    : null,
                icon: const Icon(AppIcons.add),
              ),
            ],
          ),
        ),
        Text(
          'This space fits up to ${state._maxGuests}.',
          style: const TextStyle(
              fontSize: 12, color: AppTokens.inkSecondary),
        ),
      ],
    );
  }
}

// ---------- step 2: requirements ----------

class _RequirementsStep extends StatelessWidget {
  final _BookingFlowPageState state;
  const _RequirementsStep({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('What should the host arrange?'),
        const SizedBox(height: 8),
        ..._BookingFlowPageState._requirementsOptions.map(
          (r) => CheckboxListTile(
            value: state._draft.requirements.contains(r),
            onChanged: (v) {
              state.updateDraft(() {
                if (v == true) {
                  state._draft.requirements.add(r);
                } else {
                  state._draft.requirements.remove(r);
                }
              });
            },
            title: Text(r,
                style: const TextStyle(
                    fontSize: 15, color: AppTokens.ink)),
            activeColor: AppTokens.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: 8),
        const _Label('Anything else the host should know?'),
        const SizedBox(height: 8),
        TextFormField(
          controller: state._notes,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. wheelchair access, late setup…',
          ),
        ),
      ],
    );
  }
}

// ---------- step 3: review ----------

class _ReviewStep extends StatelessWidget {
  final _BookingFlowPageState state;
  const _ReviewStep({required this.state});

  @override
  Widget build(BuildContext context) {
    final draft = state._draft;
    final fmt = DateFormat('EEE, d MMM yyyy');
    final price = state._slotPrice;
    return Form(
      key: state._reviewKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line('Event', draft.eventType),
                _Line('Dates',
                    '${fmt.format(draft.start!)} – ${fmt.format(draft.end!)}'),
                _Line('Slot', draft.slot),
                _Line('Guests', '${draft.guests}'),
                if (draft.requirements.isNotEmpty)
                  _Line('Extras', draft.requirements.join(', ')),
                if (draft.notes.trim().isNotEmpty)
                  _Line('Notes', draft.notes.trim()),
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
          if (price != null) ...[
            _PriceLine(
                label:
                    'TSh ${PriceText.compact(price)} × ${state._days} day${state._days > 1 ? 's' : ''} (${draft.slot})',
                value: 'TSh ${PriceText.compact(state._subtotal)}'),
            _PriceLine(
                label: 'Service fee (12%)',
                value: 'TSh ${PriceText.compact(state._service)}'),
            const Divider(height: 24),
            _PriceLine(
                label: 'Total',
                value: 'TSh ${PriceText.compact(state._total)}',
                bold: true),
            _PriceLine(
                label:
                    'Deposit due (${(state._depositRate * 100).toInt()}% est.)',
                value: 'TSh ${PriceText.compact(state._deposit)}'),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Estimated — the host confirms the final price.',
                style: TextStyle(
                    fontSize: 12, color: AppTokens.inkSecondary),
              ),
            ),
          ] else ...[
            const _PriceLine(
                label: 'Total', value: 'To confirm with host'),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'No rate listed for this slot — the host confirms pricing.',
                style: TextStyle(
                    fontSize: 12, color: AppTokens.inkSecondary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Contact details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Full name', hintText: 'Jane Doe'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name required so the host can reach you'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: state._phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone', hintText: '+255 ...'),
            validator: (v) {
              final digits =
                  v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
              if (digits.length < 7) {
                return 'Enter a reachable phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.inkSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink)),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PriceLine(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: bold ? 16 : 14,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        color: AppTokens.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ---------- step 4: confirmation ----------

class _Confirmation extends StatelessWidget {
  final Booking done;
  const _Confirmation({required this.done});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.check,
                    color: AppTokens.success, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request sent',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink)),
                    Text(
                      'Ref ${done.id.substring(done.id.length - 6).toUpperCase()} · ${fmt.format(done.dates.start)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTokens.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('What happens next',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink)),
        const SizedBox(height: 8),
        const _TimelineRow(
          done: true,
          current: false,
          title: 'Request sent',
          subtitle: 'The host received your event details.',
        ),
        const _TimelineRow(
          done: false,
          current: true,
          title: 'Host review',
          subtitle: 'The host checks availability and confirms pricing.',
        ),
        const _TimelineRow(
          done: false,
          current: false,
          title: 'Confirmed',
          subtitle: 'Unlocked after the host approves your request.',
          last: true,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final bool done;
  final bool current;
  final String title;
  final String subtitle;
  final bool last;
  const _TimelineRow({
    required this.done,
    required this.current,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppTokens.success
        : current
            ? AppTokens.primary
            : AppTokens.inkTertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done || current
                    ? color.withValues(alpha: 0.12)
                    : AppTokens.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                  done ? AppIcons.check : AppIcons.clock,
                  size: 15,
                  color: color),
            ),
            if (!last)
              Container(width: 2, height: 28, color: AppTokens.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: current || done
                            ? AppTokens.ink
                            : AppTokens.inkSecondary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.inkSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- shared bits ----------

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

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  const _TapRow(
      {required this.icon, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTokens.surface,
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
            const Icon(AppIcons.chevron,
                color: AppTokens.inkSecondary),
          ],
        ),
      ),
    );
  }
}
