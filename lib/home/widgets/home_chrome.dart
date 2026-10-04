import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

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
/// filled coral icon when active, outlined gray when idle.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const FloatingNavBar(
      {super.key, required this.currentIndex, required this.onTap});

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
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'Explore',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _Tab(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Map',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _Tab(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Saved',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _Tab(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
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
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTokens.coral : AppTokens.inkSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 26),
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
    );
  }
}
