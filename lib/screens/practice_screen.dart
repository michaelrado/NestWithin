import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/wellness_icon.dart';

/// The guided experience player. Paces the practice's cues across its duration,
/// with a breathing orb for breath practices and a soft pulse for the rest.
class PracticeScreen extends StatefulWidget {
  final Practice practice;
  const PracticeScreen({super.key, required this.practice});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  late final AnimationController _pulse;
  bool _running = false;
  bool _done = false;

  int get _totalSeconds => widget.practice.minutes * 60;

  @override
  void initState() {
    super.initState();
    _progress =
        AnimationController(
          vsync: this,
          duration: Duration(seconds: _totalSeconds),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) _complete();
        });
    _progress.addListener(() => setState(() {}));
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    // start automatically after the first frame for a gentle entry
    WidgetsBinding.instance.addPostFrameCallback((_) => _toggle());
  }

  @override
  void dispose() {
    _progress.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _running = !_running;
      if (_running) {
        _progress.forward();
      } else {
        _progress.stop();
      }
    });
  }

  void _complete() {
    if (_done) return;
    setState(() => _done = true);
    NestScope.read(context).markCompleted(widget.practice.id);
  }

  String get _remaining {
    final left = (_totalSeconds * (1 - _progress.value)).ceil().clamp(
      0,
      _totalSeconds,
    );
    final m = left ~/ 60;
    final s = left % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _currentCue {
    final steps = widget.practice.steps;
    if (steps.isEmpty) return widget.practice.invitation;
    final idx = (_progress.value * steps.length).floor().clamp(
      0,
      steps.length - 1,
    );
    return steps[idx];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.practice;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
        child: SafeArea(
          child: _done
              ? _Completion(practice: p)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: NestColors.inkSoft,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Text(
                            _remaining,
                            style: text.titleMedium?.copyWith(
                              color: NestColors.inkSoft,
                              fontFeatures: const [],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      style: text.headlineSmall?.copyWith(
                        color: NestColors.blueDeep,
                      ),
                    ),
                    Text(
                      '${p.kind.label} · ${p.minutes} min',
                      style: text.bodySmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                    const Spacer(),
                    if (p.breath != null)
                      BreathingOrb(
                        pattern: p.breath!,
                        size: 280,
                        color: NestColors.blueSoft,
                        running: _running,
                      )
                    else
                      _PulseEmblem(animation: _pulse, asset: p.iconAsset),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _currentCue,
                          key: ValueKey(_currentCue),
                          textAlign: TextAlign.center,
                          style: text.titleMedium?.copyWith(
                            color: NestColors.ink,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Controls(
                      running: _running,
                      progress: _progress.value,
                      onToggle: _toggle,
                      onFinish: _complete,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PulseEmblem extends StatelessWidget {
  final Animation<double> animation;
  final String asset;
  const _PulseEmblem({required this.animation, required this.asset});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = 0.92 + animation.value * 0.12;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  NestColors.blueMist.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NestColors.blueSoft.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Center(child: WellnessIcon(asset, size: 110)),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final bool running;
  final double progress;
  final VoidCallback onToggle;
  final VoidCallback onFinish;

  const _Controls({
    required this.running,
    required this.progress,
    required this.onToggle,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: NestColors.blueMist,
                  valueColor: const AlwaysStoppedAnimation(NestColors.blue),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: NestColors.blue,
                  ),
                  child: Icon(
                    running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Completion extends StatelessWidget {
  final Practice practice;
  const _Completion({required this.practice});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/brand/logo_mark_blue.png', width: 90),
          const SizedBox(height: 24),
          Text(
            'Well done.',
            style: text.headlineMedium?.copyWith(color: NestColors.blueDeep),
          ),
          const SizedBox(height: 12),
          Text(
            'You gave yourself ${practice.minutes} minutes of care.\nNotice how you feel now.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: NestColors.ink, height: 1.5),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to the Nest'),
            ),
          ),
        ],
      ),
    );
  }
}
