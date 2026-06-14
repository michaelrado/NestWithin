import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/content.dart';

/// A softly glowing orb that expands and contracts to guide the breath.
/// Drives its own animation from a [BreathPattern] and surfaces the current
/// phase label ("Breathe in", "Hold", "Breathe out").
class BreathingOrb extends StatefulWidget {
  final BreathPattern pattern;
  final double size;
  final Color color;
  final bool running;

  const BreathingOrb({
    super.key,
    required this.pattern,
    this.size = 260,
    this.color = Colors.white,
    this.running = true,
  });

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: math.max(1, widget.pattern.cycleSeconds)),
    );
    if (widget.running) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant BreathingOrb old) {
    super.didUpdateWidget(old);
    if (widget.pattern.cycleSeconds != old.pattern.cycleSeconds) {
      _c.duration = Duration(seconds: math.max(1, widget.pattern.cycleSeconds));
      if (widget.running) _c.repeat();
    }
    if (widget.running && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.running && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Returns (scale 0..1, phase label) for the current point in the cycle.
  (double, String) _phaseAt(double t) {
    final p = widget.pattern;
    final cycle = p.cycleSeconds.toDouble();
    var s = t * cycle; // seconds into the cycle

    if (s < p.inhale) {
      final f = p.inhale == 0 ? 1.0 : s / p.inhale;
      return (Curves.easeInOut.transform(f), 'Breathe in');
    }
    s -= p.inhale;
    if (s < p.holdIn) {
      return (1.0, 'Hold');
    }
    s -= p.holdIn;
    if (s < p.exhale) {
      final f = p.exhale == 0 ? 1.0 : s / p.exhale;
      return (1.0 - Curves.easeInOut.transform(f), 'Breathe out');
    }
    return (0.0, 'Rest');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final (raw, label) = _phaseAt(_c.value);
        const minScale = 0.55;
        final scale = minScale + raw * (1 - minScale);
        final orb = widget.size * scale;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // outer halo
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.06),
                ),
              ),
              // breathing glow
              Container(
                width: orb,
                height: orb,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.95),
                      widget.color.withValues(alpha: 0.25),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 40 * scale,
                      spreadRadius: 8 * scale,
                    ),
                  ],
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2B3A52),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
