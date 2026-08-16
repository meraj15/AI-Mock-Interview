import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0 to 100
  final Color? color;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final clamped = (value / 100).clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(height),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: color ?? colors.primary,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
