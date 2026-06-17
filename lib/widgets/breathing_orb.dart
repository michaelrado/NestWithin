import 'package:flutter/material.dart';

import '../models/content.dart';
import 'soul_orb.dart';

/// Guides the breath with the 3D [SoulOrb] — it expands and contracts to the
/// pattern, and surfaces the current phase label ("Breathe in", "Hold"…).
class BreathingOrb extends StatefulWidget {
  final BreathPattern pattern;
  final double size;
  final Color color;
  final Color? coreColor;
  final bool running;

  const BreathingOrb({
    super.key,
    required this.pattern,
    this.size = 260,
    this.color = Colors.white,
    this.coreColor,
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
      duration: Duration(seconds: widget.pattern.cycleSeconds.clamp(1, 60)),
    );
    if (widget.running) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant BreathingOrb old) {
    super.didUpdateWidget(old);
    if (widget.pattern.cycleSeconds != old.pattern.cycleSeconds) {
      _c.duration = Duration(seconds: widget.pattern.cycleSeconds.clamp(1, 60));
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

  /// Returns (expansion 0..1, phase label) for the current point in the cycle.
  (double, String) _phaseAt(double t) {
    final p = widget.pattern;
    var s = t * p.cycleSeconds;
    if (s < p.inhale) {
      final f = p.inhale == 0 ? 1.0 : s / p.inhale;
      return (Curves.easeInOut.transform(f), 'Breathe in');
    }
    s -= p.inhale;
    if (s < p.holdIn) return (1.0, 'Hold');
    s -= p.holdIn;
    if (s < p.exhale) {
      final f = p.exhale == 0 ? 1.0 : s / p.exhale;
      return (1.0 - Curves.easeInOut.transform(f), 'Breathe out');
    }
    return (0.0, 'Rest');
  }

  @override
  Widget build(BuildContext context) {
    final core =
        widget.coreColor ?? Color.lerp(widget.color, Colors.black, 0.0);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final (expansion, label) = _phaseAt(_c.value);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SoulOrb(
                breath: expansion,
                size: widget.size,
                colorA: core ?? widget.color,
                colorB: Color.lerp(widget.color, Colors.white, 0.55)!,
                running: widget.running,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2B3A52),
                  fontWeight: FontWeight.w700,
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
