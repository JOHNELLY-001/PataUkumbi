import 'package:flutter/material.dart';

/// Single icon set for the whole app (Material rounded/outlined).
/// Screens must use these — never `Icons.*` directly — so a glyph can
/// be swapped in exactly one place.
///
/// NOTE (Phase 1 deviation): UI_design.txt specified phosphor_flutter,
/// but phosphor_flutter 2.1.0 (the latest published) cannot compile on
/// this Flutter 3.47 toolchain — it subclasses `IconData`, which is now
/// a final class. The mapping file keeps the "one icon set" architecture,
/// so switching the backing set later is still a one-file change.
abstract final class AppIcons {
  // Brand + bottom navigation (outline = idle, filled = active).
  static const IconData brandPin = Icons.place_rounded;
  static const IconData explore = Icons.search_rounded;
  static const IconData exploreActive = Icons.search_rounded;
  static const IconData map = Icons.map_outlined;
  static const IconData mapActive = Icons.map_rounded;
  static const IconData saved = Icons.favorite_border_rounded;
  static const IconData savedActive = Icons.favorite_rounded;
  static const IconData profile = Icons.person_outline_rounded;
  static const IconData profileActive = Icons.person_rounded;

  // Navigation + actions.
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData close = Icons.clear_rounded;
  static const IconData clear = Icons.clear_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_outline_rounded;
  static const IconData chevron = Icons.chevron_right_rounded;
  static const IconData add = Icons.add_circle_outline_rounded;
  static const IconData remove = Icons.remove_circle_outline_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData share = Icons.share_outlined;
  static const IconData filter = Icons.tune_rounded;
  static const IconData alert = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;

  // Auth.
  static const IconData showPassword = Icons.visibility_outlined;
  static const IconData hidePassword = Icons.visibility_off_outlined;

  // Content.
  static const IconData search = Icons.search_rounded;
  static const IconData location = Icons.location_on_outlined;
  static const IconData calendar = Icons.calendar_month_outlined;
  static const IconData calendarCheck = Icons.event_available_outlined;
  static const IconData guests = Icons.people_outline_rounded;
  static const IconData room = Icons.meeting_room_outlined;
  static const IconData parking = Icons.local_parking_outlined;
  static const IconData clock = Icons.schedule_outlined;
  static const IconData phone = Icons.phone_outlined;
  static const IconData money = Icons.payments_outlined;
  static const IconData star = Icons.star_border_rounded;
  static const IconData starActive = Icons.star_rounded;
  static const IconData imageBroken = Icons.image_not_supported_outlined;
  static const IconData download = Icons.cloud_download_outlined;
  static const IconData cancel = Icons.cancel_outlined;
  static const IconData recenter = Icons.my_location;
  static const IconData layers = Icons.layers_outlined;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData receipt = Icons.receipt_long_outlined;
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData hostAdd = Icons.domain_add_outlined;
  static const IconData help = Icons.help_center;
  static const IconData shieldCheck = Icons.verified_user_outlined;
  static const IconData celebration = Icons.celebration_outlined;
  static const IconData refresh = Icons.refresh_outlined;
  static const IconData work = Icons.business_center_outlined;

  // Detail page spec icons.
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData verified = Icons.verified_outlined;
  static const IconData wifi = Icons.wifi;
  static const IconData shield = Icons.shield_outlined;
  static const IconData chat = Icons.chat_bubble_outline;
  static const IconData soundEq = Icons.graphic_eq;
  static const IconData ac = Icons.ac_unit;
  static const IconData capacity = Icons.groups_outlined;
  static const IconData aspect = Icons.aspect_ratio;
  static const IconData building = Icons.apartment;

  // Amenities / event types (detail page, filters — phases 4+).
  static const IconData garden = Icons.local_florist_outlined;
  static const IconData rooftop = Icons.roofing_outlined;
  static const IconData beach = Icons.beach_access_outlined;
  static const IconData party = Icons.celebration_outlined;
  static const IconData wedding = Icons.cake_outlined;
  static const IconData lounge = Icons.weekend_outlined;
  static const IconData catering = Icons.restaurant_outlined;
  static const IconData sound = Icons.speaker_outlined;
  static const IconData stage = Icons.mic_outlined;
  static const IconData projector = Icons.movie_outlined;
  static const IconData generator = Icons.bolt_outlined;
  static const IconData power = Icons.power_outlined;
}
