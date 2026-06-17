import 'package:flutter/material.dart';

import '../data/community_stats.dart';
import '../data/nest_scope.dart';
import '../data/nest_store.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';

/// Connection without social media. No likes, no followers, no algorithms —
/// just anonymous reflections and a quiet "Me too."
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    final text = Theme.of(context).textTheme;
    final reflections = store.reflections;

    return Container(
      decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Together',
                    style: text.headlineMedium?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belonging, not performance. Share anonymously, or '
                    'simply offer a “me too.”',
                    style: text.bodyMedium?.copyWith(
                      color: NestColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShareCard(store: store),
                  const SizedBox(height: 24),
                  _PopularActivities(store: store),
                  const SizedBox(height: 20),
                  _Leaderboard(store: store),
                  const SizedBox(height: 24),
                  Text(
                    'Reflections',
                    style: text.titleLarge?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: reflections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _ReflectionCard(reflection: reflections[i], store: store),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularActivities extends StatelessWidget {
  final NestStore store;
  const _PopularActivities({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final popular = CommunityStats.popularActivities(store, top: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: NestColors.clay),
            const SizedBox(width: 8),
            Text(
              'Most loved this week',
              style: text.titleMedium?.copyWith(color: NestColors.blueDeep),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popular.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final row = popular[i];
              return _PopularCard(
                rank: i + 1,
                practice: row.practice,
                count: row.count,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularCard extends StatelessWidget {
  final int rank;
  final Practice practice;
  final int count;
  const _PopularCard({
    required this.rank,
    required this.practice,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Text(
                '#$rank',
                style: text.labelLarge?.copyWith(
                  color: NestColors.clay,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            practice.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(
              color: NestColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count sessions',
            style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final NestStore store;
  const _Leaderboard({required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final users = CommunityStats.activeUsers(store, top: 8);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: NestColors.clay),
              const SizedBox(width: 8),
              Text(
                'Most active this month',
                style: text.titleMedium?.copyWith(color: NestColors.blueDeep),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (i, u) in users.indexed) _LeaderRow(rank: i + 1, user: u),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final ActiveUser user;
  const _LeaderRow({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fav = NestContent.practiceById(user.favoritePracticeId);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: user.isMe ? NestColors.blueMist : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(
                color: rank <= 3 ? NestColors.clay : NestColors.inkSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 18,
            backgroundColor: user.anonymous
                ? NestColors.inkSoft.withValues(alpha: 0.25)
                : NestColors.blue.withValues(alpha: 0.15),
            child: Icon(
              user.anonymous
                  ? Icons.visibility_off_rounded
                  : Icons.person_rounded,
              size: 18,
              color: user.anonymous ? NestColors.inkSoft : NestColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isMe ? '${user.display} (you)' : user.display,
                  style: text.titleSmall?.copyWith(
                    color: NestColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Loves ${fav.title}',
                  style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
                ),
              ],
            ),
          ),
          Text(
            '${user.practices}',
            style: text.titleMedium?.copyWith(
              color: NestColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatefulWidget {
  final NestStore store;
  const _ShareCard({required this.store});

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    await widget.store.shareReflection(t);
    _controller.clear();
    setState(() => _expanded = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared anonymously. Thank you.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_expanded)
            InkWell(
              onTap: () => setState(() => _expanded = true),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: NestColors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Share a thought, gratitude, or struggle…',
                    style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 240,
              style: text.bodyLarge?.copyWith(color: NestColors.ink),
              decoration: const InputDecoration(
                hintText: 'What’s present for you right now?',
                border: InputBorder.none,
                counterStyle: TextStyle(color: NestColors.inkSoft),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _expanded = false;
                    _controller.clear();
                  }),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Share anonymously'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final Reflection reflection;
  final NestStore store;
  const _ReflectionCard({required this.reflection, required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: reflection.mine
            ? Border.all(color: NestColors.blueMist, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reflection.mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You shared',
                style: text.labelSmall?.copyWith(
                  color: NestColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            reflection.text,
            style: text.bodyLarge?.copyWith(
              color: NestColors.ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MeTooButton(reflection: reflection, store: store),
              const Spacer(),
              Text(
                '${reflection.meToo} felt this too',
                style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeTooButton extends StatelessWidget {
  final Reflection reflection;
  final NestStore store;
  const _MeTooButton({required this.reflection, required this.store});

  @override
  Widget build(BuildContext context) {
    final active = reflection.didMeToo;
    return Material(
      color: active ? NestColors.blue : NestColors.blueMist,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => store.toggleMeToo(reflection.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: active ? Colors.white : NestColors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'Me too',
                style: TextStyle(
                  color: active ? Colors.white : NestColors.blueDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
