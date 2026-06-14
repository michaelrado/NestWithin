import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';

/// "Hold Me For Five Minutes" — the emotional heart of the app. A calming
/// sanctuary for moments of stress, anxiety, grief, or overwhelm. It simply
/// holds you: soft breath, gentle light, supportive words.
class HoldMeScreen extends StatefulWidget {
  const HoldMeScreen({super.key});

  @override
  State<HoldMeScreen> createState() => _HoldMeScreenState();
}

class _HoldMeScreenState extends State<HoldMeScreen>
    with SingleTickerProviderStateMixin {
  // A slow, soothing breath — longer exhale than inhale.
  static const _pattern = BreathPattern(
    'Soothe',
    inhale: 4,
    holdIn: 1,
    exhale: 6,
    holdOut: 1,
  );

  static const _messages = [
    'You are safe. You are held.',
    'There is nothing you need to do right now.',
    'Let your shoulders soften.',
    'Whatever you’re carrying, you can set it down for a moment.',
    'This feeling will move through you. You are not alone.',
    'Breathe. We’ve got you.',
    'You do not need fixing. You just need a moment.',
    'You belong here.',
  ];

  late final AnimationController _total; // 5 minutes
  int _msgIndex = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _total =
        AnimationController(vsync: this, duration: const Duration(minutes: 5))
          ..addListener(_tick)
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(() => _finished = true);
            }
          })
          ..forward();
  }

  void _tick() {
    // advance the message roughly every ~22 seconds
    final i =
        (_total.value * _messages.length * 1.4).floor() % _messages.length;
    if (i != _msgIndex) setState(() => _msgIndex = i);
  }

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NestTheme.sanctuaryGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (_finished)
                _Farewell(onClose: () => Navigator.of(context).pop())
              else
                Column(
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      'Hold Me',
                      style: text.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(flex: 1),
                    const BreathingOrb(
                      pattern: _pattern,
                      size: 300,
                      color: Colors.white,
                    ),
                    const Spacer(flex: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 900),
                        child: Text(
                          _messages[_msgIndex],
                          key: ValueKey(_msgIndex),
                          textAlign: TextAlign.center,
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Farewell extends StatelessWidget {
  final VoidCallback onClose;
  const _Farewell({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/brand/logo_mark_white.png', width: 90),
            const SizedBox(height: 28),
            Text(
              'You made it through.',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              'We’re here whenever you need us.\nAs many times as you need.',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: NestColors.blueDeep,
              ),
              onPressed: onClose,
              child: const Text('Return gently'),
            ),
          ],
        ),
      ),
    );
  }
}
