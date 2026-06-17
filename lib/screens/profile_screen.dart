import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../data/nest_store.dart';
import '../models/badges.dart' as nest;
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../version.dart';
import '../widgets/wellness_icon.dart';
import 'signup_screen.dart';

/// "Your Nest" — the membership hub. Shows membership status, accomplishments,
/// badges, the activities you've practiced, and member benefits / events.
/// Without an account it shows your local progress and offers to save it by
/// signing up.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  /// Total minutes of care: completed practice minutes + Hold Me (5 min each).
  static int minutesOfCare(NestStore store) {
    var m = store.holdMeCount * 5;
    store.completionCounts().forEach((id, count) {
      try {
        m += NestContent.practiceById(id).minutes * count;
      } catch (_) {}
    });
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    return Scaffold(
      backgroundColor: NestColors.cream,
      appBar: AppBar(title: const Text('Your Nest')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (store.isSignedIn)
            _MemberCard(store: store)
          else
            const _JoinCard(),
          const SizedBox(height: 24),
          _SectionTitle('Your accomplishments'),
          const SizedBox(height: 12),
          _Accomplishments(store: store),
          const SizedBox(height: 24),
          _SectionTitle('Activities you’ve practiced'),
          const SizedBox(height: 12),
          _ActivitiesPracticed(store: store),
          const SizedBox(height: 24),
          _SectionTitle('Membership'),
          const SizedBox(height: 12),
          _MemberBenefits(store: store),
          const SizedBox(height: 24),
          _BadgesSection(store: store),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$kAppName · $kAppVersionLabel',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: NestColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: NestColors.blueDeep),
  );
}

class _MemberCard extends StatelessWidget {
  final NestStore store;
  const _MemberCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final acc = store.account!;
    final initial = acc.name.trim().isNotEmpty
        ? acc.name.trim()[0].toUpperCase()
        : '🌿';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: NestTheme.sanctuaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  initial,
                  style: text.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.name,
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      acc.email,
                      style: text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nest Member · since ${ProfileScreen.monthYear(acc.joinedAt)}',
                  style: text.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!acc.emailVerified)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Email confirmation pending — check your inbox.',
                style: text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.5),
            value: acc.anonymous,
            onChanged: (v) => store.setAnonymous(v),
            title: Text(
              'Appear as Anonymous',
              style: text.titleSmall?.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              'Hide your name on community leaderboards',
              style: text.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => _confirmSignOut(context, store),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, NestStore store) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your saved progress stays on this device. You can sign back in any '
          'time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              store.signOut();
              Navigator.pop(ctx);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: NestTheme.sanctuaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Become a Nest Member',
            style: text.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'You can enjoy a couple of practices in each category for free. '
            'Create an account to save your progress, earn badges, and unlock '
            'every practice, livestream, and event.',
            style: text.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: NestColors.blueDeep,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: const Text('Create your account'),
          ),
        ],
      ),
    );
  }
}

class _Accomplishments extends StatelessWidget {
  final NestStore store;
  const _Accomplishments({required this.store});

