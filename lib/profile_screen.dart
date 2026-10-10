import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/saved_provider.dart';
import 'services/cloudinary.dart';
import 'theme/tokens.dart';
import 'ui/ui.dart';

/// Coastal profile screen: app bar with shortcuts, user card, bookings
/// preview with Upcoming/Past toggle, settings rows, logout.
/// Logic unchanged (auth state, counts, cancel, navigation). Missing
/// backend data is hardcoded in the labeled block below.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// TODO(backend): hardcoded until profile/ratings APIs exist.
// Kept in one labeled block so they read as placeholders.
const _demoRole = 'Event Organizer • Dar es Salaam';
const _demoRating = '4.95';
const _demoMemberSince = "Member since '23";

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPast = false;

  bool _isPast(Booking b) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(b.dates.end).isBefore(today);
  }

  void _comingSoon(String feature) {
    AppSnack.info(context, '$feature is coming soon.');
  }

  Future<void> _shareProfile(String name) async {
    await SharePlus.instance.share(ShareParams(
        text: '$name on Haven — find and book great venues.'));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final bookings = context.watch<BookingProvider>();
    final savedCount = context.watch<SavedProvider>().count;
    final name = !loggedIn
        ? 'Guest explorer'
        : (auth.displayName.isNotEmpty
            ? auth.displayName
            : 'Welcome back');
    final upcoming =
        bookings.items.where((b) => !_isPast(b)).toList();
    final past = bookings.items.where((b) => _isPast(b)).toList();
    final preview = (_showPast ? past : upcoming).firstOrNull;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTokens.surface,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _comingSoon('Notifications'),
            icon: const Icon(AppIcons.notifications,
                color: AppTokens.inkSecondary, size: 22),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _comingSoon('Settings'),
            icon: const Icon(AppIcons.settings,
                color: AppTokens.inkSecondary, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _UserCard(
            name: name,
            loggedIn: loggedIn,
            onEdit: () => _comingSoon('Edit profile'),
            onShare: () => _shareProfile(name),
            onLogin: () => Navigator.of(context)
                .pushReplacementNamed('/login'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Bookings',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink)),
                    Text(
                        'Manage venue reservations & access passes',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTokens.inkSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed('/bookings'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('History',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SegmentedTabs(
            upcoming: upcoming.length,
            past: past.length,
            showPast: _showPast,
            onChange: (v) => setState(() => _showPast = v),
          ),
          const SizedBox(height: 12),
          if (preview != null)
            _BookingPreview(
              booking: preview,
              showCancel:
                  !_showPast && preview.status == 'requested',
              onCancel: () => context
                  .read<BookingProvider>()
                  .cancel(preview.id),
              onOpen: () =>
                  Navigator.of(context).pushNamed('/bookings'),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius:
                    BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: Text(
                _showPast
                    ? 'No past bookings yet.'
                    : 'No upcoming bookings. Reserve a venue and it will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.inkSecondary),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Account & Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink)),
          const SizedBox(height: 8),
          AppCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SettingRow(
                  icon: AppIcons.saved,
                  title: 'Saved Venues',
                  trailing: '$savedCount saved',
                  onTap: () => Navigator.of(context)
                      .pushNamed('/saved'),
                ),
                _SettingRow(
                  icon: AppIcons.wallet,
                  title: 'Payment Methods & M-Pesa',
                  subtitle: 'Vodacom M-Pesa, CRDB, NMB',
                  onTap: () => _comingSoon('Payments'),
                ),
                _SettingRow(
                  icon: AppIcons.hostAdd,
                  title: 'Host a Venue',
                  subtitle:
                      'List your space in Masaki, Oysterbay & Dar',
                  badge: 'Partner',
                  onTap: () => _comingSoon('Venue hosting'),
                ),
                _SettingRow(
                  icon: AppIcons.help,
                  title: 'Help & Support',
                  onTap: () => _comingSoon('Help & support'),
                ),
                _SettingRow(
                  icon: AppIcons.verified,
                  title: 'Terms & Privacy',
                  onTap: () => _comingSoon('Terms & privacy'),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.primary,
                side:
                    const BorderSide(color: AppTokens.border),
                backgroundColor: AppTokens.surfaceSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      AppTokens.radiusButton),
                ),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                if (loggedIn) {
                  await context.read<AuthProvider>().logout();
                }
                if (context.mounted) {
                  Navigator.of(context)
                      .pushReplacementNamed('/login');
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(loggedIn ? 'Log Out' : 'Log in'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                Text('Haven · v1.0',
                    style: TextStyle(
                        color: AppTokens.inkTertiary,
                        fontSize: 12)),
                SizedBox(height: 2),
                Text('Brought to you by Swahili Venues Network',
                    style: TextStyle(
                        color: AppTokens.inkTertiary,
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final bool loggedIn;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onLogin;
  const _UserCard({
    required this.name,
    required this.loggedIn,
    required this.onEdit,
    required this.onShare,
    required this.onLogin,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTokens.primaryTint,
                      border: Border.all(
                          color: AppTokens.primary,
                          width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.primary)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTokens.surface,
                            width: 2),
                      ),
                      child: const Icon(AppIcons.verified,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink)),
                    const Text(
                        _demoRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTokens.inkSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppTokens.surfaceSecondary,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.starActive,
                                  size: 12,
                                  // TODO(backend): hardcoded rating.
                                  color: AppTokens.primary),
                              SizedBox(width: 4),
                              Text('$_demoRating Rating',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: AppTokens.ink)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(_demoMemberSince,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppTokens.inkSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (loggedIn)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTokens.ink,
                        side: const BorderSide(
                            color: AppTokens.border),
                        backgroundColor:
                            AppTokens.surfaceSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      onPressed: onEdit,
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.edit, size: 16),
                          SizedBox(width: 6),
                          Text('Edit Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.ink,
                      side: const BorderSide(
                          color: AppTokens.border),
                      backgroundColor:
                          AppTokens.surfaceSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onShare,
                    child: const Icon(AppIcons.share,
                        size: 18),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogin,
                child: const Text('Log in'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int upcoming;
  final int past;
  final bool showPast;
  final ValueChanged<bool> onChange;
  const _SegmentedTabs({
    required this.upcoming,
    required this.past,
    required this.showPast,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, int count, bool active,
        VoidCallback tap) {
      return Expanded(
        child: GestureDetector(
          onTap: tap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active
                  ? AppTokens.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active ? AppTokens.shadowCard : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (active)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppTokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text('$label ($count)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppTokens.ink
                            : AppTokens.inkSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          tab('Upcoming', upcoming, !showPast,
              () => onChange(false)),
          tab('Past', past, showPast, () => onChange(true)),
        ],
      ),
    );
  }
}

class _BookingPreview extends StatelessWidget {
  final Booking booking;
  final bool showCancel;
  final VoidCallback onCancel;
  final VoidCallback onOpen;
  const _BookingPreview({
    required this.booking,
    required this.showCancel,
    required this.onCancel,
    required this.onOpen,
  });

  String get _ref {
    final id = booking.id;
    final tail = id.length <= 4 ? id : id.substring(id.length - 4);
    return '#EV-${tail.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d, yyyy');
    final dates =
        '${fmt.format(booking.dates.start)} – ${fmt.format(booking.dates.end)}';
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius:
              BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.border),
          boxShadow: AppTokens.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTokens.radiusCard)),
                  child: booking.coverImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cloudinaryThumb(
                              booking.coverImage,
                              width: 800),
                          height: 176,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          placeholder: (_, __) => Container(
                              height: 176,
                              color:
                                  AppTokens.surfaceSecondary),
                          errorWidget: (_, __, ___) =>
                              Container(
                            height: 176,
                            color:
                                AppTokens.surfaceSecondary,
                            child: const Icon(
                                AppIcons.imageBroken,
                                color:
                                    AppTokens.inkTertiary),
                          ),
                        )
                      : Container(
                          height: 176,
                          color: AppTokens.surfaceSecondary,
                          child: const Icon(
                              AppIcons.imageBroken,
                              color: AppTokens.inkTertiary),
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(
                              top: Radius.circular(
                                  AppTokens.radiusCard)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6)
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusBadge(
                    label: _statusLabel(booking.status),
                    kind: _statusKind(booking.status),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withValues(alpha: 0.6),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(_ref,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(booking.venueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 4)
                          ])),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceSecondary
                          .withValues(alpha: 0.6),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTokens.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Fact(
                              icon: AppIcons.calendar,
                              label: 'Date & Schedule',
                              value: dates,
                              sub: booking.slot),
                        ),
                        Expanded(
                          child: _Fact(
                              icon: AppIcons.guests,
                              label: 'Expected Guests',
                              value:
                                  '${booking.guests} Guests',
                              sub: booking.eventType.isNotEmpty
                                  ? booking.eventType
                                  : booking.slot),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTokens
                                        .inkSecondary)),
                            Text(
                                'TSh ${booking.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppTokens.ink)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          const Text('Deposit due',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTokens
                                      .inkSecondary)),
                          Text(
                              'TSh ${booking.deposit.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onOpen,
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.receipt, size: 18),
                          SizedBox(width: 8),
                          Text('View Booking'),
                        ],
                      ),
                    ),
                  ),
                  if (showCancel) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              AppTokens.inkSecondary,
                          side: const BorderSide(
                              color: AppTokens.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        onPressed: onCancel,
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.cancel, size: 16),
                            SizedBox(width: 6),
                            Text('Cancel Reservation'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Requested';
    return status[0].toUpperCase() + status.substring(1);
  }

  StatusKind _statusKind(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
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

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: AppTokens.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTokens.inkSecondary)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink)),
              if (sub.isNotEmpty)
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTokens.inkSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final String? badge;
  final VoidCallback onTap;
  final bool last;
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      size: 20, color: AppTokens.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTokens.ink)),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppTokens.primaryTint,
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          AppTokens.primary)),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 11,
                                color:
                                    AppTokens.inkSecondary)),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(
                          fontSize: 13,
                          color:
                              AppTokens.inkSecondary)),
                const SizedBox(width: 6),
                const Icon(AppIcons.chevron,
                    size: 20,
                    color: AppTokens.inkTertiary),
              ],
            ),
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}
