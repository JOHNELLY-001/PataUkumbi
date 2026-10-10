import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/tokens.dart';

/// Shimmering placeholder used while content loads (Phase 3 adopts it
/// in lists; gallery previews it here).
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTokens.surfaceSecondary,
      highlightColor: AppTokens.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTokens.surfaceSecondary,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
