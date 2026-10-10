import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../ui/ui.dart';

/// Airbnb-style filter chip: white with border, ink when active.
class FilterChipLabel extends StatelessWidget {
  final String label;
  final bool active;
  const FilterChipLabel(
      {super.key, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppTokens.ink : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        border: Border.all(
            color: active ? AppTokens.ink : AppTokens.border),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppTokens.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Bottom tabs: Explore / Map / Saved / Profile. White bar, top border,
/// active tab gets a blue-tint pill behind a filled blue icon.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final int savedCount;
  final ValueChanged<int> onTap;
  const FloatingNavBar(
      {super.key,
      required this.currentIndex,
      this.savedCount = 0,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Tab(
                icon: AppIcons.explore,
                activeIcon: AppIcons.exploreActive,
                label: 'Explore',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _Tab(
                icon: AppIcons.map,
                activeIcon: AppIcons.mapActive,
                label: 'Map',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _Tab(
                icon: AppIcons.saved,
                activeIcon: AppIcons.savedActive,
                label: 'Saved',
                active: currentIndex == 2,
                badge: savedCount > 0 ? '$savedCount' : null,
                onTap: () => onTap(2),
              ),
              _Tab(
                icon: AppIcons.profile,
                activeIcon: AppIcons.profileActive,
                label: 'Profile',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTokens.primary : AppTokens.inkSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? AppTokens.primaryTint
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: badge == null
                  ? Icon(active ? activeIcon : icon,
                      color: color, size: 24)
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(active ? activeIcon : icon,
                            color: color, size: 24),
                        Positioned(
                          top: -4,
                          right: -8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppTokens.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
