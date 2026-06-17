import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/content.dart';

/// Plays a single looping ambient bed (waves, rain, singing bowls, warm tones,
/// forest, fireplace). One instance per playing screen; tolerant of platforms
/// where autoplay needs a gesture (failures are swallowed so the practice never
/// breaks). [isPlaying] tracks the real player state so a screen can restart
/// playback on the first user tap when the browser blocked autoplay.
class AmbiencePlayer {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  Ambience _current = Ambience.none;
  bool _enabled;
  bool _playing = false;
  final double volume;

  AmbiencePlayer({bool enabled = true, this.volume = 0.55})
    : _enabled = enabled {
    _player.setReleaseMode(ReleaseMode.loop);
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      _playing = s == PlayerState.playing;
    });
  }

  Ambience get current => _current;
  bool get enabled => _enabled;
  bool get isPlaying => _playing;

  Future<void> play(Ambience a) async {
    _current = a;
    final asset = a.asset;
    if (!_enabled || asset == null) {
      await _safeStop();
      return;
    }
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // ignore — audio is an enhancement, never a hard dependency
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value) {
      await play(_current);
    } else {
      await _safeStop();
    }
  }

  Future<void> _safeStop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _safeStop();
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
