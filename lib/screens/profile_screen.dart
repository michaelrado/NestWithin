import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../data/nest_store.dart';
import '../models/badges.dart' as nest;
import '../theme/app_theme.dart';
import '../version.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            _AccountCard(store: store)
          else
            const _JoinCard(),
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

class _AccountCard extends StatelessWidget {
  final NestStore store;
  const _AccountCard({required this.store});

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
                    if (!acc.emailVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Email confirmation pending',
                          style: text.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 6),
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
            'Create your account',
            style: text.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'You can enjoy a couple of practices in each category for free. '
            'Make an account to unlock everything and earn badges.',
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
            child: const Text('Get started'),
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
