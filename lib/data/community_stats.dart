import '../models/content.dart';
import 'nest_store.dart';

/// A member on the "most active" leaderboard.
class ActiveUser {
  final String name;
  final int practices;
  final String favoritePracticeId;
  final bool anonymous;
  final bool isMe;

  const ActiveUser(
    this.name,
    this.practices,
    this.favoritePracticeId, {
    this.anonymous = false,
    this.isMe = false,
  });

  /// Respects the member's privacy choice.
  String get display => anonymous ? 'Anonymous' : name;
}

/// Community-wide stats. Today these blend a seeded baseline with the user's
/// own local activity; once the VPS API is live, [popularActivities] and
/// [activeUsers] swap to real aggregates with the same shapes — no UI change.
class CommunityStats {
  CommunityStats._();

  // Pretend aggregate completion counts across the community.
  static const Map<String, int> _seedPopularity = {
    'box-breath': 312,
    'grounding': 287,
    'soundbath': 264,
    'four78': 251,
    'bodyscan': 230,
    'gratitude': 198,
    'coherent': 176,
    'lovingkindness': 162,
    'sigh': 154,
    'intention': 131,
    'restore': 120,
    'shake': 96,
  };

  static List<({Practice practice, int count})> popularActivities(
    NestStore s, {
    int top = 6,
  }) {
    final entries =
        NestContent.practices
            .map(
              (p) => (
                practice: p,
                count: (_seedPopularity[p.id] ?? 80) + s.completionsOf(p.id),
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return entries.take(top).toList();
  }

  static const List<ActiveUser> _seedUsers = [
    ActiveUser('Maya R.', 142, 'box-breath'),
    ActiveUser('Anonymous', 128, 'soundbath', anonymous: true),
    ActiveUser('Theo K.', 119, 'four78'),
    ActiveUser('Priya S.', 104, 'bodyscan'),
    ActiveUser('Anonymous', 97, 'grounding', anonymous: true),
    ActiveUser('Jordan M.', 85, 'coherent'),
    ActiveUser('Lena V.', 78, 'gratitude'),
    ActiveUser('Sam W.', 64, 'sigh'),
  ];

  /// The leaderboard, with the signed-in user folded in at their real local
  /// count and shown as "Anonymous" if they opted out of being named.
  static List<ActiveUser> activeUsers(NestStore s, {int top = 8}) {
    final list = [..._seedUsers];
    if (s.isSignedIn) {
      final acc = s.account!;
      list.add(
        ActiveUser(
          acc.name,
          s.totalPractices,
          favorite(s),
          anonymous: acc.anonymous,
          isMe: true,
        ),
      );
    }
    list.sort((a, b) => b.practices.compareTo(a.practices));
    return list.take(top).toList();
  }

  static String favorite(NestStore s) {
    final counts = s.completionCounts();
    if (counts.isEmpty) return 'box-breath';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
