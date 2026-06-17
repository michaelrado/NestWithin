import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A living, 3D-feeling "soul" that breathes with the practice.
///
/// Primary path is a fragment shader (`shaders/soul.frag`) — a fresnel-lit
/// sphere with swirling inner energy. If the shader can't be loaded (rare),
/// it falls back to a hand-painted volumetric orb so it always renders.
class SoulOrb extends StatefulWidget {
  /// 0..1 — how expanded the soul is (drive from the breath phase).
  final double breath;
  final double size;
  final Color colorA; // inner core
  final Color colorB; // energy / rim
  final bool running;

  const SoulOrb({
    super.key,
    required this.breath,
    this.size = 280,
    this.colorA = const Color(0xFF7E9FD1),
    this.colorB = const Color(0xFFEAF2FF),
    this.running = true,
  });

  static ui.FragmentProgram? _program;
  static bool _triedLoad = false;

  static Future<void> warmUp() async {
    if (_triedLoad) return;
    _triedLoad = true;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/soul.frag');
    } catch (_) {
      _program = null; // fall back to the painter
    }
  }

  @override
  State<SoulOrb> createState() => _SoulOrbState();
}

class _SoulOrbState extends State<SoulOrb> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    if (SoulOrb._program == null && !SoulOrb._triedLoad) {
      SoulOrb.warmUp().then((_) {
        if (mounted) setState(() {});
      });
    }
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMicroseconds / 1e6);
    });
    if (widget.running) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant SoulOrb old) {
    super.didUpdateWidget(old);
    if (widget.running && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.running && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SoulPainter(
          program: SoulOrb._program,
          time: _time,
          breath: widget.breath.clamp(0.0, 1.0),
          colorA: widget.colorA,
          colorB: widget.colorB,
        ),
      ),
    );
  }
}

class _SoulPainter extends CustomPainter {
  final ui.FragmentProgram? program;
  final double time;
  final double breath;
  final Color colorA;
  final Color colorB;

  _SoulPainter({
    required this.program,
    required this.time,
    required this.breath,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final prog = program;
    if (prog != null) {
      final shader = prog.fragmentShader();
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, time)
        ..setFloat(3, breath)
        ..setFloat(4, colorA.r)
        ..setFloat(5, colorA.g)
        ..setFloat(6, colorA.b)
        ..setFloat(7, colorB.r)
        ..setFloat(8, colorB.g)
        ..setFloat(9, colorB.b);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    } else {
      _paintFallback(canvas, size);
    }
  }

  /// Hand-painted volumetric orb: outer aura, shaded sphere with an off-centre
  /// highlight (reads as 3D), and a few drifting energy wisps.
  void _paintFallback(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    final r = base * (0.62 + breath * 0.18);

    // aura
    canvas.drawCircle(
      center,
      r * 1.9,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          r * 1.9,
          [
            colorB.withValues(alpha: 0.28 + 0.18 * breath),
            colorB.withValues(alpha: 0.0),
          ],
          [0.0, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    // shaded sphere (light from top-left)
    final light = center.translate(-r * 0.35, -r * 0.4);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          light,
          r * 1.5,
          [
            Color.lerp(colorB, Colors.white, 0.5)!,
            colorB,
            colorA,
            Color.lerp(colorA, Colors.black, 0.25)!,
          ],
          [0.0, 0.35, 0.7, 1.0],
        ),
    );

    // drifting wisps
    for (var i = 0; i < 5; i++) {
      final a = time * (0.4 + i * 0.13) + i * 1.7;
      final rad = r * (0.25 + 0.45 * ((math.sin(time * 0.6 + i) + 1) / 2));
      final p = center.translate(math.cos(a) * rad, math.sin(a * 1.2) * rad);
      canvas.drawCircle(
        p,
        r * (0.10 + 0.05 * math.sin(time + i)),
        Paint()
          ..color = colorB.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // rim light
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Color.lerp(colorB, Colors.white, 0.4)!.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _SoulPainter old) =>
      old.time != time ||
      old.breath != breath ||
      old.colorA != colorA ||
      old.colorB != colorB ||
      old.program != program;
}