  @override
  Widget build(BuildContext context) {
    final earned = nest.Badges.earned(store).length;
    final stats = <({IconData icon, Color color, String value, String label})>[
      (
        icon: Icons.spa_rounded,
        color: NestColors.blue,
        value: '${store.totalPractices}',
        label: 'practices',
      ),
      (
        icon: Icons.timer_outlined,
        color: NestColors.sage,
        value: '${ProfileScreen.minutesOfCare(store)}',
        label: 'minutes of care',
      ),
      (
        icon: Icons.local_florist_rounded,
        color: NestColors.clay,
        value: '${store.checkInStreak}',
        label: 'day streak',
      ),
      (
        icon: Icons.workspace_premium_rounded,
        color: NestColors.blueDeep,
        value: '$earned',
        label: 'badges earned',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final s in stats)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.color.withValues(alpha: 0.14),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: NestColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NestColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivitiesPracticed extends StatelessWidget {
  final NestStore store;
  const _ActivitiesPracticed({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final counts = store.completionCounts();
    final rows =
        counts.entries
            .map((e) {
              try {
                return (
                  practice: NestContent.practiceById(e.key),
                  count: e.value,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<({Practice practice, int count})>()
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    if (rows.isEmpty && store.holdMeCount == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_rounded, color: NestColors.sage),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your first practice is waiting. Pick a feeling on the Nest tab '
                'and begin.',
                style: text.bodyMedium?.copyWith(color: NestColors.ink),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          if (store.holdMeCount > 0)
            _row(
              context,
              icon: Icons.favorite_rounded,
              iconColor: NestColors.clay,
              title: 'Hold Me For Five Minutes',
              count: store.holdMeCount,
            ),
          for (final r in rows)
            _PracticeRow(practice: r.practice, count: r.count),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
  }) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NestColors.blueMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: text.titleSmall?.copyWith(
                color: NestColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _CountPill(count: count),
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final Practice practice;
  final int count;
  const _PracticeRow({required this.practice, required this.count});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NestColors.blueMist,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(5),
            child: WellnessIcon(practice.iconAsset, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  practice.title,
                  style: text.titleSmall?.copyWith(
                    color: NestColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${practice.kind.label} · ${practice.minutes} min',
                  style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
                ),
              ],
            ),
          ),
          _CountPill(count: count),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '×$count',
        style: const TextStyle(
          color: NestColors.blueDeep,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MemberBenefits extends StatelessWidget {
  final NestStore store;
  const _MemberBenefits({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final member = store.isSignedIn;
    final benefits = <(String, bool)>[
      ('Every practice, unlocked', member),
      ('Hold Me, any time you need it', true), // always free
      ('Live-streamed classes', member),
      ('Workshops & special events', member),
      ('Monthly themes & journeys', member),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    b.$2
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: b.$2 ? NestColors.sage : NestColors.inkSoft,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b.$1,
                      style: text.bodyLarge?.copyWith(
                        color: b.$2 ? NestColors.ink : NestColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            member ? 'Your unlocked events' : 'Events you’ll unlock',
            style: text.titleSmall?.copyWith(
              color: NestColors.blueDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final o in NestContent.studioOfferings)
            _EventRow(offering: o, unlocked: member),
          if (!member) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignupScreen(
                      reason:
                          'Create an account to unlock events & everything else',
                    ),
                  ),
                ),
                child: const Text('Create an account to unlock'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final StudioOffering offering;
  final bool unlocked;
  const _EventRow({required this.offering, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NestColors.blueMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(offering.icon, color: NestColors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offering.title,
                  style: text.titleSmall?.copyWith(
                    color: NestColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${offering.when} · ${offering.teacher}',
                  style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
                ),
              ],
            ),
          ),
          if (unlocked)
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Reserved “${offering.title}” — see you there.',
                  ),
                ),
              ),
              child: const Text('Reserve'),
            )
          else
            const Icon(
              Icons.lock_outline_rounded,
              color: NestColors.inkSoft,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  final NestStore store;
  const _BadgesSection({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final earned = nest.Badges.earnedIds(store).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Badges',
              style: text.titleLarge?.copyWith(color: NestColors.blueDeep),
            ),
            const SizedBox(width: 8),
            Text(
              '${earned.length}/${nest.Badges.all.length}',
              style: text.titleSmall?.copyWith(color: NestColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            for (final b in nest.Badges.all)
              _BadgeTile(badge: b, earned: earned.contains(b.id)),
          ],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final nest.Badge badge;
  final bool earned;
  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: earned
                ? badge.color.withValues(alpha: 0.5)
                : NestColors.sand,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned
                    ? badge.color.withValues(alpha: 0.16)
                    : NestColors.creamDeep,
              ),
              child: Icon(
                earned ? badge.icon : Icons.lock_outline_rounded,
                color: earned ? badge.color : NestColors.inkSoft,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: earned ? NestColors.ink : NestColors.inkSoft,
                fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
