import 'package:flutter/material.dart';

import '../audio/ambience_player.dart';
import '../data/nest_scope.dart';
import '../models/badges.dart' as nest;
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/soul_orb.dart';
import '../widgets/wellness_icon.dart';

/// The guided experience player. Paces the practice's cues across its duration,
/// with the 3D soul orb breathing along and a looping ambient sound bed.
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
  late final AmbiencePlayer _ambience;
  bool _running = false;
  bool _done = false;
  List<String> _newBadges = const [];

  int get _totalSeconds => widget.practice.minutes * 60;

  @override
  void initState() {
    super.initState();
    _ambience = AmbiencePlayer(enabled: NestScope.read(context).soundEnabled);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toggle();
      _ambience.play(widget.practice.ambience);
    });
  }

  @override
  void dispose() {
    _ambience.dispose();
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

  Future<void> _toggleSound() async {
    final store = NestScope.read(context);
    final next = !store.soundEnabled;
    await store.setSoundEnabled(next);
    await _ambience.setEnabled(next);
    setState(() {});
  }

  /// Browsers block audio that doesn't begin from a user gesture, so the first
  /// tap anywhere on the player (re)starts the sound bed if it isn't running.
  void _onUserGesture() {
    if (widget.practice.ambience == Ambience.none) return;
    if (NestScope.read(context).soundEnabled && !_ambience.isPlaying) {
      _ambience.play(widget.practice.ambience);
    }
  }

  Future<void> _complete() async {
    if (_done) return;
    final badges = await NestScope.read(
      context,
    ).markCompleted(widget.practice.id);
    setState(() {
      _done = true;
      _newBadges = badges;
    });
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
    final soundOn = NestScope.of(context).soundEnabled;

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onUserGesture(),
        child: Container(
          decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
          child: SafeArea(
            child: _done
                ? _Completion(practice: p, newBadges: _newBadges)
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
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: p.ambience == Ambience.none
                                  ? 'No sound for this practice'
                                  : (soundOn ? 'Mute' : 'Unmute'),
                              color: NestColors.inkSoft,
                              onPressed: p.ambience == Ambience.none
                                  ? null
                                  : _toggleSound,
                              icon: Icon(
                                soundOn && p.ambience != Ambience.none
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.title,
                        style: text.headlineSmall?.copyWith(
                          color: NestColors.blueDeep,
                        ),
                      ),
                      Text(
                        p.ambience == Ambience.none
                            ? '${p.kind.label} · ${p.minutes} min'
                            : '${p.kind.label} · ${p.minutes} min · ${p.ambience.label}',
                        style: text.bodySmall?.copyWith(
                          color: NestColors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      if (p.breath != null)
                        BreathingOrb(
                          pattern: p.breath!,
                          size: 290,
                          color: NestColors.blueSoft,
                          running: _running,
                        )
                      else
                        _SoulEmblem(
                          pulse: _pulse,
                          asset: p.iconAsset,
                          kind: p.kind,
                          running: _running,
                        ),
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
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

({Color a, Color b}) _soulColors(PracticeKind kind) {
  return switch (kind) {
    PracticeKind.meditation => (a: NestColors.blue, b: NestColors.blueMist),
    PracticeKind.sound => (a: NestColors.blueSoft, b: Color(0xFFEAF2FF)),
    PracticeKind.rest => (a: NestColors.blueDeep, b: NestColors.blueSoft),
    PracticeKind.reflection => (a: NestColors.sage, b: Color(0xFFE6EFE4)),
    PracticeKind.movement => (a: NestColors.clay, b: Color(0xFFF3DCCB)),
    PracticeKind.breath => (a: NestColors.blueSoft, b: Color(0xFFEAF2FF)),
  };
}

class _SoulEmblem extends StatelessWidget {
  final AnimationController pulse;
  final String asset;
  final PracticeKind kind;
  final bool running;
  const _SoulEmblem({
    required this.pulse,
    required this.asset,
    required this.kind,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final c = _soulColors(kind);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return SizedBox(
          width: 290,
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SoulOrb(
                breath: pulse.value,
                size: 290,
                colorA: c.a,
                colorB: c.b,
                running: running,
              ),
              Opacity(
                opacity: 0.9,
                child: WellnessIcon(asset, size: 96, tint: Colors.white),
              ),
            ],
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

  const _Controls({
    required this.running,
    required this.progress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

class _Completion extends StatelessWidget {
  final Practice practice;
  final List<String> newBadges;
  const _Completion({required this.practice, required this.newBadges});

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
          if (newBadges.isNotEmpty) ...[
            const SizedBox(height: 28),
            _BadgeUnlock(badgeIds: newBadges),
          ],
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

class _BadgeUnlock extends StatelessWidget {
  final List<String> badgeIds;
  const _BadgeUnlock({required this.badgeIds});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NestColors.clay.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            badgeIds.length == 1 ? 'Badge earned!' : 'Badges earned!',
            style: text.titleSmall?.copyWith(
              color: NestColors.clay,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 12,
            children: [
              for (final id in badgeIds)
                _MiniBadge(badge: nest.Badges.byId(id)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final nest.Badge badge;
  const _MiniBadge({required this.badge});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.color.withValues(alpha: 0.16),
            ),
            child: Icon(badge.icon, color: badge.color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: NestColors.ink),
          ),
        ],
      ),
    );
  }
}
