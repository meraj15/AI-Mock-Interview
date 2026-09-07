import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

// ── Mini Voice Wave Visualizer Bars ──────────────────────────────────────────

class MiniVoiceWaveVisualizer extends StatelessWidget {
  final Color color;
  final Animation<double> anim;

  const MiniVoiceWaveVisualizer({
    super.key,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, _) {
        final v = anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(4 + (v * 8)),
            const SizedBox(width: 2.5),
            _bar(10 - (v * 6)),
            const SizedBox(width: 2.5),
            _bar(6 + (v * 7)),
            const SizedBox(width: 2.5),
            _bar(12 - (v * 8)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Animated Progress Dots ────────────────────────────────────────────────────

class AnimatedProgressDots extends StatefulWidget {
  final Color color;

  const AnimatedProgressDots({super.key, required this.color});

  @override
  State<AnimatedProgressDots> createState() => _AnimatedProgressDotsState();
}

class _AnimatedProgressDotsState extends State<AnimatedProgressDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _activeIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _activeIndex = (_activeIndex + 1) % 3);
      _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == _activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 7,
          height: isActive ? 10 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? widget.color
                : widget.color.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

// ── Control Pill ──────────────────────────────────────────────────────────────

class ControlPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const ControlPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isPrimary ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.semiBold(10, color: isPrimary ? Colors.white : color),
            ),
          ],
        ),
      ),
    );
  }
}
