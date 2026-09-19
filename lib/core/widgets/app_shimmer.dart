import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A theme-aware animated shimmer wrapper for skeleton loading views.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Duration period;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBase = isDark
        ? const Color(0xFF1E2C48)
        : const Color(0xFFE4E8F1);

    final defaultHighlight = isDark
        ? const Color(0xFF31446C)
        : const Color(0xFFF7F9FC);

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      period: period,
      child: child,
    );
  }
}

/// A standard rounded placeholder box for shimmer skeletons.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  const ShimmerBox.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shapeBorder = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    if (shapeBorder != null) {
      return Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: shapeBorder!,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
