import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_icons.dart';

/// Heart with a scale bounce on toggle. 48dp hit area, semantic label.
class FavoriteButton extends StatefulWidget {
  final bool saved;
  final ValueChanged<bool> onToggle;
  final double iconSize;
  final Color idleColor;

  const FavoriteButton({
    super.key,
    required this.saved,
    required this.onToggle,
    this.iconSize = 28,
    this.idleColor = Colors.white,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctr = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.35,
  ).animate(CurvedAnimation(parent: _ctr, curve: Curves.elasticOut));

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.saved ? 'Remove from saved' : 'Save venue',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _ctr.forward(from: 0);
          widget.onToggle(!widget.saved);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.saved
                  ? AppIcons.savedActive
                  : AppIcons.saved,
              color: widget.saved
                  ? AppTokens.heart
                  : widget.idleColor,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
