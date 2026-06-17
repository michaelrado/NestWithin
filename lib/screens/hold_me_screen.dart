import 'package:flutter/material.dart';

import '../audio/ambience_player.dart';
import '../data/nest_scope.dart';
import '../models/badges.dart' as nest;
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';

/// "Hold Me For Five Minutes" — the emotional heart of the app. A calming
/// sanctuary for moments of stress, anxiety, grief, or overwhelm. It simply
/// holds you: a glowing soul breathing slowly, warm tones, supportive words.
/// Always free — this is the safety feature.
class HoldMeScreen extends StatefulWidget {
  const HoldMeScreen({super.key});

  @override
  State<HoldMeScreen> createState() => _HoldMeScreenState();
}

class _HoldMeScreenState extends State<HoldMeScreen>
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _total;
  late final AmbiencePlayer _ambience;
  int _msgIndex = 0;
  bool _finished = false;
  List<String> _newBadges = const [];

  @override
  void initState() {
    super.initState();
    _ambience = AmbiencePlayer(enabled: NestScope.read(context).soundEnabled);
    _total =
        AnimationController(vsync: this, duration: const Duration(minutes: 5))
          ..addListener(_tick)
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) _finish();
          })
          ..forward();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ambience.play(Ambience.pad),
    );
  }

  void _tick() {
    final i =
        (_total.value * _messages.length * 1.4).floor() % _messages.length;
    if (i != _msgIndex) setState(() => _msgIndex = i);
  }

  Future<void> _finish() async {
    final badges = await NestScope.read(context).markHoldMeComplete();
    setState(() {
      _finished = true;
      _newBadges = badges;
    });
  }

  Future<void> _toggleSound() async {
    final store = NestScope.read(context);
    final next = !store.soundEnabled;
    await store.setSoundEnabled(next);
    await _ambience.setEnabled(next);
    setState(() {});
  }

  /// First tap (re)starts the sound bed if a browser blocked autoplay.
  void _onUserGesture() {
    if (NestScope.read(context).soundEnabled && !_ambience.isPlaying) {
      _ambience.play(Ambience.pad);
    }
  }

  @override
  void dispose() {
    _ambience.dispose();
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final soundOn = NestScope.of(context).soundEnabled;
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onUserGesture(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: NestTheme.sanctuaryGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSound,
                  ),
                ),
                if (_finished)
                  _Farewell(
                    newBadges: _newBadges,
                    onClose: () => Navigator.of(context).pop(),
                  )
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
                        coreColor: Color(0xFF8FB0E0),
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
      ),
    );
  }
}

class _Farewell extends StatelessWidget {
  final VoidCallback onClose;
  final List<String> newBadges;
  const _Farewell({required this.onClose, required this.newBadges});

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
            if (newBadges.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                children: [
                  for (final id in newBadges)
                    _Badge(badge: nest.Badges.byId(id)),
                ],
              ),
            ],
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

class _Badge extends StatelessWidget {
  final nest.Badge badge;
  const _Badge({required this.badge});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: Icon(badge.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
