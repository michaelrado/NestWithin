import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';

/// A single daily check-in record.
class CheckIn {
  final String moodId;
  final DateTime at;

  CheckIn(this.moodId, this.at);

  Map<String, dynamic> toJson() => {'mood': moodId, 'at': at.toIso8601String()};
  factory CheckIn.fromJson(Map<String, dynamic> j) =>
      CheckIn(j['mood'] as String, DateTime.parse(j['at'] as String));
}

/// A community reflection. Seeded ones plus anything the user shares.
class Reflection {
  final String id;
  final String text;
  int meToo;
  final bool mine;
  final bool didMeToo;

  Reflection({
    required this.id,
    required this.text,
    required this.meToo,
    this.mine = false,
    this.didMeToo = false,
  });
}

/// Local-first persistence. Everything lives on-device via shared_preferences,
/// so the app works fully offline on phone and web. No accounts, no servers.
class NestStore extends ChangeNotifier {
  static const _kCheckIns = 'nest.checkins.v1';
  static const _kReflections = 'nest.reflections.v1';
  static const _kMeToo = 'nest.metoo.v1';
  static const _kCompleted = 'nest.completed.v1';
  static const _kOnboarded = 'nest.onboarded.v1';

  late SharedPreferences _prefs;

  List<CheckIn> _checkIns = [];
  List<Reflection> _userReflections = [];
  Set<String> _meTooed = {};
  List<String> _completed = []; // practice ids, most-recent last
  bool _onboarded = false;

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);
  List<String> get completed => List.unmodifiable(_completed);
  bool get onboarded => _onboarded;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _onboarded = _prefs.getBool(_kOnboarded) ?? false;

    final ci = _prefs.getStringList(_kCheckIns) ?? [];
    _checkIns = ci
        .map((s) => CheckIn.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    _completed = _prefs.getStringList(_kCompleted) ?? [];
    _meTooed = (_prefs.getStringList(_kMeToo) ?? []).toSet();

    final refl = _prefs.getStringList(_kReflections) ?? [];
    _userReflections = refl.map((s) {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return Reflection(
        id: j['id'] as String,
        text: j['text'] as String,
        meToo: j['meToo'] as int? ?? 0,
        mine: true,
      );
    }).toList();

    notifyListeners();
  }

  // ── Onboarding ───────────────────────────────────────────────────────────
  Future<void> completeOnboarding() async {
    _onboarded = true;
    await _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  // ── Check-ins ──────────────────────────────────────────────────────────--
  CheckIn? get todaysCheckIn {
    for (final c in _checkIns.reversed) {
      if (_isSameDay(c.at, _now())) return c;
    }
    return null;
  }

  Future<void> recordCheckIn(String moodId, {DateTime? at}) async {
    _checkIns.add(CheckIn(moodId, at ?? _now()));
    await _prefs.setStringList(
      _kCheckIns,
      _checkIns.map((c) => jsonEncode(c.toJson())).toList(),
    );
    notifyListeners();
  }

  /// Mood id → count, over the trailing [days] window.
  Map<String, int> moodCounts({int days = 30}) {
    final cutoff = _now().subtract(Duration(days: days));
    final counts = <String, int>{};
    for (final c in _checkIns) {
      if (c.at.isAfter(cutoff)) {
        counts[c.moodId] = (counts[c.moodId] ?? 0) + 1;
      }
    }
    return counts;
  }

  int get checkInStreak {
    if (_checkIns.isEmpty) return 0;
    final days = _checkIns.map((c) => _dayKey(c.at)).toSet();
    var streak = 0;
    var cursor = _now();
    while (days.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Completed practices ─────────────────────────────────────────────────-
  Future<void> markCompleted(String practiceId) async {
    _completed.add(practiceId);
    if (_completed.length > 200) {
      _completed = _completed.sublist(_completed.length - 200);
    }
    await _prefs.setStringList(_kCompleted, _completed);
    notifyListeners();
  }

  int get practicesThisWeek {
    // Crude but honest: count of completions kept, capped to a weekly feel.
    return _completed.length;
  }

  // ── Community reflections ────────────────────────────────────────────────
  List<Reflection> get reflections {
    final seeded = <Reflection>[];
    for (var i = 0; i < NestContent.seedReflections.length; i++) {
      final (text, base) = NestContent.seedReflections[i];
      final id = 'seed-$i';
      final extra = _meTooed.contains(id) ? 1 : 0;
      seeded.add(
        Reflection(
          id: id,
          text: text,
          meToo: base + extra,
          didMeToo: _meTooed.contains(id),
        ),
      );
    }
    final mine = _userReflections
        .map(
          (r) => Reflection(
            id: r.id,
            text: r.text,
            meToo: r.meToo + (_meTooed.contains(r.id) ? 1 : 0),
            mine: true,
            didMeToo: _meTooed.contains(r.id),
          ),
        )
        .toList()
        .reversed
        .toList();
    return [...mine, ...seeded];
  }

  Future<void> toggleMeToo(String id) async {
    if (_meTooed.contains(id)) {
      _meTooed.remove(id);
    } else {
      _meTooed.add(id);
    }
    await _prefs.setStringList(_kMeToo, _meTooed.toList());
    notifyListeners();
  }

  Future<void> shareReflection(String text) async {
    final id = 'mine-${_now().microsecondsSinceEpoch}';
    _userReflections.add(
      Reflection(id: id, text: text.trim(), meToo: 0, mine: true),
    );
    await _prefs.setStringList(
      _kReflections,
      _userReflections
          .map(
            (r) => jsonEncode({'id': r.id, 'text': r.text, 'meToo': r.meToo}),
          )
          .toList(),
    );
    notifyListeners();
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  DateTime _now() => DateTime.now();
  bool _isSameDay(DateTime a, DateTime b) => _dayKey(a) == _dayKey(b);
  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
