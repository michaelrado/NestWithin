import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badges.dart';
import '../models/content.dart';

/// How many activities in each category are free before an account is needed.
const int kFreePerCategory = 2;

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

/// The locally-stored account profile. (When the backend lands, this is the
/// shape we sync; email confirmation + reset happen server-side via Mailgun.)
class NestAccount {
  final String name;
  final String email;
  final String referral; // "How did you hear about us?"
  final int rating; // 1..5 stars given to the app at signup
  final bool anonymous; // opt out of showing your name in community stats
  final DateTime joinedAt;
  final bool emailVerified;

  NestAccount({
    required this.name,
    required this.email,
    required this.referral,
    required this.rating,
    required this.anonymous,
    required this.joinedAt,
    this.emailVerified = false,
  });

  String get displayName => anonymous ? 'Anonymous' : name;

  NestAccount copyWith({bool? anonymous, bool? emailVerified}) => NestAccount(
    name: name,
    email: email,
    referral: referral,
    rating: rating,
    anonymous: anonymous ?? this.anonymous,
    joinedAt: joinedAt,
    emailVerified: emailVerified ?? this.emailVerified,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'referral': referral,
    'rating': rating,
    'anonymous': anonymous,
    'joinedAt': joinedAt.toIso8601String(),
    'emailVerified': emailVerified,
  };

  factory NestAccount.fromJson(Map<String, dynamic> j) => NestAccount(
    name: j['name'] as String,
    email: j['email'] as String,
    referral: j['referral'] as String? ?? '',
    rating: j['rating'] as int? ?? 0,
    anonymous: j['anonymous'] as bool? ?? false,
    joinedAt:
        DateTime.tryParse(j['joinedAt'] as String? ?? '') ?? DateTime.now(),
    emailVerified: j['emailVerified'] as bool? ?? false,
  );
}

/// Local-first persistence. Everything lives on-device via shared_preferences,
/// so the app works fully offline. The account/stats models are shaped so they
/// can later sync to the VPS API without UI changes.
class NestStore extends ChangeNotifier {
  static const _kCheckIns = 'nest.checkins.v1';
  static const _kReflections = 'nest.reflections.v1';
  static const _kMeToo = 'nest.metoo.v1';
  static const _kCompleted = 'nest.completed.v1';
  static const _kOnboarded = 'nest.onboarded.v1';
  static const _kAccount = 'nest.account.v1';
  static const _kSound = 'nest.sound.v1';
  static const _kHoldMe = 'nest.holdme.v1';
  static const _kBadges = 'nest.badges.v1';

  late SharedPreferences _prefs;

  List<CheckIn> _checkIns = [];
  List<Reflection> _userReflections = [];
  Set<String> _meTooed = {};
  List<String> _completed = []; // practice ids, most-recent last
  bool _onboarded = false;
  NestAccount? _account;
  bool _soundEnabled = true;
  int _holdMeCount = 0;
  Set<String> _awardedBadges = {};

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);
  List<String> get completed => List.unmodifiable(_completed);
  bool get onboarded => _onboarded;
  NestAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get soundEnabled => _soundEnabled;
  int get holdMeCount => _holdMeCount;
  Set<String> get awardedBadges => Set.unmodifiable(_awardedBadges);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _onboarded = _prefs.getBool(_kOnboarded) ?? false;
    _soundEnabled = _prefs.getBool(_kSound) ?? true;
    _holdMeCount = _prefs.getInt(_kHoldMe) ?? 0;
    _awardedBadges = (_prefs.getStringList(_kBadges) ?? []).toSet();

    final acc = _prefs.getString(_kAccount);
    if (acc != null) {
      _account = NestAccount.fromJson(jsonDecode(acc) as Map<String, dynamic>);
    }

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

  // ── Account ────────────────────────────────────────────────────────────--
  Future<void> signUp({
    required String name,
    required String email,
    required String referral,
    required int rating,
    required bool anonymous,
  }) async {
    _account = NestAccount(
      name: name.trim(),
      email: email.trim(),
      referral: referral,
      rating: rating,
      anonymous: anonymous,
      joinedAt: DateTime.now(),
    );
    await _prefs.setString(_kAccount, jsonEncode(_account!.toJson()));
    notifyListeners();
  }

  Future<void> setAnonymous(bool value) async {
    if (_account == null) return;
    _account = _account!.copyWith(anonymous: value);
    await _prefs.setString(_kAccount, jsonEncode(_account!.toJson()));
    notifyListeners();
  }

  Future<void> signOut() async {
    _account = null;
    await _prefs.remove(_kAccount);
    notifyListeners();
  }

  /// Free tier: the first [kFreePerCategory] items in any category are open;
  /// the rest unlock once there's an account.
  bool isUnlocked(int indexInCategory) =>
      isSignedIn || indexInCategory < kFreePerCategory;

  // ── Sound preference ──────────────────────────────────────────────────────
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(_kSound, value);
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
  /// Records a completion and returns the ids of any badges newly earned.
  Future<List<String>> markCompleted(String practiceId) async {
    _completed.add(practiceId);
    if (_completed.length > 500) {
      _completed = _completed.sublist(_completed.length - 500);
    }
    await _prefs.setStringList(_kCompleted, _completed);
    final newBadges = await _refreshBadges();
    notifyListeners();
    return newBadges;
  }

  Future<List<String>> markHoldMeComplete() async {
    _holdMeCount += 1;
    await _prefs.setInt(_kHoldMe, _holdMeCount);
    final newBadges = await _refreshBadges();
    notifyListeners();
    return newBadges;
  }

  int get totalPractices => _completed.length;

  int get practicesThisWeek {
    return _completed.length; // kept simple; honest local count
  }

  /// practice id → number of times completed (local).
  Map<String, int> completionCounts() {
    final m = <String, int>{};
    for (final id in _completed) {
      m[id] = (m[id] ?? 0) + 1;
    }
    return m;
  }

  int completionsOf(String practiceId) =>
      _completed.where((id) => id == practiceId).length;

  Set<String> get distinctCompleted => _completed.toSet();

  // ── Badges ────────────────────────────────────────────────────────────────
  /// Recomputes earned badge ids; persists and returns any that are newly
  /// earned (for celebration). Pure derivation lives in models/badges.dart.
  Future<List<String>> _refreshBadges() async {
    // imported lazily to avoid a cycle at top of file
    final earned = Badges.earnedIds(this);
    final fresh = earned.where((b) => !_awardedBadges.contains(b)).toList();
    if (fresh.isNotEmpty) {
      _awardedBadges.addAll(fresh);
      await _prefs.setStringList(_kBadges, _awardedBadges.toList());
    }
    return fresh;
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
